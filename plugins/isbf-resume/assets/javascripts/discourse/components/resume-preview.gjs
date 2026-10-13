import Component from "@glimmer/component";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ResumeDraftPaper from "./resume-draft-paper";

export default class ResumePreview extends Component {
  get isUnavailable() {
    return Boolean(
      this.args.busy ||
      this.args.stale ||
      this.args.unavailable ||
      !this.args.result
    );
  }

  get pdfURL() {
    return this.isUnavailable ? null : `${this.args.result.pdf_url}?inline=1`;
  }

  get previewPages() {
    if (this.isUnavailable) {
      return [];
    }

    return (this.args.result.preview_urls || []).map((url, index) => ({
      number: index + 1,
      url,
    }));
  }

  <template>
    <section
      aria-busy={{if @busy "true" "false"}}
      aria-label={{i18n "isbf_resume.preview"}}
      class="isbf-resume-preview isbf-resume__preview"
    >
      <h2>{{i18n "isbf_resume.preview"}}</h2>
      {{#if @busy}}
        <p class="isbf-resume__notice">{{i18n
            "isbf_resume.generating_preview"
          }}</p>
      {{else if this.isUnavailable}}
        {{#if @stale}}
          <p class="isbf-resume__notice">{{i18n "isbf_resume.stale"}}</p>
        {{/if}}
        <p>{{i18n "isbf_resume.draft_preview_note"}}</p>
        <ResumeDraftPaper @payload={{@payload}} />
      {{else}}
        <p class={{if @stale "isbf-resume__notice"}}>
          {{#if @stale}}{{i18n "isbf_resume.stale"}}{{else}}{{i18n
              "isbf_resume.generated"
              count=@result.pages
            }}{{/if}}
        </p>
        {{#unless this.isUnavailable}}
          {{#if this.previewPages.length}}
            <div class="isbf-resume__pages">
              {{#each this.previewPages key="url" as |page|}}
                <img
                  alt={{i18n
                    "isbf_resume.preview_page"
                    count=@result.pages
                    page=page.number
                  }}
                  class="isbf-resume__paper"
                  src={{page.url}}
                />
              {{/each}}
            </div>
          {{else}}
            <p>{{i18n "isbf_resume.preview_unavailable"}}</p>
          {{/if}}
        {{/unless}}
      {{/if}}
      <div class="isbf-resume__downloads">
        <DButton
          download=""
          rel="noopener noreferrer"
          target="_blank"
          @disabled={{this.isUnavailable}}
          @href={{unless this.isUnavailable @result.docx_url}}
          @icon="file-arrow-down"
          @label="isbf_resume.download_docx"
        />
        <DButton
          download=""
          rel="noopener noreferrer"
          target="_blank"
          @disabled={{this.isUnavailable}}
          @href={{unless this.isUnavailable @result.pdf_url}}
          @icon="file-arrow-down"
          @label="isbf_resume.download_pdf"
        />
        {{#unless this.isUnavailable}}<a
            href={{this.pdfURL}}
            rel="noopener noreferrer"
            target="_blank"
          >{{i18n "isbf_resume.open_pdf"}}</a>{{/unless}}
      </div>
      <p>{{i18n "isbf_resume.expiry"}}</p>
    </section>
  </template>
}
