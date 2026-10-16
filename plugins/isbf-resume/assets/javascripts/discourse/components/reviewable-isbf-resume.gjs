import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ResumeShareEditModal from "./resume-share-edit-modal";
import ResumeShareMetadata from "./resume-share-metadata";
import ResumeSharePreview from "./resume-share-preview";

export default class ReviewableIsbfResume extends Component {
  @service modal;

  @tracked previewOpen = false;

  get share() {
    return {
      ...this.args.reviewable.shared_resume,
      ...this.args.reviewable.payload,
    };
  }

  @action
  editDetails() {
    this.modal.show(ResumeShareEditModal, {
      model: { reviewable: this.args.reviewable },
    });
  }

  @action
  togglePreview(event) {
    this.previewOpen = event.currentTarget.open;
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
      {{#if @reviewable.can_edit_resume}}<p>{{i18n
            "isbf_resume.sharing.native_review_help"
          }}</p>
        <DButton
          class="btn-primary"
          @action={{this.editDetails}}
          @label="isbf_resume.sharing.edit_details"
        />
      {{/if}}
      <DButton
        class="btn-primary"
        data-auto-route="false"
        @href={{getURL this.share.pdf_url}}
        @label="isbf_resume.sharing.download"
      />
      <details {{on "toggle" this.togglePreview}}>
        <summary>{{i18n "isbf_resume.sharing.preview"}}</summary>
        {{#if this.previewOpen}}
          <ResumeSharePreview @urls={{this.share.preview_urls}} />
        {{/if}}
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
