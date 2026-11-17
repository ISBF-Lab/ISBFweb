import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class ForumAssistant extends Service {
  @service currentUser;
  @service siteSettings;

  @tracked loading = false;
  @tracked snapshot = null;

  #refreshPromise;

  get status() {
    return this.snapshot ?? this.currentUser?.forum_assistant;
  }

  get restricted() {
    return (
      this.status?.restricted ??
      ((this.siteSettings.ai_forum_assistant_enabled ||
        this.siteSettings.ai_forum_assistant_restrict_members) &&
        Boolean(this.currentUser) &&
        !this.currentUser.admin)
    );
  }

  get message() {
    const status = this.status;
    if (!status?.enabled || !status?.configured) {
      return i18n("discourse_ai.forum_assistant.unavailable");
    }
    if (status.blocked_until) {
      return i18n("discourse_ai.forum_assistant.cooldown", {
        time: this.#formatTime(status.blocked_until),
      });
    }
    if (status.busy) {
      return i18n("discourse_ai.forum_assistant.busy");
    }
    if (status.global_limit_reached) {
      return i18n("discourse_ai.forum_assistant.global_limit", {
        time: this.#formatTime(status.resets_at),
      });
    }
    return i18n("discourse_ai.forum_assistant.remaining", {
      remaining: status.remaining_today,
      limit: status.daily_limit,
      time: this.#formatTime(status.resets_at),
    });
  }

  isSelected(agentId) {
    return (
      this.restricted ||
      (this.status?.enabled && Number(agentId) === this.status?.agent?.id)
    );
  }

  async refresh() {
    if (!this.currentUser) {
      return;
    }
    if (this.#refreshPromise) {
      return this.#refreshPromise;
    }
    this.loading = true;
    this.#refreshPromise = ajax(
      "/discourse-ai/ai-bot/forum-assistant/status.json"
    )
      .then((status) => {
        this.snapshot = status;
        return status;
      })
      .catch(() => {
        this.snapshot = { ...this.status, can_ask: false, configured: false };
        return this.snapshot;
      })
      .finally(() => {
        this.loading = false;
        this.#refreshPromise = null;
      });
    return this.#refreshPromise;
  }

  async cancel() {
    await ajax("/discourse-ai/ai-bot/forum-assistant/cancel.json", {
      method: "POST",
    });
    await this.refresh();
  }

  #formatTime(value) {
    return value ? new Date(value).toLocaleString() : "";
  }
}
