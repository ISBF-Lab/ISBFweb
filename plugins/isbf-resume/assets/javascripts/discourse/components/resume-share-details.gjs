import Component from "@glimmer/component";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ResumeShareMetadata from "./resume-share-metadata";
import ResumeSharingHeader from "./resume-sharing-header";

export default class ResumeShareDetails extends Component {
  get share() {
    return this.args.share;
  }

  get description() {
    return this.share.description || this.share.submitted_description;
  }

  get statusLabel() {
    return this.share.status !== "approved"
      ? i18n(`isbf_resume.sharing.statuses.${this.share.status}`)
      : null;
  }

  get pages() {
    return this.share.preview_urls.map((url, index) => ({
      url: getURL(url),
      alt: i18n("isbf_resume.sharing.preview_page", { page: index + 1 }),
    }));
  }

  <template>
    <main class="isbf-resume isbf-resume-share-details" ...attributes>
      <ResumeSharingHeader
        @backHref="/isbf/workbench/resume/shares"
        @title={{this.share.title}}
      >
        <DButton
          class="btn-primary"
          data-auto-route="false"
          @href={{getURL this.share.pdf_url}}
          @label="isbf_resume.sharing.download"
        />
      </ResumeSharingHeader>
      {{#if this.statusLabel}}<p
          class="isbf-resume-share-details__status"
        >{{this.statusLabel}}</p>{{/if}}
      {{#if this.description}}<p
          class="isbf-resume-share-details__description"
        >{{this.description}}</p>{{/if}}
      <ResumeShareMetadata @share={{this.share}} />
      <section class="isbf-resume-share-details__preview isbf-resume__preview">
        <h2>{{i18n "isbf_resume.sharing.preview"}}</h2>
        <div class="isbf-resume__pages">
          {{#each this.pages key="url" as |page|}}<img
              alt={{page.alt}}
              class="isbf-resume__paper"
              loading="lazy"
              src={{page.url}}
            />{{/each}}
        </div>
      </section>
    </main>
  </template>
}
