import Component from "@glimmer/component";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ResumeShareMetadata from "./resume-share-metadata";

export default class ReviewableIsbfResume extends Component {
  get share() {
    return this.args.reviewable.shared_resume;
  }

  get pages() {
    return this.share.preview_urls.map((url, index) => ({
      url: getURL(url),
      alt: i18n("isbf_resume.sharing.preview_page", { page: index + 1 }),
    }));
  }

  <template>
    <section class="isbf-resume-review" ...attributes>
      <h3>{{this.share.title}}</h3>
      <ResumeShareMetadata @share={{this.share}} />
      <h4>{{i18n "isbf_resume.sharing.original_description"}}</h4>
      <p
        class="isbf-resume-review__description"
      >{{this.share.submitted_description}}</p>
      <h4>{{i18n "isbf_resume.sharing.review_description"}}</h4>
      <p
        class="isbf-resume-review__description"
      >{{@reviewable.payload.description}}</p>
      {{#if @reviewable.can_edit}}<p>{{i18n
            "isbf_resume.sharing.native_review_help"
          }}</p>{{/if}}
      <DButton
        class="btn-primary"
        data-auto-route="false"
        @href={{getURL this.share.pdf_url}}
        @label="isbf_resume.sharing.download"
      />
      <details>
        <summary>{{i18n "isbf_resume.sharing.preview"}}</summary>
        {{#each this.pages key="url" as |page|}}<img
            alt={{page.alt}}
            class="isbf-resume-review__preview"
            loading="lazy"
            src={{page.url}}
          />{{/each}}
      </details>
      {{#if this.share.reviews.length}}
        <h4>{{i18n "isbf_resume.sharing.history"}}</h4>
        {{#each this.share.reviews key="id" as |review|}}
          <p>{{i18n
              "isbf_resume.sharing.review_by"
              name=review.reviewer_name
              username=review.reviewer_username
            }}
            ·
            <time
              datetime={{review.created_at}}
            >{{review.created_at}}</time></p>
          <p
            class="isbf-resume-review__description"
          >{{review.original_description}}</p>
          <p class="isbf-resume-review__description">{{review.description}}</p>
        {{/each}}
      {{/if}}
    </section>
  </template>
}
