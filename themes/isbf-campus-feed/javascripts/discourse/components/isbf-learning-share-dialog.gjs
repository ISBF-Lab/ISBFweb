import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFLearningShareDialog extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;

  @tracked contributor = null;
  @tracked description = "";
  @tracked error = null;
  @tracked link = "";
  @tracked saving = false;
  @tracked title = "";

  #closed = false;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get contributorEnabled() {
    return this.site?.isbf_learning?.resource_contributor === true;
  }

  get contributorValue() {
    return (
      this.contributor ??
      (this.currentUser?.name || this.currentUser?.username || "")
    );
  }

  get shareLabel() {
    return i18n(
      themePrefix(
        this.site?.isbf_learning?.resource_admin_management === true &&
          !(
            this.currentUser?.admin ||
            this.currentUser?.academy_moderator_permissions?.manage_resources
          )
          ? "isbf_v2.learning_apply_share"
          : "isbf_v2.learning_share"
      )
    );
  }

  get submitLabel() {
    return this.site?.isbf_learning?.resource_admin_management === true &&
      !(
        this.currentUser?.admin ||
        this.currentUser?.academy_moderator_permissions?.manage_resources
      )
      ? i18n(themePrefix("isbf_v2.learning_submit_request"))
      : this.shareLabel;
  }

  get descriptionEnabled() {
    return this.site?.isbf_learning?.resource_description === true;
  }

  get minimumTitleLength() {
    return this.siteSettings.min_topic_title_length;
  }

  get maximumTitleLength() {
    return this.siteSettings.max_topic_title_length;
  }

  get saveDisabled() {
    const length = [...this.title.trim()].length;
    return (
      this.saving ||
      !this.args.course?.id ||
      length < this.minimumTitleLength ||
      length > this.maximumTitleLength ||
      !this.validLink ||
      (this.descriptionEnabled && [...this.description].length > 300) ||
      (this.contributorEnabled &&
        this.contributor !== null &&
        [...this.contributor.trim()].length > 15)
    );
  }

  get validLink() {
    const value = this.link.trim();
    if (
      value.length > 2048 ||
      !/^https?:\/\//i.test(value) ||
      /[\\\u0000-\u0020]/.test(value)
    ) {
      return false;
    }
    try {
      const url = new URL(value);
      return Boolean(url.hostname && !url.username && !url.password);
    } catch {
      return false;
    }
  }

  @action
  changeContributor(event) {
    this.contributor = event.target.value;
  }

  @action
  changeDescription(event) {
    this.description = event.target.value;
  }

  @action
  changeLink(event) {
    this.link = event.target.value;
  }

  @action
  changeTitle(event) {
    this.title = event.target.value;
  }

  @action
  close() {
    this.#closed = true;
    this.args.onClose();
  }

  @action
  focusTitle(element) {
    element.focus();
  }

  @action
  async save(event) {
    event.preventDefault();
    if (this.#closed || this.saveDisabled) {
      return;
    }
    this.error = null;
    this.saving = true;
    try {
      const response = await ajax("/isbf/learning/resources", {
        type: "POST",
        data: {
          course_id: this.args.course.id,
          title: this.title.trim(),
          link: this.link.trim(),
          ...(this.descriptionEnabled ? { description: this.description } : {}),
          ...(this.contributorEnabled
            ? { contributor: this.contributor?.trim() || "" }
            : {}),
        },
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (response?.success !== true || typeof response.pending !== "boolean") {
        throw new Error("Unexpected learning resource response");
      }
      this.#closed = true;
      this.args.onSubmitted(response);
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.error =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          i18n(themePrefix("isbf_v2.learning_share_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.saving = false;
      }
    }
  }

  <template>
    <DModal
      class="isbf-learning-share-dialog"
      @closeModal={{this.close}}
      @submitOnEnter={{false}}
      @title={{this.shareLabel}}
    >
      <:body>
        <p class="isbf-learning-share-dialog__course">{{@course.name}}</p>
        <form {{on "submit" this.save}}>
          <label>
            <span>{{i18n
                (themePrefix "isbf_v2.learning_resource_title")
              }}</span>
            <input
              disabled={{this.saving}}
              maxlength={{this.maximumTitleLength}}
              minlength={{this.minimumTitleLength}}
              required
              type="text"
              value={{this.title}}
              {{on "input" this.changeTitle}}
              {{didInsert this.focusTitle}}
            />
          </label>
          {{#if this.descriptionEnabled}}
            <label>
              <span>{{i18n
                  (themePrefix "isbf_v2.learning_resource_description")
                }}</span>
              <textarea
                disabled={{this.saving}}
                rows="3"
                value={{this.description}}
                {{on "input" this.changeDescription}}
              ></textarea>
              <span>{{i18n
                  (themePrefix "isbf_v2.learning_description_hint")
                }}</span>
            </label>
          {{/if}}
          <label>
            <span>{{i18n (themePrefix "isbf_v2.learning_resource_link")}}</span>
            <input
              disabled={{this.saving}}
              maxlength="2048"
              placeholder="https://"
              required
              type="url"
              value={{this.link}}
              {{on "input" this.changeLink}}
            />
          </label>
          {{#if this.contributorEnabled}}
            <label>
              <span>{{i18n
                  (themePrefix "isbf_v2.learning_resource_contributor")
                }}</span>
              <input
                disabled={{this.saving}}
                type="text"
                value={{this.contributorValue}}
                {{on "input" this.changeContributor}}
              />
              <span>{{i18n
                  (themePrefix "isbf_v2.learning_contributor_hint")
                }}</span>
            </label>
          {{/if}}
          {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
          <div class="isbf-learning-share-dialog__actions">
            <DButton
              @action={{this.close}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
            />
            <DButton
              class="btn-primary"
              @disabled={{this.saveDisabled}}
              @translatedLabel={{this.submitLabel}}
              @type="submit"
            />
          </div>
        </form>
      </:body>
    </DModal>
  </template>
}
