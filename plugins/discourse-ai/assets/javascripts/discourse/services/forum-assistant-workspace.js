import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { extractErrorInfo } from "discourse/lib/ajax-error";
import { cook } from "discourse/lib/text";
import { i18n } from "discourse-i18n";

const BASE = "/discourse-ai/ai-bot/forum-assistant/conversations";
const TERMINAL = new Set([
  "completed",
  "refused",
  "clarified",
  "not_found",
  "failed",
  "expired",
  "cancelled",
]);

function mergeMessages(...collections) {
  return [
    ...new Map(
      collections.flat().map((message) => [message.id, message])
    ).values(),
  ].sort((left, right) => left.post_number - right.post_number);
}

export default class ForumAssistantWorkspace extends Service {
  @service currentUser;
  @service forumAssistant;
  @service messageBus;
  @service router;
  @service sessionStore;

  @tracked conversation = null;
  @tracked conversations = [];
  @tracked drafts = new Map();
  @tracked error = null;
  @tracked hasMoreHistory = false;
  @tracked hasOlder = false;
  @tracked historyError = null;
  @tracked loading = false;
  @tracked loadingHistory = false;
  @tracked loadingOlder = false;
  @tracked messages = [];
  @tracked request = null;
  @tracked selectedId = null;
  @tracked sending = false;
  @tracked starring = null;

  #active = false;
  #generation = 0;
  #historyPage = 0;
  #refreshPromise;
  #refreshQueued = false;
  #streamChannel;
  #streamCallback;
  #streamData = new Map();
  #streamTimer;
  #timer;
  #userChannel;

  #onRequestUpdate = (data) => {
    if (data.conversation_id === this.selectedId) {
      this.refresh();
    }
    this.forumAssistant.refresh();
    this.loadHistory();
  };

  #onStream = (data) => {
    if (data.noop || !data.post_id) {
      return;
    }
    if (
      !data.done &&
      data.post_id === this.request?.reply_post_id &&
      TERMINAL.has(this.request?.status)
    ) {
      return;
    }
    this.#streamData.set(data.post_id, data);
    if (data.done) {
      this.refresh();
      this.forumAssistant.refresh();
    }
    if (!this.#streamTimer) {
      this.#streamTimer = setTimeout(() => {
        this.#streamTimer = null;
        const generation = this.#generation;
        for (const chunk of this.#streamData.values()) {
          this.#renderStream(chunk, generation);
        }
      }, 100);
    }
  };

  willDestroy() {
    super.willDestroy(...arguments);
    this.stop();
  }

  get draft() {
    return (
      this.drafts.get(this.#draftKey) ??
      this.sessionStore.get(this.#draftKey) ??
      ""
    );
  }

  get generating() {
    return Boolean(
      this.selectedId &&
      ((this.request && !TERMINAL.has(this.request.status)) ||
        (this.forumAssistant.status?.busy &&
          this.forumAssistant.status?.active_conversation_id ===
            this.selectedId))
    );
  }

  get disabled() {
    return (
      this.loading ||
      this.sending ||
      (this.selectedId !== null && !this.conversation) ||
      this.conversation?.read_only ||
      !this.forumAssistant.status?.can_ask
    );
  }

  get #draftKey() {
    return `forum-assistant-draft:${this.currentUser?.id}:${this.selectedId ?? "new"}`;
  }

  async start(conversationId) {
    this.#active = true;
    this.#userChannel = `/discourse-ai/forum-assistant/user/${this.currentUser.id}`;
    this.messageBus.subscribe(this.#userChannel, this.#onRequestUpdate);
    await Promise.all([
      this.loadHistory(),
      this.select(conversationId),
      this.forumAssistant.refresh(),
    ]);
    this.#scheduleRefresh();
  }

  stop() {
    this.#active = false;
    this.#generation++;
    clearTimeout(this.#timer);
    clearTimeout(this.#streamTimer);
    this.#streamTimer = null;
    this.#streamData.clear();
    if (this.#userChannel) {
      this.messageBus.unsubscribe(this.#userChannel, this.#onRequestUpdate);
      this.#userChannel = null;
    }
    this.#unsubscribeStream();
    this.selectedId = null;
    this.conversation = null;
    this.messages = [];
    this.request = null;
    this.loading = false;
    this.#refreshPromise = null;
    this.#refreshQueued = false;
  }

  setDraft(raw) {
    this.drafts = new Map(this.drafts).set(this.#draftKey, raw);
    if (raw) {
      this.sessionStore.set({ key: this.#draftKey, value: raw });
    } else {
      this.sessionStore.remove(this.#draftKey);
    }
  }

  async select(value) {
    const id = value ? Number(value) : null;
    if (id === this.selectedId && (this.conversation || this.loading || !id)) {
      return;
    }
    this.#generation++;
    this.#unsubscribeStream();
    this.#streamData.clear();
    this.#refreshPromise = null;
    this.#refreshQueued = false;
    this.selectedId = id;
    this.conversation = null;
    this.messages = [];
    this.request = null;
    this.hasOlder = false;
    this.error = null;
    this.loading = false;
    if (!value) {
      return;
    }
    if (!/^[1-9]\d*$/.test(String(value)) || !Number.isSafeInteger(id)) {
      this.error = i18n("discourse_ai.forum_assistant.workspace.missing");
      return;
    }
    this.#subscribeStream();
    this.loading = true;
    try {
      await this.refresh();
    } finally {
      if (this.selectedId === id) {
        this.loading = false;
      }
    }
  }

  async loadHistory(more = false) {
    if (this.loadingHistory) {
      return;
    }
    const page = more ? this.#historyPage + 1 : 0;
    this.loadingHistory = true;
    this.historyError = null;
    try {
      const result = await ajax(`${BASE}.json`, { data: { page } });
      if (!this.#active) {
        return;
      }
      const existing = more || this.#historyPage > 0 ? this.conversations : [];
      this.conversations = [
        ...new Map(
          [...existing, ...result.conversations].map((item) => [item.id, item])
        ).values(),
      ].sort(
        (left, right) =>
          new Date(right.last_posted_at) - new Date(left.last_posted_at)
      );
      if (more || this.#historyPage === 0) {
        this.hasMoreHistory = result.has_more;
        this.#historyPage = page;
      }
    } catch (error) {
      if (this.#active) {
        this.historyError = extractErrorInfo(error).message;
      }
    } finally {
      this.loadingHistory = false;
    }
  }

  async refresh() {
    if (!this.selectedId || !this.#active) {
      return;
    }
    if (this.#refreshPromise) {
      this.#refreshQueued = true;
      return this.#refreshPromise;
    }
    const id = this.selectedId;
    const generation = this.#generation;
    const promise = ajax(`${BASE}/${id}.json`)
      .then((result) => {
        if (!this.#active || generation !== this.#generation) {
          return;
        }
        this.conversation = result.conversation;
        const firstNumber = result.messages[0]?.post_number ?? Infinity;
        const earlierMessages = this.messages.filter(
          (message) => message.post_number < firstNumber
        );
        this.messages = mergeMessages(earlierMessages, result.messages);
        this.request = result.request;
        if (TERMINAL.has(result.request?.status)) {
          this.#streamData.clear();
        }
        if (!earlierMessages.length) {
          this.hasOlder = result.has_more;
        }
        this.error = null;
        for (const data of this.#streamData.values()) {
          this.#renderStream(data, generation);
        }
      })
      .catch((error) => {
        if (this.#active && generation === this.#generation) {
          const info = extractErrorInfo(error);
          this.error =
            info.status === 404
              ? i18n("discourse_ai.forum_assistant.workspace.missing")
              : info.message;
          if (info.status === 404 || info.status === 403) {
            this.messages = [];
            this.conversation = null;
            this.#unsubscribeStream();
          }
        }
      })
      .finally(() => {
        if (this.#refreshPromise === promise) {
          this.#refreshPromise = null;
          if (
            this.#refreshQueued &&
            this.#active &&
            generation === this.#generation
          ) {
            this.#refreshQueued = false;
            return this.refresh();
          }
        }
      });
    this.#refreshPromise = promise;
    return promise;
  }

  async loadOlder() {
    if (!this.hasOlder || this.loadingOlder || !this.messages.length) {
      return;
    }
    this.loadingOlder = true;
    const generation = this.#generation;
    try {
      const result = await ajax(`${BASE}/${this.selectedId}.json`, {
        data: { before: this.messages[0].post_number },
      });
      if (generation === this.#generation && this.#active) {
        this.messages = mergeMessages(result.messages, this.messages);
        this.hasOlder = result.has_more;
      }
    } catch (error) {
      if (generation === this.#generation && this.#active) {
        this.error = extractErrorInfo(error).message;
      }
    } finally {
      this.loadingOlder = false;
    }
  }

  async send(raw) {
    if (this.disabled || !raw?.trim()) {
      return false;
    }
    const generation = this.#generation;
    const previousId = this.selectedId;
    this.sending = true;
    this.error = null;
    try {
      const result = await ajax(
        previousId ? `${BASE}/${previousId}/messages.json` : `${BASE}.json`,
        {
          type: "POST",
          data: { raw },
        }
      );
      if (this.#active && generation === this.#generation) {
        this.setDraft("");
        this.selectedId = result.conversation_id;
        this.conversation ||= {
          id: result.conversation_id,
          title: raw.slice(0, 60),
          read_only: false,
        };
        this.messages = mergeMessages(this.messages, [result.message]);
        this.request = result.request;
        this.#subscribeStream();
        this.router.replaceWith("discourse-ai-bot-conversations", {
          queryParams: { conversation: result.conversation_id },
        });
        await this.refresh();
      } else {
        this.drafts = new Map(this.drafts).set(
          `forum-assistant-draft:${this.currentUser.id}:${previousId ?? "new"}`,
          ""
        );
        this.sessionStore.remove(
          `forum-assistant-draft:${this.currentUser.id}:${previousId ?? "new"}`
        );
      }
      await this.loadHistory();
      return true;
    } catch (error) {
      if (this.#active && generation === this.#generation) {
        this.error = extractErrorInfo(error).message;
      }
      return false;
    } finally {
      await this.forumAssistant.refresh();
      this.sending = false;
    }
  }

  async cancel() {
    if (!this.selectedId || !this.generating) {
      return;
    }
    try {
      await ajax("/discourse-ai/ai-bot/forum-assistant/cancel.json", {
        type: "POST",
        data: { conversation_id: this.selectedId },
      });
      await Promise.all([this.refresh(), this.forumAssistant.refresh()]);
    } catch (error) {
      this.error = extractErrorInfo(error).message;
    }
  }

  async toggleStar(conversation) {
    if (this.starring) {
      return;
    }
    this.starring = conversation.id;
    try {
      const result = await ajax(
        `/discourse-ai/ai-bot/conversations/${conversation.id}/starred.json`,
        {
          type: "PUT",
          data: { starred: !conversation.starred },
        }
      );
      this.conversations = this.conversations.map((item) =>
        item.id === conversation.id
          ? { ...item, starred: result.starred }
          : item
      );
    } catch (error) {
      this.historyError = extractErrorInfo(error).message;
    } finally {
      this.starring = null;
    }
  }

  async #renderStream(data, generation) {
    const cooked = data.cooked ?? String(await cook(data.raw ?? ""));
    if (
      !this.#active ||
      generation !== this.#generation ||
      this.#streamData.get(data.post_id) !== data
    ) {
      return;
    }
    this.messages = mergeMessages(this.messages, [
      {
        id: data.post_id,
        post_number: data.post_number,
        role: "assistant",
        raw: data.raw,
        cooked,
      },
    ]);
    if (data.done) {
      this.#streamData.delete(data.post_id);
    }
  }

  #subscribeStream() {
    const channel = `discourse-ai/ai-bot/topic/${this.selectedId}`;
    if (this.#streamChannel === channel) {
      return;
    }
    this.#unsubscribeStream();
    this.#streamChannel = channel;
    const generation = this.#generation;
    this.#streamCallback = (data) => {
      if (
        this.#active &&
        generation === this.#generation &&
        this.#streamChannel === channel
      ) {
        this.#onStream(data);
      }
    };
    this.messageBus.subscribe(channel, this.#streamCallback, -2);
  }

  #unsubscribeStream() {
    if (this.#streamChannel) {
      this.messageBus.unsubscribe(this.#streamChannel, this.#streamCallback);
      this.#streamChannel = null;
      this.#streamCallback = null;
    }
  }

  #scheduleRefresh() {
    clearTimeout(this.#timer);
    if (!this.#active) {
      return;
    }
    this.#timer = setTimeout(async () => {
      await this.forumAssistant.refresh();
      if (this.generating) {
        await this.refresh();
      }
      this.#scheduleRefresh();
    }, 10000);
  }
}
