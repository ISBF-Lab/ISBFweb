import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ResumeCollectionModal extends Component {
  @service a11y;

  @tracked busy = false;
  @tracked error;

  data = { url: this.args.model.url };

  @action
  async save(data) {
    this.busy = true;
    this.error = null;
    try {
      const response = await ajax("/isbf-resume/collection.json", {
        type: "PUT",
        data: { url: data.url.trim() },
      });
      this.args.model.onSaved(response.collection_url);
      this.a11y.announce(i18n("isbf_resume.sharing.collection_saved"));
      this.args.closeModal();
    } catch (error) {
      this.error = extractError(error);
      this.a11y.announce(this.error, "assertive");
    } finally {
      this.busy = false;
    }
  }

  <template>
    <DModal
      class="isbf-resume-confirmation"
      ...attributes
      @closeModal={{@closeModal}}
      @inline={{@inline}}
      @title={{i18n "isbf_resume.sharing.edit_collection"}}
    >
      <:body>
        <Form @data={{this.data}} @onSubmit={{this.save}} as |form|>
          {{#if this.error}}<form.Alert
              @type="error"
            >{{this.error}}</form.Alert>{{/if}}
          <form.Field
            @format="full"
            @helpText={{i18n "isbf_resume.sharing.collection_help"}}
            @name="url"
            @title={{i18n "isbf_resume.sharing.collection_url"}}
            @type="input-url"
            @validation="required"
            as |field|
          >
            <field.Control disabled={{this.busy}} maxlength={{2048}} />
          </form.Field>
          <form.Submit @label="review.save" />
          <DButton
            class="btn-default"
            @action={{@closeModal}}
            @disabled={{this.busy}}
            @label="review.cancel"
          />
        </Form>
      </:body>
    </DModal>
  </template>
}
