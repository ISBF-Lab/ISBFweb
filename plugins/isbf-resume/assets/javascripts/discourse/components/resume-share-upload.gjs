import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import ResumeContributorFields from "./resume-contributor-fields";
import ResumeSharingHeader from "./resume-sharing-header";

const FIELD_LIMITS = {
  title: 200,
  industry: 120,
  position: 120,
  salary: 120,
  experience: 80,
  description: 2000,
  download_url: 2048,
};
const MAX_BYTES = 10 * 1024 * 1024;

export default class ResumeShareUpload extends Component {
  @service a11y;
  @service router;
  @service siteSettings;

  @tracked error;
  @tracked busy = false;
  @tracked previewSource = "pdf";

  data = {
    file: "",
    consent: false,
    title: "",
    industry: "",
    position: "",
    salary: "",
    experience: "",
    description: "",
    download_url: "",
    contributor: "",
    student_number: "",
    contributor_user_id: "",
    preview_source: "pdf",
    preview_images: "",
  };
  #file;
  #images = [];

  get canUpload() {
    return this.args.model?.can_submit === true;
  }

  get collectionUrl() {
    return (
      this.args.model?.collection_url ||
      this.siteSettings.isbf_resume_collection_url
    );
  }

  get fields() {
    return Object.entries(FIELD_LIMITS).map(([name, limit]) => ({
      name,
      limit,
      title: i18n(`isbf_resume.sharing.fields.${name}.title`),
      help: i18n(`isbf_resume.sharing.fields.${name}.help`),
      placeholder: i18n(`isbf_resume.sharing.fields.${name}.placeholder`),
      type:
        name === "description"
          ? "textarea"
          : name === "download_url"
            ? "input-url"
            : "input-text",
      fullRow: ["title", "description", "download_url"].includes(name),
      validation: name === "download_url" ? "required" : null,
    }));
  }

  @action
  changeSource(value, { set }) {
    set("preview_source", value);
    set("file", "");
    set("preview_images", "");
    this.previewSource = value;
    this.#file = null;
    this.#images = [];
    this.error = null;
  }

  @action
  selectImages(setValue, event) {
    const images = Array.from(event.target.files || []);
    this.error = null;
    if (
      images.length > 3 ||
      images.some(
        (image) => !/\.(png|jpe?g|webp)$/i.test(image.name) || image.size < 1
      ) ||
      images.reduce((size, image) => size + image.size, 0) > MAX_BYTES
    ) {
      event.target.value = "";
      this.#images = [];
      setValue("");
      this.error = i18n("isbf_resume.sharing.invalid_images");
      this.a11y.announce(this.error, "assertive");
      return;
    }
    this.#images = images;
    setValue(images.map((image) => image.name).join(", "));
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
      this.error = i18n(
        file.size > MAX_BYTES
          ? "isbf_resume.sharing.pdf_too_large"
          : "isbf_resume.sharing.invalid_pdf"
      );
      this.a11y.announce(this.error, "assertive");
      return;
    }
    this.#file = file;
    setValue(file?.name || "");
  }

  @action
  async submit(data) {
    if (!this.canUpload) {
      return;
    }
    this.error = null;
    this.busy = true;
    const body = new FormData();
    if (this.#file) {
      body.append("shared_resume[file]", this.#file);
    }
    for (const image of this.#images) {
      body.append("shared_resume[preview_images][]", image);
    }
    body.append("shared_resume[consent]", String(data.consent === true));
    for (const name of Object.keys(FIELD_LIMITS)) {
      body.append(`shared_resume[${name}]`, data[name] || "");
    }
    for (const name of [
      "contributor",
      "student_number",
      "contributor_user_id",
    ]) {
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
      {{#if this.canUpload}}
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
            @format="full"
            @name="preview_source"
            @onSet={{this.changeSource}}
            @title={{i18n "isbf_resume.sharing.preview_source"}}
            @type="select"
            as |field|
          >
            <field.Control as |select|>
              <select.Option @value="pdf">{{i18n
                  "isbf_resume.sharing.preview_pdf"
                }}</select.Option>
              <select.Option @value="images">{{i18n
                  "isbf_resume.sharing.preview_images"
                }}</select.Option>
            </field.Control>
          </form.Field>
          {{#if (eq this.previewSource "pdf")}}
            <form.Field
              @format="full"
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
          {{else}}
            <form.Field
              @format="full"
              @helpText={{i18n "isbf_resume.sharing.images_help"}}
              @name="preview_images"
              @title={{i18n "isbf_resume.sharing.preview_images"}}
              @type="custom"
              @validation="required"
              as |field|
            >
              <field.Control><input
                  accept="image/png,image/jpeg,image/webp,.png,.jpg,.jpeg,.webp"
                  disabled={{this.busy}}
                  id={{field.id}}
                  multiple
                  type="file"
                  {{on "change" (fn this.selectImages field.set)}}
                /></field.Control>
            </form.Field>
          {{/if}}
          <div class="isbf-resume__fields">
            {{#each this.fields key="name" as |field|}}
              <form.Field
                class={{dConcatClass
                  "isbf-resume__field"
                  (if field.fullRow "--full-row")
                }}
                @format="full"
                @helpText={{field.help}}
                @name={{field.name}}
                @title={{field.title}}
                @type={{field.type}}
                @validation={{field.validation}}
                as |control|
              >
                <control.Control
                  maxlength={{field.limit}}
                  placeholder={{field.placeholder}}
                />
              </form.Field>
            {{/each}}
          </div>
          <ResumeContributorFields
            @data={{this.data}}
            @disabled={{this.busy}}
            @form={{form}}
          />
          <form.Field
            @format="full"
            @helpText={{i18n "isbf_resume.sharing.privacy_notice"}}
            @name="consent"
            @title={{i18n "isbf_resume.sharing.consent"}}
            @type="checkbox"
            @validation="accepted"
            as |field|
          ><field.Control /></form.Field>
          <form.Submit @label="isbf_resume.sharing.submit" />
        </Form>
      {{else}}
        <p class="isbf-resume__intro">{{i18n
            "isbf_resume.sharing.collection_notice"
          }}</p>
        <p class="isbf-resume__intro">{{i18n
            "isbf_resume.sharing.collection_privacy"
          }}</p>
        <DButton
          class="btn-primary"
          data-auto-route="false"
          rel="noopener noreferrer"
          target="_blank"
          @href={{this.collectionUrl}}
          @label="isbf_resume.sharing.open_collection"
        />
      {{/if}}
    </main>
  </template>
}
