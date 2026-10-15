import Component from "@glimmer/component";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import { RESUME_FIELDS } from "../lib/resume-fields";

const FULL_WIDTH_BASIC = ["highest_education", "portfolio_links", "linkedin"];
const RECORD_FIELDS = {
  education: {
    title: "school",
    role: ["major", "degree"],
    leads: ["courses"],
    bullets: "achievements",
  },
  experience: {
    title: "company",
    role: ["position"],
    leads: ["department"],
    bullets: "details",
  },
  projects: {
    title: "name",
    role: ["role"],
    leads: ["technology", "link"],
    bullets: "details",
  },
  activities: { title: "name", role: ["role"], leads: [], bullets: "details" },
  skills: {
    title: "name",
    role: ["level"],
    leads: ["issuer"],
    bullets: "description",
  },
  honors: {
    title: "name",
    role: [],
    leads: ["issuer"],
    bullets: "description",
  },
};

function text(value) {
  return typeof value === "string" ? value.replaceAll("\r\n", "\n").trim() : "";
}

export default class ResumeDraftPaper extends Component {
  get language() {
    return this.args.payload?.language === "en" ? "en" : "zh";
  }

  get basicFields() {
    const basic = this.args.payload?.basic || {};
    return RESUME_FIELDS.basic.fields
      .filter((field) => !field.photo && !FULL_WIDTH_BASIC.includes(field.id))
      .map((field) => ({
        id: field.id,
        label: this.#label(`fields.${field.id}`),
        value: text(basic[field.id]),
      }))
      .filter((field) => field.value);
  }

  get basicParagraphs() {
    const basic = this.args.payload?.basic || {};
    return FULL_WIDTH_BASIC.map((id) => ({
      id,
      label: this.#label(`fields.${id}`),
      value: text(basic[id]),
    })).filter((field) => field.value);
  }

  get photo() {
    const value = this.args.payload?.basic?.photo;
    return /^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=\r\n]+$/.test(
      value || ""
    )
      ? value
      : null;
  }

  get sections() {
    return Object.values(RESUME_FIELDS)
      .filter((section) => section.id !== "basic")
      .map((section) => {
        const values = this.args.payload?.[section.id];
        const summary = section.id === "summary" ? text(values?.text) : "";
        const entries =
          section.repeatable && Array.isArray(values)
            ? values
                .filter((entry) =>
                  section.fields.some(
                    (field) =>
                      field.type !== "checkbox" && text(entry?.[field.id])
                  )
                )
                .map((entry) => this.#record(section.id, entry))
            : [];
        return {
          id: section.id,
          label: this.#label(`sections.${section.id}`),
          summary,
          entries,
        };
      })
      .filter((section) => section.summary || section.entries.length);
  }

  get hasBasic() {
    return this.basicFields.length || this.basicParagraphs.length || this.photo;
  }

  get hasBasicGrid() {
    return this.basicFields.length || this.photo;
  }

  get documentLanguage() {
    return this.language === "en" ? "en" : "zh-CN";
  }

  get hasContent() {
    return this.hasBasic || this.sections.length;
  }

  get title() {
    return this.#label("title");
  }

  get basicLabel() {
    return this.#label("sections.basic");
  }

  get separator() {
    return this.language === "en" ? ": " : "：";
  }

  #label(key) {
    return i18n(`isbf_resume.paper.${this.language}.${key}`);
  }

  #dates(section, entry) {
    if (entry.date) {
      return text(entry.date).replaceAll("-", ".");
    }
    const start = text(entry.start_month).replaceAll("-", ".");
    let end = text(entry.end_month).replaceAll("-", ".");
    if (entry.ongoing === true) {
      end =
        section === "education" && end
          ? `${end}${this.#label("expected")}`
          : this.#label("present");
    }
    return start && end ? `${start} - ${end}` : start || end;
  }

  #record(section, entry) {
    const fields = RECORD_FIELDS[section];
    return {
      date: this.#dates(section, entry),
      title: text(entry[fields.title]),
      role: fields.role
        .map((id) => text(entry[id]))
        .filter(Boolean)
        .join(" · "),
      paragraphs: fields.leads
        .map((id) => ({
          id,
          label: this.#label(`leads.${id}`),
          value: text(entry[id]),
        }))
        .filter((paragraph) => paragraph.value),
      bullets: text(entry[fields.bullets])
        .split("\n")
        .filter((line) => line.trim()),
    };
  }

  <template>
    {{#if this.hasContent}}
      <div class="isbf-resume-draft-frame">
        <article
          aria-label={{i18n "isbf_resume.draft_preview"}}
          class="isbf-resume-draft"
          data-template={{@payload.template}}
          lang={{this.documentLanguage}}
          ...attributes
        >
          <header class="isbf-resume-draft__title">
            <h3>{{this.title}}</h3>
            <span>{{i18n "isbf_resume.paper.subtitle"}}</span>
          </header>
          {{#if this.hasBasic}}
            <section class="isbf-resume-draft__section">
              <h4 class="isbf-resume-draft__heading">{{this.basicLabel}}</h4>
              {{#if this.hasBasicGrid}}<div class="isbf-resume-draft__basic">
                  {{#if this.basicFields.length}}
                    <div class="isbf-resume-draft__fields">
                      {{#each this.basicFields key="id" as |field|}}
                        <p class="isbf-resume-draft__text"><span
                            class="isbf-resume-draft__label"
                          >{{field.label}}{{this.separator}}</span>{{field.value}}</p>
                      {{/each}}
                    </div>
                  {{/if}}
                  {{#if this.photo}}
                    <img
                      alt={{i18n "isbf_resume.fields.basic.photo.label"}}
                      class="isbf-resume-draft__photo"
                      src={{this.photo}}
                    />
                  {{/if}}
                </div>{{/if}}
              {{#each this.basicParagraphs key="id" as |field|}}
                <p class="isbf-resume-draft__text"><strong
                  >{{field.label}}{{this.separator}}</strong>{{field.value}}</p>
              {{/each}}
            </section>
          {{/if}}
          {{#each this.sections key="id" as |resumeSection|}}
            <section
              class="isbf-resume-draft__section"
              data-section={{resumeSection.id}}
            >
              <h4
                class="isbf-resume-draft__heading"
              >{{resumeSection.label}}</h4>
              {{#if resumeSection.summary}}<p
                  class="isbf-resume-draft__text"
                >{{resumeSection.summary}}</p>{{/if}}
              {{#each resumeSection.entries as |entry|}}
                <div class="isbf-resume-draft__entry">
                  <div
                    class={{dConcatClass
                      "isbf-resume-draft__record"
                      (if entry.date "has-date")
                    }}
                  >
                    {{#if entry.date}}<span>{{entry.date}}</span>{{/if}}
                    <strong>{{entry.title}}</strong>
                    <span class="isbf-resume-draft__role">{{entry.role}}</span>
                  </div>
                  {{#each entry.paragraphs key="id" as |paragraph|}}
                    <p class="isbf-resume-draft__text"><strong
                      >{{paragraph.label}}</strong>{{paragraph.value}}</p>
                  {{/each}}
                  {{#if entry.bullets.length}}
                    <ul class="isbf-resume-draft__bullets">
                      {{#each entry.bullets as |line|}}<li
                        >{{line}}</li>{{/each}}
                    </ul>
                  {{/if}}
                </div>
              {{/each}}
            </section>
          {{/each}}
        </article>
      </div>
    {{else}}
      <p class="isbf-resume-draft__empty">{{i18n
          "isbf_resume.empty_draft_preview"
        }}</p>
    {{/if}}
  </template>
}
