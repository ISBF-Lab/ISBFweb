import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import ResumeSharingHeader from "./resume-sharing-header";

const FIELD_LIMITS = {
  title: 200,
  industry: 120,
  position: 120,
  salary: 120,
  experience: 80,
  description: 2000,
};
const MAX_BYTES = 10 * 1024 * 1024;

export default class ResumeShareUpload extends Component {
  @service a11y;
  @service router;

  @tracked error;
  @tracked busy = false;

  data = {
    file: "",
    consent: false,
    title: "",
    industry: "",
    position: "",
    salary: "",
    experience: "",
    description: "",
  };
  #file;

  get fields() {
    return Object.entries(FIELD_LIMITS).map(([name, limit]) => ({
      name,
      limit,
      title: i18n(`isbf_resume.sharing.fields.${name}.title`),
      help: i18n(`isbf_resume.sharing.fields.${name}.help`),
      placeholder: i18n(`isbf_resume.sharing.fields.${name}.placeholder`),
      type: name === "description" ? "textarea" : "input-text",
      fullRow: name === "title" || name === "description",
    }));
  }

  @action
  selectFile(setValue, event) {
    const file = event.target.files?.[0];
    this.error = null;
    if (
      file &&
      (!/\.pdf$/i.test(file.name) || file.size < 1 || file.size > MAX_BYTES)
    ) {
      event.target.value = "";
      this.#file = null;
      setValue("");
      this.error = i18n("isbf_resume.sharing.invalid_pdf");
      this.a11y.announce(this.error, "assertive");
      return;
    }
    this.#file = file;
    setValue(file?.name || "");
  }

  @action
  async submit(data) {
    this.error = null;
    this.busy = true;
    const body = new FormData();
    body.append("shared_resume[file]", this.#file);
    body.append("shared_resume[consent]", String(data.consent === true));
    for (const name of Object.keys(FIELD_LIMITS)) {
      body.append(`shared_resume[${name}]`, data[name] || "");
    }
    try {
      const share = await ajax("/isbf-resume/shares.json", {
        type: "POST",
        data: body,
        processData: false,
        contentType: false,
      });
      this.a11y.announce(i18n("isbf_resume.sharing.submitted"));
      this.router.transitionTo("isbfResumeShares.show", share.id);
    } catch (error) {
      this.error = extractError(error);
      this.a11y.announce(this.error, "assertive");
    } finally {
      this.busy = false;
    }
  }

  <template>
    <main class="isbf-resume isbf-resume-share-upload" ...attributes>
      <ResumeSharingHeader
        @backHref="/isbf/workbench/resume/shares"
        @title={{i18n "isbf_resume.sharing.upload_title"}}
      />
      <p class="isbf-resume__intro">{{i18n
          "isbf_resume.sharing.optional_notice"
        }}</p>
      <Form
        class="isbf-resume__form"
        @data={{this.data}}
        @onSubmit={{this.submit}}
        as |form|
      >
        {{#if this.error}}<form.Alert
            @type="error"
          >{{this.error}}</form.Alert>{{/if}}
        <form.Field
          @name="file"
          @title={{i18n "isbf_resume.sharing.pdf"}}
          @type="custom"
          @validation="required"
          as |field|
        >
          <field.Control><input
              accept="application/pdf,.pdf"
              aria-describedby={{concat
                field.errorId
                " isbf-resume-sharing-pdf-help"
              }}
              disabled={{this.busy}}
              id={{field.id}}
              type="file"
              {{on "change" (fn this.selectFile field.set)}}
            /><p id="isbf-resume-sharing-pdf-help">{{i18n
                "isbf_resume.sharing.pdf_help"
              }}</p></field.Control>
        </form.Field>
        <div class="isbf-resume__fields">
          {{#each this.fields key="name" as |field|}}
            <form.Field
              class={{dConcatClass
                "isbf-resume__field"
                (if field.fullRow "--full-row")
              }}
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
        </div>
        <form.Field
          @helpText={{i18n "isbf_resume.sharing.privacy_notice"}}
          @name="consent"
          @title={{i18n "isbf_resume.sharing.consent"}}
          @type="checkbox"
          @validation="accepted"
          as |field|
        ><field.Control /></form.Field>
        <form.Submit @label="isbf_resume.sharing.submit" />
      </Form>
    </main>
  </template>
}
