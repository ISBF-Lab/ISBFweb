import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ForumAssistantStatus extends Component {
  @service forumAssistant;

  #timer;

  willDestroy() {
    super.willDestroy(...arguments);
    clearTimeout(this.#timer);
  }

  @action
  async refresh() {
    clearTimeout(this.#timer);
    await this.forumAssistant.refresh();
    if (!this.isDestroying) {
      this.#timer = setTimeout(this.refresh, 10000);
    }
  }

  @action
  async cancel() {
    try {
      await this.forumAssistant.cancel();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <section
      class="forum-assistant-status"
      ...attributes
      {{didInsert this.refresh}}
    >
      <p>{{i18n "discourse_ai.forum_assistant.scope"}}</p>
      {{#if @readOnly}}
        <p>{{i18n "discourse_ai.forum_assistant.read_only"}}
          <a href="/discourse-ai/ai-bot/conversations">{{i18n
              "discourse_ai.forum_assistant.new_conversation"
            }}</a>
        </p>
      {{else}}
        <p aria-live="polite" role="status">{{this.forumAssistant.message}}</p>
        {{#if this.forumAssistant.status.busy}}
          <DButton
            class="btn-flat"
            @action={{this.cancel}}
            @icon="pause"
            @label="discourse_ai.forum_assistant.stop"
          />
        {{/if}}
      {{/if}}
      <DButton
        class="btn-flat"
        @action={{this.refresh}}
        @disabled={{this.forumAssistant.loading}}
        @icon="rotate"
        @label="discourse_ai.forum_assistant.refresh"
      />
    </section>
  </template>
}
