import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { next, schedule } from "@ember/runloop";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import DTabs from "discourse/ui-kit/d-tabs";
import { i18n } from "discourse-i18n";
import {
  emptyResume,
  exportPayload,
  fieldPath,
  newEntry,
} from "../lib/resume-data";
import { RESUME_FIELDS } from "../lib/resume-fields";
import ResumeFields from "./resume-fields";
import ResumeGenerateConfirmation from "./resume-generate-confirmation";
import ResumePreview from "./resume-preview";

export default class ResumeEditor extends Component {
  @service a11y;
  @service modal;

  @tracked activeStage = "content";
  @tracked busy = false;
  @tracked confirming = false;
  @tracked draft = emptyResume();
  @tracked error = null;
  @tracked language = "zh_CN";
  @tracked photoBusy = false;
  @tracked result = null;
  @tracked resultVersion = null;
  @tracked expanded = {};
  initialData = this.draft;
  #form;
  #submissionLanguage = "zh_CN";
  #submissionTrigger;

  get basicFields() {
    return [
      "name",
      "phone",
      "email",
      "job_intent",
      "current_city",
      "preferred_city",
      "highest_education",
      "photo",
    ].map((id) => RESUME_FIELDS.basic.fields.find((field) => field.id === id));
  }

  get extraFields() {
    return RESUME_FIELDS.basic.fields.filter(
      (field) => !this.basicFields.includes(field)
    );
  }

  get sections() {
    return Object.values(RESUME_FIELDS)
      .filter((section) => section.id !== "basic")
      .map((section) => ({
        ...section,
        expanded: this.expanded[section.id],
        entries: Object.keys(this.draft[section.id] || {}).map((id, index) => ({
          id,
          number: index + 1,
        })),
        atLimit:
          Object.keys(this.draft[section.id] || {}).length >=
          section.maxEntries,
      }));
  }

  get payloadVersion() {
    return JSON.stringify(this.previewPayload);
  }

  get previewPayload() {
    return exportPayload(this.draft, this.language);
  }

  get stale() {
    return this.result && this.resultVersion !== this.payloadVersion;
  }

  get unavailable() {
    return !this.result || this.stale || this.busy;
  }

  get disabled() {
    return this.busy || this.photoBusy || this.confirming;
  }

  get showAside() {
    return this.activeStage !== "preview";
  }

  get templateGoldURL() {
    return getURL("/plugins/isbf-resume/images/example-blue-gold.png");
  }

  get templateGrayURL() {
    return getURL("/plugins/isbf-resume/images/example-blue-gray.png");
  }

  @action
  captureSubmissionTrigger(event) {
    const submitter =
      event.submitter ||
      event.target?.closest?.('button[type="submit"]') ||
      (event.type === "submit"
        ? event.currentTarget.querySelector('button[type="submit"]')
        : null);
    if (submitter) {
      const focused = document.activeElement;
      this.#submissionTrigger = focused?.closest(".isbf-resume__form")
        ? focused
        : submitter;
    }
  }

  @action
  registerForm(api) {
    this.#form = api;
  }

  @action
  setStage(stage) {
    this.activeStage = stage;
  }

  @action
  setDraft(name, value, draft) {
    this.draft = { ...draft };
  }

  @action
  setPhotoBusy(busy) {
    if (!this.isDestroying) {
      this.photoBusy = busy;
    }
  }

  @action
  addEntry(section) {
    if (Object.keys(this.draft[section.id] || {}).length < section.maxEntries) {
      this.#form.set(`${section.id}.${newEntry()}`, {});
    }
  }

  @action
  removeEntry(sectionId, entryId) {
    const entries = { ...this.draft[sectionId] };
    delete entries[entryId];
    this.#form.set(sectionId, entries);
  }

  @action
  setExpanded(section, event) {
    const open = event.currentTarget.open;
    if (this.expanded[section] !== open) {
      this.expanded = { ...this.expanded, [section]: open };
    }
  }

  @action
  validate(data, { addError }) {
    const errors = {};
    for (const key of ["name", "phone", "email"]) {
      if (!data.basic?.[key]?.trim()) {
        errors[key] = "isbf_resume.missing";
      }
    }
    const phone = data.basic?.phone?.trim();
    if (phone) {
      const digits = (phone.match(/\d/g) || []).length;
      if (
        !/^\+?[\d ().\t-]+(?:(?:x|ext\.?|分机)[ \t]*\d+)?$/i.test(phone) ||
        digits < 5 ||
        digits > 30
      ) {
        errors.phone = "isbf_resume.phone_invalid";
      }
    }
    const email = data.basic?.email?.trim();
    if (email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      errors.email = "isbf_resume.email_invalid";
    }
    if (Object.keys(errors).length) {
      this.activeStage = "content";
      this.#expandSections();
      for (const [key, message] of Object.entries(errors)) {
        const definition = RESUME_FIELDS.basic.fields.find(
          (field) => field.id === key
        );
        addError(`basic.${key}`, {
          title: i18n(definition.labelKey),
          message: i18n(message),
        });
      }
      this.a11y.announce(i18n("isbf_resume.invalid"), "assertive");
    }
  }

  @action
  async submitEnglish() {
    if (this.disabled) {
      return;
    }
    this.#submissionTrigger = document.activeElement;
    this.#submissionLanguage = "en";
    try {
      await this.#form.submit();
    } finally {
      this.#submissionLanguage = "zh_CN";
    }
  }

  @action
  async generate(data) {
    if (this.disabled) {
      return;
    }
    const language = this.#submissionLanguage;
    const resume = exportPayload(data, language);
    const version = JSON.stringify(resume);
    const trigger = this.#submissionTrigger || document.activeElement;
    this.#submissionTrigger = null;
    this.confirming = true;
    let confirmation;
    try {
      confirmation = await this.modal.show(ResumeGenerateConfirmation, {
        model: { english: language === "en" },
      });
    } finally {
      if (!this.isDestroying) {
        this.confirming = false;
      }
    }
    if (this.isDestroying) {
      return;
    }
    if (!confirmation?.confirmed) {
      this.activeStage = "content";
      // FormKit re-enables submit after this action resolves.
      next(() => {
        if (!this.isDestroying && trigger?.isConnected) {
          trigger.focus();
        }
      });
      return;
    }
    this.language = language;
    this.busy = true;
    this.activeStage = "preview";
    this.error = null;
    this.a11y.announce(i18n("isbf_resume.generating"));
    try {
      const result = await ajax("/isbf-resume/exports.json", {
        type: "POST",
        contentType: "application/json",
        data: JSON.stringify({ resume }),
      });
      if (this.isDestroying) {
        return;
      }
      this.result = result;
      this.resultVersion = version;
      this.activeStage = "preview";
      this.a11y.announce(
        i18n("isbf_resume.generated", { count: result.pages })
      );
    } catch (error) {
      if (this.isDestroying) {
        return;
      }
      const response = error.jqXHR?.responseJSON || {};
      this.error = response.errors?.[0] || i18n("isbf_resume.failed");
      this.activeStage = "content";
      this.#expandSections();
      schedule("afterRender", () => {
        if (!this.isDestroying) {
          for (const [path, message] of Object.entries(
            response.field_errors || {}
          )) {
            this.#form.addError(fieldPath(path, this.draft), {
              title: this.#errorTitle(path),
              message,
            });
          }
        }
      });
      this.a11y.announce(this.error, "assertive");
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }

  #expandSections() {
    this.expanded = Object.fromEntries(
      Object.keys(RESUME_FIELDS).map((id) => [id, true])
    );
  }

  #errorTitle(path) {
    if (path === "template") {
      return i18n("isbf_resume.selection");
    }
    const parts = path.split(".");
    const section = RESUME_FIELDS[parts[0]];
    const field = section?.fields.find(
      (definition) => definition.id === parts.at(-1)
    );
    return i18n(field?.labelKey || section?.labelKey || "isbf_resume.invalid");
  }

  <template>
    <main class="isbf-resume" data-stage={{this.activeStage}}>
      <a class="isbf-resume__back" href={{getURL "/isbf/workbench"}}>{{i18n
          "isbf_resume.back"
        }}</a>
      <h1>{{i18n "isbf_resume.title"}}</h1>
      <p class="isbf-resume__intro">{{i18n "isbf_resume.intro"}}</p>
      <div class="isbf-resume__layout">
        <Form
          class="isbf-resume__form"
          @data={{this.initialData}}
          @onRegisterApi={{this.registerForm}}
          @onSet={{this.setDraft}}
          @onSubmit={{this.generate}}
          @validate={{this.validate}}
          {{on "click" this.captureSubmissionTrigger capture=true}}
          {{on "submit" this.captureSubmissionTrigger capture=true}}
          as |form|
        >
          {{#if this.error}}<p
              class="isbf-resume__error"
            >{{this.error}}</p>{{/if}}
          <DTabs
            class="isbf-resume__stages"
            @active={{this.activeStage}}
            @label={{i18n "isbf_resume.stages"}}
            @onActivate={{this.setStage}}
            as |tabs|
          >
            <tabs.Tab @key="content" @label={{i18n "isbf_resume.content"}}>
              <section class="isbf-resume__section">
                <h2>{{i18n "isbf_resume.basic"}}</h2>
                <p>{{i18n "isbf_resume.sections.basic.description"}}</p>
                <form.Object @name="basic" as |basic|>
                  <ResumeFields
                    @disabled={{this.busy}}
                    @fields={{this.basicFields}}
                    @onPhotoBusy={{this.setPhotoBusy}}
                    @scope={{basic}}
                  />
                  <details
                    class="isbf-resume__details"
                    open={{this.expanded.basic}}
                    {{on "toggle" (fn this.setExpanded "basic")}}
                  >
                    <summary>{{i18n "isbf_resume.more"}}</summary>
                    <ResumeFields
                      @disabled={{this.busy}}
                      @fields={{this.extraFields}}
                      @scope={{basic}}
                    />
                  </details>
                </form.Object>
              </section>
              <h2>{{i18n "isbf_resume.modules"}}</h2>
              <p>{{i18n "isbf_resume.skipped"}}</p>
              {{#each this.sections key="id" as |moduleDefinition|}}
                <details
                  class="isbf-resume__details"
                  open={{moduleDefinition.expanded}}
                  {{on "toggle" (fn this.setExpanded moduleDefinition.id)}}
                >
                  <summary>{{i18n moduleDefinition.labelKey}}</summary>
                  <p>{{i18n moduleDefinition.descriptionKey}}</p>
                  <form.Object @name={{moduleDefinition.id}} as |group|>
                    {{#if moduleDefinition.repeatable}}
                      {{#each moduleDefinition.entries key="id" as |entry|}}
                        <section class="isbf-resume__entry">
                          <h3>{{i18n
                              "isbf_resume.entry"
                              count=entry.number
                            }}</h3>
                          <group.Object @name={{entry.id}} as |object|>
                            <ResumeFields
                              @disabled={{this.busy}}
                              @fields={{moduleDefinition.fields}}
                              @scope={{object}}
                            />
                          </group.Object>
                          <DButton
                            @action={{fn
                              this.removeEntry
                              moduleDefinition.id
                              entry.id
                            }}
                            @disabled={{this.busy}}
                            @label="isbf_resume.remove"
                          />
                        </section>
                      {{/each}}
                      <DButton
                        @action={{fn this.addEntry moduleDefinition}}
                        @disabled={{if this.busy true moduleDefinition.atLimit}}
                        @icon="plus"
                        @label="isbf_resume.add"
                      />
                      {{#if moduleDefinition.atLimit}}<p>{{i18n
                            "isbf_resume.limit"
                            count=moduleDefinition.maxEntries
                          }}</p>{{/if}}
                    {{else}}
                      <ResumeFields
                        @disabled={{this.busy}}
                        @fields={{moduleDefinition.fields}}
                        @scope={{group}}
                      />
                    {{/if}}
                  </form.Object>
                </details>
              {{/each}}
              <DButton
                @action={{fn this.setStage "templates"}}
                @label="isbf_resume.next_template"
              />
            </tabs.Tab>
            <tabs.Tab @key="templates" @label={{i18n "isbf_resume.templates"}}>
              <section class="isbf-resume__section">
                <h2>{{i18n "isbf_resume.templates"}}</h2>
                <form.Field
                  @format="full"
                  @helpText={{i18n "isbf_resume.template_help"}}
                  @name="template"
                  @title={{i18n "isbf_resume.selection"}}
                  @type="radio-group"
                  as |field|
                >
                  <field.Control as |group|>
                    <group.Radio @value="blue-gold" as |radio|>
                      <radio.Title>{{i18n
                          "isbf_resume.blue_gold"
                        }}</radio.Title>
                      <radio.Description><img
                          alt={{i18n "isbf_resume.blue_gold"}}
                          src={{this.templateGoldURL}}
                        /></radio.Description>
                    </group.Radio>
                    <group.Radio @value="blue-gray" as |radio|>
                      <radio.Title>{{i18n
                          "isbf_resume.blue_gray"
                        }}</radio.Title>
                      <radio.Description><img
                          alt={{i18n "isbf_resume.blue_gray"}}
                          src={{this.templateGrayURL}}
                        /></radio.Description>
                    </group.Radio>
                  </field.Control>
                </form.Field>
              </section>
              <DButton
                @action={{fn this.setStage "preview"}}
                @label="isbf_resume.next_preview"
              />
            </tabs.Tab>
            <tabs.Tab @key="preview" @label={{i18n "isbf_resume.preview"}}>
              <p class="isbf-resume__notice isbf-resume__page-advice">{{i18n
                  "isbf_resume.page_advice"
                }}</p>
              <ResumePreview
                @busy={{this.busy}}
                @payload={{this.previewPayload}}
                @result={{this.result}}
                @stale={{this.stale}}
                @template={{this.draft.template}}
                @unavailable={{this.unavailable}}
              />
            </tabs.Tab>
          </DTabs>
          <form.Actions>
            <form.Submit
              @disabled={{this.disabled}}
              @label={{if
                this.busy
                "isbf_resume.generating"
                "isbf_resume.generate"
              }}
            />
            <DButton
              class="btn-default isbf-resume__generate-english"
              @action={{this.submitEnglish}}
              @disabled={{this.disabled}}
              @label="isbf_resume.generate_english"
            />
            {{#if this.stale}}<p>{{i18n "isbf_resume.stale"}}</p>{{/if}}
          </form.Actions>
        </Form>
        {{#if this.showAside}}
          <aside class="isbf-resume__aside">
            <ResumePreview
              @busy={{this.busy}}
              @payload={{this.previewPayload}}
              @result={{this.result}}
              @stale={{this.stale}}
              @template={{this.draft.template}}
              @unavailable={{this.unavailable}}
            />
          </aside>
        {{/if}}
      </div>
    </main>
  </template>
}
