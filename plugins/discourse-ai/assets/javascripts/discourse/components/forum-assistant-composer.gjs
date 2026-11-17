import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { SEND_SHORTCUT_META_ENTER } from "discourse/lib/constants";
import { not, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ForumAssistantComposer extends Component {
  @service currentUser;
  @service siteSettings;

  formData;
  #form;

  constructor(owner, args) {
    super(owner, args);
    this.formData = { raw: args.workspace.draft };
  }

  @action
  registerForm(form) {
    this.#form = form;
  }

  @action
  restoreDraft() {
    this.#form?.set("raw", this.args.workspace.draft);
    this.#form?.removeErrors();
  }

  @action
  saveDraft(name, value) {
    if (name === "raw") {
      this.args.workspace.setDraft(value);
    }
  }

  @action
  skipDirtyCheck() {
    return false;
  }

  @action
  handleKeyDown(event) {
    if (
      event.key !== "Enter" ||
      event.isComposing ||
      event.repeat ||
      event.shiftKey ||
      event.ctrlKey ||
      event.metaKey
    ) {
      return;
    }
    if (
      this.currentUser.user_option?.send_shortcut !== SEND_SHORTCUT_META_ENTER
    ) {
      event.preventDefault();
      this.#form?.submit();
    }
  }

  @action
  async submit({ raw }) {
    if ((await this.args.workspace.send(raw)) && !this.isDestroying) {
      this.restoreDraft();
    }
  }

  @action
  cancel() {
    return this.args.workspace.cancel();
  }

  <template>
    <div
      class="forum-assistant-composer"
      {{didUpdate this.restoreDraft @workspace.selectedId}}
    >
      <Form
        @commitOnSubmit={{false}}
        @data={{this.formData}}
        @onDirtyCheck={{this.skipDirtyCheck}}
        @onRegisterApi={{this.registerForm}}
        @onSet={{this.saveDraft}}
        @onSubmit={{this.submit}}
        as |form data|
      >
        <form.Field
          @disabled={{@workspace.disabled}}
          @format="full"
          @name="raw"
          @title={{i18n
            "discourse_ai.forum_assistant.workspace.question_label"
          }}
          @type="textarea"
          as |field|
        >
          <field.Control
            aria-describedby="forum-assistant-scope forum-assistant-allowance"
            maxlength={{this.siteSettings.ai_forum_assistant_max_question_chars}}
            placeholder={{i18n
              "discourse_ai.forum_assistant.workspace.placeholder"
            }}
            rows="2"
            @autoResize={{true}}
            {{on "keydown" this.handleKeyDown}}
          />
        </form.Field>
        {{#if @workspace.generating}}
          <DButton
            class="forum-assistant-composer__send btn-primary"
            @action={{this.cancel}}
            @icon="pause"
            @title="discourse_ai.forum_assistant.stop"
          />
        {{else}}
          <DButton
            class="forum-assistant-composer__send btn-primary"
            type="submit"
            @disabled={{or @workspace.disabled (not data.raw)}}
            @icon="paper-plane"
            @isLoading={{@workspace.sending}}
            @title="discourse_ai.forum_assistant.workspace.send"
          />
        {{/if}}
      </Form>
    </div>
  </template>
}
