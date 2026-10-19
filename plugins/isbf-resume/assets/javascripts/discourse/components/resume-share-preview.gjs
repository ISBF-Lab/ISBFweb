import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ResumeSharePreview extends Component {
  @service a11y;

  @tracked page = 1;
  @tracked _attempt = 0;
  @tracked _result;

  get count() {
    return Math.min(this.args.urls?.length || 0, 3);
  }

  get pageNumber() {
    return Math.min(this.page, this.count || 1);
  }

  get currentUrl() {
    const url = this.args.urls?.[this.pageNumber - 1];
    if (!url) {
      return null;
    }
    return `${getURL(url)}${this._attempt ? `?retry=${this._attempt}` : ""}`;
  }

  get images() {
    return this.currentUrl
      ? [
          {
            url: this.currentUrl,
            alt: i18n("isbf_resume.sharing.preview_page", {
              page: this.pageNumber,
            }),
          },
        ]
      : [];
  }

  get failed() {
    return this._result?.url === this.currentUrl && this._result.failed;
  }

  get loading() {
    return this.count > 0 && this._result?.url !== this.currentUrl;
  }

  get previousDisabled() {
    return this.loading || this.pageNumber <= 1;
  }

  get nextDisabled() {
    return this.loading || this.pageNumber >= this.count;
  }

  get pageLabel() {
    return i18n("isbf_resume.sharing.page_count", {
      page: this.pageNumber,
      count: this.count,
    });
  }

  @action
  previous() {
    this.page = Math.max(1, this.pageNumber - 1);
  }

  @action
  next() {
    this.page = Math.min(this.count, this.pageNumber + 1);
  }

  @action
  retry() {
    this._attempt++;
  }

  @action
  loaded(event) {
    const url = event.target.getAttribute("src");
    if (url === this.currentUrl) {
      this._result = { url, failed: false };
      this.a11y.announce(this.pageLabel);
    }
  }

  @action
  failedToLoad(event) {
    const url = event.target.getAttribute("src");
    if (url === this.currentUrl) {
      this._result = { url, failed: true };
      this.a11y.announce(
        i18n("isbf_resume.sharing.preview_failed"),
        "assertive"
      );
    }
  }

  <template>
    <div
      class="isbf-resume-share-preview"
      ...attributes
      aria-busy={{this.loading}}
    >
      <p class="isbf-resume-share-preview__notice">{{i18n
          "isbf_resume.sharing.preview_notice"
        }}</p>
      {{#if this.count}}
        <div class="isbf-resume-share-preview__controls">
          <DButton
            class="btn-primary"
            @action={{this.previous}}
            @disabled={{this.previousDisabled}}
            @label="isbf_resume.sharing.previous_page"
          />
          <span>{{this.pageLabel}}</span>
          <DButton
            class="btn-primary"
            @action={{this.next}}
            @disabled={{this.nextDisabled}}
            @label="isbf_resume.sharing.next_page"
          />
        </div>
        {{#if this.loading}}<p>{{i18n
              "isbf_resume.sharing.preview_loading"
            }}</p>{{/if}}
        {{#if this.failed}}
          <p>{{i18n "isbf_resume.sharing.preview_failed"}}</p>
          <DButton
            class="btn-primary"
            @action={{this.retry}}
            @label="isbf_resume.sharing.retry_preview"
          />
        {{/if}}
        {{#unless this.failed}}
          {{#each this.images key="url" as |image|}}
            <img
              alt={{image.alt}}
              class="isbf-resume__paper"
              loading="lazy"
              src={{image.url}}
              {{on "load" this.loaded}}
              {{on "error" this.failedToLoad}}
            />
          {{/each}}
        {{/unless}}
      {{/if}}
    </div>
  </template>
}
