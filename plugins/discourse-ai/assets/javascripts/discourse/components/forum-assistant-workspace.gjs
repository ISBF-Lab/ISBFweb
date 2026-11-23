import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import bodyClass from "discourse/helpers/body-class";
import getURL from "discourse/lib/get-url";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import linkForumPaths from "../lib/forum-assistant-links";
import ForumAssistantComposer from "./forum-assistant-composer";

function cookedHTML(value) {
  return trustHTML(value || "");
}

export default class ForumAssistantWorkspace extends Component {
  @service forumAssistant;
  @service("forum-assistant-workspace") workspace;
  @service router;

  @tracked historyOpen = false;

  #lastConversation;
  #messageElement;
  #rootElement;
  #stickToBottom = true;

  #syncViewport = () => {
    const viewport = window.visualViewport;
    if (this.#rootElement && !this.isDestroying) {
      const height =
        viewport?.scale === 1 ? viewport.height : window.innerHeight;
      this.#rootElement.style.setProperty(
        "--forum-assistant-viewport-height",
        `${height}px`
      );
    }
  };

  willDestroy() {
    super.willDestroy(...arguments);
    window.visualViewport?.removeEventListener("resize", this.#syncViewport);
    window.removeEventListener("resize", this.#syncViewport);
    window.removeEventListener("keydown", this.handleKeyDown);
    this.workspace.stop();
  }

  get historyGroups() {
    const groups = new Map();
    const midnight = new Date();
    midnight.setHours(0, 0, 0, 0);
    for (const conversation of this.workspace.conversations) {
      const age = (midnight - new Date(conversation.last_posted_at)) / 86400000;
      const key = conversation.starred
        ? "starred"
        : age < 0
          ? "today"
          : age < 7
            ? "week"
            : "older";
      if (!groups.has(key)) {
        groups.set(key, {
          key,
          title: i18n(`discourse_ai.forum_assistant.workspace.${key}`),
          conversations: [],
        });
      }
      groups.get(key).conversations.push({
        ...conversation,
        href: `/discourse-ai/ai-bot/conversations?conversation=${conversation.id}`,
        starTitle: conversation.starred
          ? "discourse_ai.ai_bot.conversations.unstar_conversation"
          : "discourse_ai.ai_bot.conversations.star_conversation",
      });
    }
    return ["starred", "today", "week", "older"]
      .map((key) => groups.get(key))
      .filter(Boolean);
  }

  get outcomeMessage() {
    const status = this.workspace.request?.status;
    return ["failed", "expired", "cancelled"].includes(status)
      ? i18n(`discourse_ai.forum_assistant.workspace.${status}`)
      : null;
  }

  @action
  start(element) {
    this.#rootElement = element;
    this.#syncViewport();
    window.visualViewport?.addEventListener("resize", this.#syncViewport);
    window.addEventListener("resize", this.#syncViewport);
    window.addEventListener("keydown", this.handleKeyDown);
    return this.workspace.start(this.args.conversationId);
  }

  @action
  selectConversation() {
    this.#stickToBottom = true;
    return this.workspace.select(this.args.conversationId);
  }

  @action
  openConversation(id, event) {
    if (event && wantsNewWindow(event)) {
      return;
    }
    event?.preventDefault();
    this.historyOpen = false;
    this.router.transitionTo("discourse-ai-bot-conversations", {
      queryParams: { conversation: id },
    });
  }

  @action
  newConversation() {
    this.openConversation(null);
  }

  @action
  toggleHistory() {
    this.historyOpen = !this.historyOpen;
    requestAnimationFrame(() => {
      this.#rootElement
        ?.querySelector(
          this.historyOpen
            ? ".forum-assistant-workspace__new"
            : ".forum-assistant-workspace__open-history"
        )
        ?.focus({ preventScroll: true });
    });
  }

  @action
  handleKeyDown(event) {
    if (this.historyOpen && event.key === "Escape") {
      event.preventDefault();
      this.toggleHistory();
    }
  }

  @action
  loadHistory() {
    return this.workspace.loadHistory(true);
  }

  @action
  retryHistory() {
    return this.workspace.loadHistory();
  }

  @action
  toggleStar(conversation) {
    return this.workspace.toggleStar(conversation);
  }

  @action
  refresh() {
    return Promise.all([
      this.workspace.refresh(),
      this.forumAssistant.refresh(),
    ]);
  }

  @action
  async loadOlder() {
    const height = this.#messageElement.scrollHeight;
    const top = this.#messageElement.scrollTop;
    this.#stickToBottom = false;
    await this.workspace.loadOlder();
    requestAnimationFrame(() => {
      if (this.#messageElement && !this.isDestroying) {
        this.#messageElement.scrollTop =
          top + this.#messageElement.scrollHeight - height;
      }
    });
  }

  @action
  registerMessages(element) {
    this.#messageElement = element;
  }

  @action
  recordScroll(event) {
    const element = event.target;
    this.#stickToBottom =
      element.scrollHeight - element.scrollTop - element.clientHeight < 80;
  }

  @action
  scrollMessages() {
    const changed = this.#lastConversation !== this.workspace.selectedId;
    this.#lastConversation = this.workspace.selectedId;
    if (changed || this.#stickToBottom) {
      requestAnimationFrame(() => {
        if (this.#messageElement && !this.isDestroying) {
          this.#messageElement.scrollTop = this.#messageElement.scrollHeight;
        }
      });
    }
  }

  <template>
    {{bodyClass "forum-assistant-workspace-page"}}
    <div
      class={{dConcatClass
        "forum-assistant-workspace"
        (if this.historyOpen "--history-open")
      }}
      {{didInsert this.start}}
      {{didUpdate this.selectConversation @conversationId}}
    >
      <header class="forum-assistant-workspace__header">
        <a
          aria-label={{i18n "discourse_ai.forum_assistant.workspace.back"}}
          class="forum-assistant-workspace__back"
          href={{getURL "/isbf/workbench"}}
        >{{dIcon "arrow-left"}}</a>
        <h1>{{i18n "discourse_ai.forum_assistant.workspace.title"}}</h1>
        <DButton
          aria-controls="forum-assistant-history"
          aria-expanded={{if this.historyOpen "true" "false"}}
          class="btn-flat forum-assistant-workspace__open-history"
          @action={{this.toggleHistory}}
          @label="discourse_ai.forum_assistant.workspace.history"
        />
      </header>
      <div class="forum-assistant-workspace__body">
        <aside
          aria-label={{i18n "discourse_ai.forum_assistant.workspace.history"}}
          class="forum-assistant-workspace__history"
          id="forum-assistant-history"
        >
          <div class="forum-assistant-workspace__history-heading">
            <h2>{{i18n "discourse_ai.forum_assistant.workspace.history"}}</h2>
            <DButton
              class="btn-flat forum-assistant-workspace__close-history"
              @action={{this.toggleHistory}}
              @icon="xmark"
              @title="close"
            />
          </div>
          <DButton
            class="forum-assistant-workspace__new btn-primary"
            @action={{this.newConversation}}
            @icon="plus"
            @label="discourse_ai.forum_assistant.new_conversation"
          />
          <nav class="forum-assistant-workspace__history-list">
            {{#each this.historyGroups as |group|}}
              <section class="forum-assistant-workspace__history-group">
                <h3>{{group.title}}</h3>
                {{#each group.conversations key="id" as |conversation|}}
                  <div
                    class={{dConcatClass
                      "forum-assistant-workspace__history-item"
                      (if
                        (eq conversation.id this.workspace.selectedId)
                        "is-active"
                      )
                    }}
                  >
                    <a
                      aria-current={{if
                        (eq conversation.id this.workspace.selectedId)
                        "page"
                      }}
                      href={{conversation.href}}
                      title={{conversation.title}}
                      {{on "click" (fn this.openConversation conversation.id)}}
                    >{{conversation.title}}</a>
                    <DButton
                      class="btn-flat forum-assistant-workspace__star"
                      @action={{fn this.toggleStar conversation}}
                      @disabled={{eq this.workspace.starring conversation.id}}
                      @icon={{if conversation.starred "star" "far-star"}}
                      @title={{conversation.starTitle}}
                    />
                  </div>
                {{/each}}
              </section>
            {{else}}
              {{#unless this.workspace.loadingHistory}}
                <p class="forum-assistant-workspace__empty-history">{{i18n
                    "discourse_ai.forum_assistant.workspace.empty_history"
                  }}</p>
              {{/unless}}
            {{/each}}
            {{#if this.workspace.historyError}}
              <p role="alert">{{this.workspace.historyError}}</p>
              <DButton
                class="btn-flat"
                @action={{this.retryHistory}}
                @label="retry"
              />
            {{else if this.workspace.hasMoreHistory}}
              <DButton
                class="btn-flat"
                @action={{this.loadHistory}}
                @isLoading={{this.workspace.loadingHistory}}
                @label="discourse_ai.forum_assistant.workspace.more"
              />
            {{/if}}
          </nav>
        </aside>
        <section
          aria-label={{i18n "discourse_ai.forum_assistant.workspace.title"}}
          class="forum-assistant-workspace__main"
        >
          {{#if this.workspace.conversation}}
            <div class="forum-assistant-workspace__conversation-heading">
              <span
                class="forum-assistant-workspace__conversation-title"
                title={{this.workspace.conversation.title}}
              >{{this.workspace.conversation.title}}</span>
            </div>
          {{/if}}
          <div
            aria-busy={{this.workspace.loading}}
            class="forum-assistant-workspace__messages"
            {{didInsert this.registerMessages}}
            {{didUpdate
              this.scrollMessages
              this.workspace.messages
              this.workspace.selectedId
            }}
            {{on "scroll" this.recordScroll}}
          >
            <div class="forum-assistant-workspace__message-content">
              {{#if this.workspace.loading}}
                <p role="status">{{i18n "loading"}}</p>
              {{else if this.workspace.selectedId}}
                {{#if this.workspace.hasOlder}}
                  <DButton
                    class="btn-flat forum-assistant-workspace__older"
                    @action={{this.loadOlder}}
                    @isLoading={{this.workspace.loadingOlder}}
                    @label="discourse_ai.forum_assistant.workspace.older_messages"
                  />
                {{/if}}
                <div
                  aria-live="polite"
                  aria-relevant="additions"
                  class="forum-assistant-workspace__log"
                  role="log"
                >
                  {{#each this.workspace.messages key="id" as |message|}}
                    <article
                      class={{dConcatClass
                        "forum-assistant-message"
                        (if (eq message.role "user") "--user" "--assistant")
                      }}
                      data-message-id={{message.id}}
                    >
                      {{#if (eq message.role "user")}}
                        <span class="sr-only">{{i18n
                            "discourse_ai.forum_assistant.workspace.you"
                          }}</span>
                        <div
                          class="forum-assistant-message__question"
                        >{{message.raw}}</div>
                      {{else}}
                        <span class="forum-assistant-message__role">{{dIcon
                            "far-discobot"
                          }}{{i18n
                            "discourse_ai.forum_assistant.workspace.title"
                          }}</span>
                        <div
                          class="forum-assistant-message__answer cooked"
                          {{didInsert linkForumPaths}}
                          {{didUpdate linkForumPaths message.cooked}}
                        >{{cookedHTML message.cooked}}</div>
                      {{/if}}
                    </article>
                  {{/each}}
                </div>
                {{#if this.workspace.generating}}
                  <p
                    class="forum-assistant-workspace__pending"
                    role="status"
                  >{{i18n "discourse_ai.forum_assistant.busy"}}</p>
                {{/if}}
                {{#if this.outcomeMessage}}
                  <p
                    class="forum-assistant-workspace__outcome"
                    role="status"
                  >{{this.outcomeMessage}}</p>
                {{/if}}
              {{else}}
                <div class="forum-assistant-workspace__welcome">
                  <span class="forum-assistant-workspace__welcome-icon">{{dIcon
                      "far-discobot"
                    }}</span>
                  <h2>{{i18n
                      "discourse_ai.forum_assistant.workspace.welcome"
                    }}</h2>
                  <p>{{i18n "discourse_ai.forum_assistant.scope"}}</p>
                </div>
              {{/if}}
              {{#if this.workspace.error}}
                <div class="forum-assistant-workspace__error" role="alert">
                  <p>{{this.workspace.error}}</p>
                  <DButton
                    class="btn-flat"
                    @action={{this.refresh}}
                    @label="retry"
                  />
                </div>
              {{/if}}
            </div>
          </div>
          <footer class="forum-assistant-workspace__footer">
            <div class="forum-assistant-workspace__composer-content">
              <p class="sr-only" id="forum-assistant-scope">{{i18n
                  "discourse_ai.forum_assistant.scope"
                }}</p>
              {{#if this.workspace.conversation.read_only}}
                <p class="forum-assistant-workspace__read-only">{{i18n
                    "discourse_ai.forum_assistant.read_only"
                  }}</p>
              {{/if}}
              <ForumAssistantComposer @workspace={{this.workspace}} />
              <div class="forum-assistant-workspace__allowance">
                <p
                  aria-live="polite"
                  id="forum-assistant-allowance"
                  role="status"
                >{{this.forumAssistant.message}}</p>
                <DButton
                  class="btn-flat"
                  @action={{this.refresh}}
                  @icon="rotate"
                  @title="discourse_ai.forum_assistant.refresh"
                />
              </div>
              <p class="forum-assistant-workspace__disclaimer">{{i18n
                  "discourse_ai.ai_bot.conversations.disclaimer"
                }}</p>
            </div>
          </footer>
        </section>
      </div>
    </div>
  </template>
}
