import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action, get, set } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import htmlClass from "discourse/helpers/html-class";
import { ajax } from "discourse/lib/ajax";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFLearningCollectionFormDialog extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked error;
  @tracked saving = false;

  data;
  #closed = false;

  constructor() {
    super(...arguments);
    this.data = {
      url: get(this.siteSettings, this.settingName),
    };
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get settingName() {
    return this.args.library
      ? "isbf_library_collection_form_url"
      : "isbf_learning_collection_form_url";
  }

  get canManage() {
    return Boolean(
      this.currentUser &&
      (get(this.currentUser, "admin") ||
        get(this.currentUser, "academy_moderator_permissions.manage_resources"))
    );
  }

  @action
  close() {
    if (!this.saving) {
      this.#closed = true;
      this.args.onClose();
    }
  }

  @action
  async save(data) {
    if (this.#closed || this.saving || !this.canManage) {
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      const response = await ajax(
        `/isbf/${this.args.library ? "library" : "learning"}/collection-form`,
        {
          type: "PUT",
          data: { url: data.url.trim() },
        }
      );
      if (response.success !== true || !response.url) {
        throw new Error("Unexpected collection form response");
      }
      if (!this.#closed) {
        set(this.siteSettings, this.settingName, response.url);
        this.#closed = true;
        this.args.onSaved();
      }
    } catch (error) {
      if (!this.#closed) {
        this.error =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          error?.responseJSON?.errors?.[0] ||
          i18n(themePrefix("isbf_v2.learning_collection_save_error"));
      }
    } finally {
      if (!this.#closed) {
        this.saving = false;
      }
    }
  }

  <template>
    {{htmlClass "isbf-learning-collection-open"}}
    <DModal
      class="isbf-learning-share-dialog isbf-learning-collection-modal isbf-learning-collection-form-dialog"
      @closeModal={{this.close}}
      @dismissable={{not this.saving}}
      @submitOnEnter={{false}}
      @title={{i18n (themePrefix "isbf_v2.learning_collection_settings")}}
    >
      <:body>
        {{#if this.canManage}}
          <Form @data={{this.data}} @onSubmit={{this.save}} as |form|>
            <form.Field
              @name="url"
              @title={{i18n (themePrefix "isbf_v2.learning_collection_url")}}
              @type="input"
              @validation="required|url"
              as |field|
            >
              <field.Control disabled={{this.saving}} @type="url" />
            </form.Field>
            {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
            <form.Actions>
              <DButton
                @action={{this.close}}
                @disabled={{this.saving}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
              />
              <form.Submit @label={{themePrefix "isbf_v2.learning_save"}} />
            </form.Actions>
          </Form>
        {{/if}}
      </:body>
    </DModal>
  </template>
}
