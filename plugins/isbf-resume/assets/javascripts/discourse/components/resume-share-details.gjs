import Component from "@glimmer/component";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ResumeShareContributor from "./resume-share-contributor";
import ResumeShareMetadata from "./resume-share-metadata";
import ResumeSharePreview from "./resume-share-preview";
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

  <template>
    <main class="isbf-resume isbf-resume-share-details" ...attributes>
      <ResumeSharingHeader
        @backHref="/isbf/workbench/resume/shares"
        @title={{this.share.title}}
      >
        {{#if this.share.pdf_url}}
          <DButton
            class="btn-primary"
            data-auto-route="false"
            rel="noopener noreferrer"
            target="_blank"
            @href={{getURL this.share.pdf_url}}
            @label="isbf_resume.sharing.download"
          />
        {{/if}}
      </ResumeSharingHeader>
      {{#if this.statusLabel}}<p
          class="isbf-resume-share-details__status"
        >{{this.statusLabel}}</p>{{/if}}
      {{#if this.description}}<p
          class="isbf-resume-share-details__description"
        >{{this.description}}</p>{{/if}}
      <ResumeShareMetadata @share={{this.share}} />
      <ResumeShareContributor @share={{this.share}} />
      <section class="isbf-resume-share-details__preview isbf-resume__preview">
        <h2>{{i18n "isbf_resume.sharing.preview"}}</h2>
        <ResumeSharePreview @urls={{this.share.preview_urls}} />
      </section>
    </main>
  </template>
}
