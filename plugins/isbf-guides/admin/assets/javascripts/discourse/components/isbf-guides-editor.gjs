import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import DPickFilesButton from "discourse/ui-kit/d-pick-files-button";
import { i18n } from "discourse-i18n";

export default class IsbfGuidesEditor extends Component {
  @service dialog;
  @service router;

  @tracked savedGuide;
  @tracked formApi;
  @tracked busy = false;
  @tracked error;
  @tracked notice;

  constructor() {
    super(...arguments);
    window.addEventListener("beforeunload", this.beforeUnload);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    window.removeEventListener("beforeunload", this.beforeUnload);
  }

  get guide() {
    const incoming = this.args.guide;
    if (
      !incoming ||
      (this.savedGuide?.id === incoming.id &&
        this.savedGuide.version >= incoming.version)
    ) {
      return this.savedGuide ?? incoming;
    }
    return incoming;
  }

  @cached
  get forms() {
    const draft = this.guide?.draft;
    return [
      {
        // Saving or publishing must not recreate the editor while its plugins load.
        id: this.args.guide?.id ?? "new",
        data: {
          slug: this.guide?.slug ?? "",
          title: draft?.title ?? "",
          summary: draft?.summary ?? "",
          raw: draft?.raw ?? "",
          source_file: null,
        },
      },
    ];
  }

  get publicationDisabled() {
    return this.busy || !this.guide || this.formApi?.isDirty;
  }

  get isLegacyMarkdown() {
    return this.guide?.draft.content_format === "markdown";
  }

  get sourceUrl() {
    return this.guide
      ? `/isbf/guides/admin/guides/${this.guide.id}/source`
      : null;
  }

  get previewUrl() {
    return this.guide ? `${this.guide.url}?preview=1` : null;
  }

  @action
  registerApi(api) {
    this.formApi = api;
  }

  @action
  beforeUnload(event) {
    if (this.formApi?.isDirty) {
      event.preventDefault();
      event.returnValue = "";
    }
  }

  @action
  async save(data) {
    this.busy = true;
    this.error = null;
    this.notice = null;
    const isNew = !this.guide;
    try {
      const base = `/isbf/guides/admin/guides${isNew ? "" : `/${this.guide.id}`}`;
      const metadata = {
        slug: data.slug,
        title: data.title,
        summary: data.summary,
        version: this.guide?.version,
      };
      let response;
      if (data.source_file) {
        const payload = new FormData();
        for (const [name, value] of Object.entries(metadata)) {
          if (value !== undefined) {
            payload.append(name, value);
          }
        }
        payload.append("file", data.source_file);
        response = await ajax(`${base}/import.json`, {
          type: "POST",
          data: payload,
          processData: false,
          contentType: false,
        });
      } else {
        if (isNew) {
          this.error = i18n("isbf_guides.admin.file_required");
          return;
        }
        if (this.isLegacyMarkdown) {
          metadata.raw = data.raw;
        }
        response = await ajax(`${base}.json`, {
          type: "PUT",
          data: metadata,
        });
      }
      this.savedGuide = response.guide;
      this.formApi.set("source_file", null);
      this.formApi.commit();
      this.notice = i18n("isbf_guides.admin.saved");
      if (isNew) {
        this.router.replaceWith(
          "adminPlugins.show.isbf-guides-guides.edit",
          this.guide.id
        );
      }
    } catch (error) {
      this.error = extractError(error);
    } finally {
      this.busy = false;
    }
  }

  @action
  pickDocument(files) {
    const file = files[0];
    if (file.size > 10 * 1024 * 1024) {
      this.error = i18n("isbf_guides.admin.file_too_large");
      return;
    }
    this.error = null;
    this.notice = null;
    this.formApi.set("source_file", file);
  }

  @action
  async publish() {
    if (this.publicationDisabled) {
      return;
    }
    const confirmed = await this.dialog.confirm({
      message: i18n("isbf_guides.admin.publish_confirm"),
    });
    if (confirmed) {
      await this.#changePublication("publish");
    }
  }

  @action
  async unpublish() {
    if (this.publicationDisabled) {
      return;
    }
    const confirmed = await this.dialog.confirm({
      message: i18n("isbf_guides.admin.unpublish_confirm"),
    });
    if (confirmed) {
      await this.#changePublication("unpublish");
    }
  }

  @action
  async uploadImages(files) {
    if (this.busy || !this.guide) {
      return;
    }
    this.busy = true;
    this.error = null;
    try {
      for (const file of files) {
        const data = new FormData();
        data.append("file", file);
        const response = await ajax(
          `/isbf/guides/admin/guides/${this.guide.id}/images.json`,
          {
            type: "POST",
            data,
            processData: false,
            contentType: false,
          }
        );
        const caption = file.name.replace(/[\[\]\\\r\n]/g, "");
        this.formApi.set(
          "raw",
          `${this.formApi.get("raw")}\n\n![${caption}](${response.image.url})\n`
        );
      }
    } catch (error) {
      this.error = extractError(error);
    } finally {
      this.busy = false;
    }
  }

  async #changePublication(actionName) {
    this.busy = true;
    this.error = null;
    this.notice = null;
    try {
      const response = await ajax(
        `/isbf/guides/admin/guides/${this.guide.id}/${actionName}.json`,
        {
          type: "POST",
          data: { version: this.guide.version },
        }
      );
      this.savedGuide = response.guide;
      this.notice = i18n(
        `isbf_guides.admin.${actionName === "publish" ? "published_notice" : "unpublished_notice"}`
      );
    } catch (error) {
      this.error = extractError(error);
    } finally {
      this.busy = false;
    }
  }

  <template>
    <div class="isbf-guides-editor">
      <a href="/admin/plugins/isbf-guides/guides">{{i18n
          "isbf_guides.admin.back"
        }}</a>
      <DPageSubheader
        @descriptionLabel={{i18n "isbf_guides.admin.description"}}
        @titleLabel={{i18n
          (if this.guide "isbf_guides.admin.edit" "isbf_guides.admin.new")
        }}
      />
      {{#if this.error}}<p
          class="alert alert-error"
          role="alert"
        >{{this.error}}</p>{{/if}}
      {{#if this.notice}}<p
          class="alert alert-success"
          role="status"
        >{{this.notice}}</p>{{/if}}

      {{#each this.forms key="id" as |model|}}
        <Form
          @commitOnSubmit={{false}}
          @data={{model.data}}
          @disabled={{this.busy}}
          @onRegisterApi={{this.registerApi}}
          @onSubmit={{this.save}}
          as |form|
        >
          <form.Field
            @disabled={{this.guide.slug_locked}}
            @name="slug"
            @title={{i18n "isbf_guides.admin.slug"}}
            @type="input"
            @validation="required"
            as |field|
          >
            <field.Control @maxlength={{80}} />
          </form.Field>
          <form.Field
            @name="title"
            @title={{i18n "isbf_guides.admin.guide_title"}}
            @type="input"
            @validation="required"
            as |field|
          >
            <field.Control @maxlength={{200}} />
          </form.Field>
          <form.Field
            @name="summary"
            @title={{i18n "isbf_guides.admin.summary"}}
            @type="textarea"
            as |field|
          >
            <field.Control @maxlength={{1000}} @rows={{3}} />
          </form.Field>
          <form.Field
            @name="source_file"
            @title={{i18n "isbf_guides.admin.document"}}
            @type="custom"
            @validation={{if this.guide "" "required"}}
            as |field|
          >
            <field.Control>
              <DPickFilesButton
                @acceptedFormatsOverride=".html,.htm,.zip"
                @fileInputDisabled={{this.busy}}
                @fileInputId="isbf-guides-document-input"
                @label="isbf_guides.admin.pick_document"
                @onFilesPicked={{this.pickDocument}}
                @showButton={{true}}
              />
              {{#if field.value}}
                <span
                  class="isbf-guides-editor__filename"
                >{{field.value.name}}</span>
              {{/if}}
            </field.Control>
            <p class="isbf-guides-editor__file-help">{{i18n
                "isbf_guides.admin.document_help"
              }}</p>
            <a class="raw-link" href="/isbf/guides/admin/guides/template">{{i18n
                "isbf_guides.admin.download_template"
              }}</a>
            {{#if this.guide}}
              <a class="raw-link" href={{this.sourceUrl}}>{{i18n
                  "isbf_guides.admin.download_source"
                }}</a>
            {{/if}}
          </form.Field>
          {{#if this.isLegacyMarkdown}}
            <form.Field
              @name="raw"
              @title={{i18n "isbf_guides.admin.body"}}
              @type="composer"
              @validation="required"
              as |field|
            >
              <field.Control @preview={{true}} />
            </form.Field>
            <div class="isbf-guides-editor__images">
              {{#if this.guide}}
                <DPickFilesButton
                  @acceptedFormatsOverride=".jpg,.jpeg,.png,.webp,.gif"
                  @allowMultiple={{true}}
                  @fileInputDisabled={{this.busy}}
                  @fileInputId="isbf-guides-image-input"
                  @onFilesPicked={{this.uploadImages}}
                />
                <label for="isbf-guides-image-input">{{i18n
                    "isbf_guides.admin.upload"
                  }}</label>
              {{else}}
                <p>{{i18n "isbf_guides.admin.upload_after_save"}}</p>
              {{/if}}
            </div>
          {{/if}}
          <form.Submit @label="isbf_guides.admin.save_draft" />
        </Form>
      {{/each}}

      {{#if this.guide}}
        <section
          aria-label={{i18n "isbf_guides.admin.publication"}}
          class="isbf-guides-editor__publication"
        >
          <p>{{i18n
              (if
                this.guide.published
                "isbf_guides.admin.published"
                "isbf_guides.admin.draft"
              )
            }}</p>
          {{#if this.guide.has_changes}}<p>{{i18n
                "isbf_guides.admin.pending_changes"
              }}</p>{{/if}}
          {{#if this.formApi.isDirty}}
            <p>{{i18n "isbf_guides.admin.save_first"}}</p>
          {{else}}
            <a
              class="btn btn-default"
              href={{this.previewUrl}}
              rel="noopener noreferrer"
              target="_blank"
            >{{i18n "isbf_guides.admin.preview"}}</a>
          {{/if}}
          <DButton
            @action={{this.publish}}
            @disabled={{this.publicationDisabled}}
            @label="isbf_guides.admin.publish"
          />
          {{#if this.guide.published}}
            <DButton
              @action={{this.unpublish}}
              @disabled={{this.publicationDisabled}}
              @label="isbf_guides.admin.unpublish"
            />
          {{/if}}
        </section>
      {{/if}}
    </div>
  </template>
}
