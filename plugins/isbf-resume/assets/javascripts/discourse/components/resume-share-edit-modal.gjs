import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { extractError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

const FIELD_LIMITS = {
  title: 200,
  industry: 120,
  position: 120,
  salary: 120,
  experience: 80,
  description: 2000,
};

export default class ResumeShareEditModal extends Component {
  @service a11y;

  @tracked busy = false;
  @tracked error;

  data = { ...this.args.model.reviewable.payload };

  get fields() {
    return Object.entries(FIELD_LIMITS).map(([name, limit]) => ({
      name,
      limit,
      title: i18n(`isbf_resume.sharing.fields.${name}.title`),
      help:
        name === "description"
          ? i18n("isbf_resume.sharing.review_description_help")
          : name === "title"
            ? i18n("isbf_resume.sharing.review_title_help")
            : i18n(`isbf_resume.sharing.fields.${name}.help`),
      placeholder: i18n(`isbf_resume.sharing.fields.${name}.placeholder`),
      type: name === "description" ? "textarea" : "input-text",
    }));
  }

  @action
  async save(data) {
    this.busy = true;
    this.error = null;
    try {
      const payload = Object.fromEntries(
        Object.keys(FIELD_LIMITS).map((name) => [name, data[name] || ""])
      );
      await this.args.model.reviewable.update({ payload });
      this.a11y.announce(i18n("isbf_resume.sharing.details_saved"));
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
      class="isbf-resume-confirmation isbf-resume-share-edit"
      ...attributes
      @closeModal={{@closeModal}}
      @inline={{@inline}}
      @title={{i18n "isbf_resume.sharing.edit_details"}}
    >
      <:body>
        <p>{{i18n "isbf_resume.sharing.native_review_help"}}</p>
        <Form @data={{this.data}} @onSubmit={{this.save}} as |form|>
          {{#if this.error}}<form.Alert
              @type="error"
            >{{this.error}}</form.Alert>{{/if}}
          {{#each this.fields key="name" as |field|}}
            <form.Field
              @format="full"
              @helpText={{field.help}}
              @name={{field.name}}
              @title={{field.title}}
              @type={{field.type}}
              as |control|
            >
              <control.Control
                maxlength={{field.limit}}
                placeholder={{field.placeholder}}
              />
            </form.Field>
          {{/each}}
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
