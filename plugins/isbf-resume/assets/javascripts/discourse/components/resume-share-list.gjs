import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import getURL from "discourse/lib/get-url";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import ResumeShareMetadata from "./resume-share-metadata";
import ResumeSharingHeader from "./resume-sharing-header";

export default class ResumeShareList extends Component {
  @service a11y;

  @tracked busy = false;
  @tracked error;
  @tracked response;
  @tracked extraShares = [];
  @tracked page = 1;

  get model() {
    return this.response || this.args.model;
  }

  get shares() {
    return [...this.model.shares, ...this.extraShares].map((share) => ({
      ...share,
      href: getURL(`/isbf/workbench/resume/shares/${share.id}`),
      summary: share.description || share.submitted_description,
      statusLabel:
        share.status && this.args.list !== "published"
          ? i18n(`isbf_resume.sharing.statuses.${share.status}`)
          : null,
    }));
  }

  get title() {
    return i18n(
      `isbf_resume.sharing.${this.args.list === "published" ? "title" : this.args.list}`
    );
  }

  get canLoadMore() {
    return this.model.can_load_more;
  }

  @action
  async loadMore() {
    await this.#load(this.page + 1);
  }

  async #load(page) {
    this.busy = true;
    this.error = null;
    try {
      const response = await ajax("/isbf-resume/shares.json", {
        data: { page, list: this.args.list },
      });
      if (this.isDestroying) {
        return;
      }
      this.extraShares =
        page === 1 ? [] : [...this.extraShares, ...response.shares];
      this.response =
        page === 1
          ? response
          : { ...this.model, can_load_more: response.can_load_more };
      this.page = page;
      this.a11y.announce(i18n("isbf_resume.sharing.loaded"));
    } catch (error) {
      if (!this.isDestroying) {
        this.error = extractError(error);
        this.a11y.announce(this.error, "assertive");
      }
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }

  <template>
    <main
      aria-busy={{this.busy}}
      class="isbf-resume isbf-resume-share-list"
      ...attributes
    >
      <ResumeSharingHeader @title={{this.title}}>
        <div class="isbf-resume-share-list__actions">
          {{#if (eq @list "published")}}<DButton
              class="btn-primary isbf-resume-share-list__mine"
              @href={{getURL "/isbf/workbench/resume/shares/mine"}}
              @label="isbf_resume.sharing.mine"
            />{{/if}}
          {{#if this.model.can_submit}}<DButton
              class="btn-primary isbf-resume-share-list__upload"
              @href={{getURL "/isbf/workbench/resume/shares/new"}}
              @label="isbf_resume.sharing.upload"
            />{{/if}}
        </div>
      </ResumeSharingHeader>
      {{#if this.error}}<p
          class="isbf-resume__error"
          role="alert"
        >{{this.error}}</p>{{/if}}
      <ul class="isbf-resume-share-list__files">
        {{#each this.shares key="id" as |share|}}
          <li class="isbf-resume-share-list__file">
            <span
              aria-hidden="true"
              class="isbf-resume-share-list__icon"
            >{{dIcon "file-lines"}}</span>
            <div class="isbf-resume-share-list__content">
              <h2><a href={{share.href}}>{{share.title}}</a></h2>
              {{#if share.summary}}<p
                  class="isbf-resume-share-list__description"
                >{{share.summary}}</p>{{/if}}
              <ResumeShareMetadata @share={{share}} />
              {{#if share.statusLabel}}<p
                  class="isbf-resume-share-list__status"
                >{{share.statusLabel}}</p>{{/if}}
              <a class="isbf-resume-share-list__open" href={{share.href}}>{{i18n
                  "isbf_resume.sharing.open"
                }}</a>
            </div>
          </li>
        {{else}}<li class="isbf-resume-share-list__empty">{{i18n
              "isbf_resume.sharing.empty"
            }}</li>{{/each}}
      </ul>
      {{#if this.canLoadMore}}<DButton
          class="btn-default"
          @action={{this.loadMore}}
          @disabled={{this.busy}}
          @label="isbf_resume.sharing.load_more"
        />{{/if}}
    </main>
  </template>
}
