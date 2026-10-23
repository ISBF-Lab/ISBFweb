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
import {
  learningEditableResource,
  learningEditDetails,
  learningLinkBody,
} from "../lib/learning-resources";

export default class ISBFResourceShareDialog extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;

  @tracked contributor = null;
  @tracked description = "";
  @tracked error = null;
  @tracked editReady = false;
  @tracked loadError = null;
  @tracked loading = false;
  @tracked link = "";
  @tracked saving = false;
  @tracked title = "";

  #closed = false;
  #loadGeneration = 0;
  #original = null;

  constructor() {
    super(...arguments);
    if (this.isEditing) {
      this.retryLoad();
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get config() {
    return this.args.library
      ? this.site?.isbf_library
      : this.site?.isbf_learning;
  }

  get fieldPrefix() {
    return this.args.library ? "isbf_library" : "isbf_learning";
  }

  get isEditing() {
    return Boolean(this.args.resource);
  }

  get editAllowed() {
    return (
      this.canManageResources &&
      this.config?.resource_admin_management === true &&
      learningEditableResource(this.args.resource)
    );
  }

  get fieldsDisabled() {
    return this.saving || (this.isEditing && !this.editReady);
  }

  get contributorEnabled() {
    return this.config?.resource_contributor === true;
  }

  get contributorHint() {
    return i18n(
      themePrefix(
        this.isEditing
          ? "isbf_v2.learning_edit_contributor_hint"
          : "isbf_v2.learning_contributor_hint"
      )
    );
  }

  get contributorValue() {
    return (
      this.contributor ??
      (this.isEditing
        ? ""
        : this.currentUser?.name || this.currentUser?.username || "")
    );
  }

  get canManageResources() {
    return Boolean(
      this.currentUser?.admin ||
      (!this.args.library &&
        this.currentUser?.academy_moderator_permissions?.manage_resources)
    );
  }

  get shareLabel() {
    if (this.isEditing) {
      return i18n(themePrefix("isbf_v2.learning_edit"));
    }
    return i18n(
      themePrefix(
        this.config?.resource_admin_management === true &&
          !this.canManageResources
          ? "isbf_v2.learning_apply_share"
          : "isbf_v2.learning_share"
      )
    );
  }

  get submitLabel() {
    if (this.isEditing) {
      return i18n(themePrefix("isbf_v2.learning_save_changes"));
    }
    return this.config?.resource_admin_management === true &&
      !this.canManageResources
      ? i18n(themePrefix("isbf_v2.learning_submit_request"))
      : this.shareLabel;
  }

  get descriptionEnabled() {
    return this.config?.resource_description === true;
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
      this.fieldsDisabled ||
      (this.isEditing && !this.editAllowed) ||
      !this.args.course?.id ||
      length < this.minimumTitleLength ||
      length > this.maximumTitleLength ||
      !this.validLink ||
      (this.descriptionEnabled && [...this.description].length > 300) ||
      (this.contributorEnabled &&
        this.contributor !== null &&
        [...this.contributor.trim()].length > 15 &&
        (!this.isEditing ||
          this.contributor.trim() !== this.#original?.contributor))
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
  async retryLoad() {
    if (this.#closed || this.isDestroying || this.loading || this.saving) {
      return;
    }
    this.editReady = false;
    this.loadError = null;
    if (!this.editAllowed) {
      this.loadError = i18n(themePrefix("isbf_v2.learning_edit_unavailable"));
      return;
    }
    const generation = ++this.#loadGeneration;
    const topicId = this.args.resource.id;
    this.loading = true;
    try {
      const topic = await ajax(`/t/${topicId}.json`);
      if (
        this.#closed ||
        this.isDestroying ||
        generation !== this.#loadGeneration
      ) {
        return;
      }
      const firstPost = topic?.post_stream?.posts?.find(
        (post) => post.post_number === 1
      );
      if (topic?.id !== topicId || !Number.isSafeInteger(firstPost?.id)) {
        throw new Error("Unexpected learning topic response");
      }
      const post = await ajax(`/posts/${firstPost.id}.json`);
      if (
        this.#closed ||
        this.isDestroying ||
        generation !== this.#loadGeneration
      ) {
        return;
      }
      const details = learningEditDetails(
        topic,
        post,
        this.args.course?.id,
        this.fieldPrefix
      );
      if (!this.editAllowed || !details) {
        this.loadError = i18n(themePrefix("isbf_v2.learning_edit_unavailable"));
        return;
      }
      this.#original = details;
      this.title = details.title;
      this.link = details.link;
      this.description = details.description;
      this.contributor = details.contributor;
      this.editReady = true;
    } catch {
      if (
        !this.#closed &&
        !this.isDestroying &&
        generation === this.#loadGeneration
      ) {
        this.loadError = i18n(themePrefix("isbf_v2.learning_edit_load_error"));
      }
    } finally {
      if (
        !this.#closed &&
        !this.isDestroying &&
        generation === this.#loadGeneration
      ) {
        this.loading = false;
      }
    }
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
      const response = this.isEditing
        ? await this.#saveEdit()
        : await ajax(
            `/isbf/${this.args.library ? "library" : "learning"}/resources`,
            {
              type: "POST",
              data: {
                [this.args.library ? "group_id" : "course_id"]:
                  this.args.course.id,
                title: this.title.trim(),
                link: this.link.trim(),
                ...(this.descriptionEnabled
                  ? { description: this.description }
                  : {}),
                ...(this.contributorEnabled
                  ? { contributor: this.contributor?.trim() || "" }
                  : {}),
              },
            }
          );
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
          i18n(
            themePrefix(
              this.isEditing
                ? "isbf_v2.learning_edit_error"
                : "isbf_v2.learning_share_error"
            )
          );
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.saving = false;
      }
    }
  }

  async #saveEdit() {
    const original = this.#original;
    if (!this.editAllowed || !this.editReady || !original) {
      throw new Error("Learning resource is not editable");
    }
    const title = this.title.trim();
    const link = this.link.trim();
    const description = this.descriptionEnabled
      ? this.description.replace(/\r\n?/g, "\n").trim()
      : original.description;
    const raw =
      title === original.title &&
      link === original.link &&
      description === original.description
        ? original.raw
        : learningLinkBody(title, link, description);
    const response = await ajax(`/posts/${original.postId}.json`, {
      type: "PUT",
      data: {
        title,
        post: {
          raw,
          [`${this.fieldPrefix}_link`]: link,
          ...(this.descriptionEnabled
            ? { [`${this.fieldPrefix}_description`]: description }
            : {}),
          ...(this.contributorEnabled
            ? {
                [`${this.fieldPrefix}_contributor`]:
                  this.contributor?.trim() || "",
              }
            : {}),
        },
      },
    });
    if (
      response?.post?.id !== original.postId ||
      response.post.topic_id !== original.topicId
    ) {
      throw new Error("Unexpected learning edit response");
    }
    return { success: true, pending: false, edited: true };
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
        {{#if this.loading}}
          <p role="status">{{i18n (themePrefix "isbf_v2.learning_loading")}}</p>
        {{/if}}
        {{#if this.loadError}}
          <p role="alert">{{this.loadError}}</p>
          <DButton
            @action={{this.retryLoad}}
            @disabled={{this.loading}}
            @translatedLabel={{i18n (themePrefix "isbf_v2.learning_retry")}}
          />
        {{/if}}
        <form {{on "submit" this.save}}>
          <label>
            <span>{{i18n
                (themePrefix "isbf_v2.learning_resource_title")
              }}</span>
            <input
              disabled={{this.fieldsDisabled}}
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
                disabled={{this.fieldsDisabled}}
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
              disabled={{this.fieldsDisabled}}
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
                disabled={{this.fieldsDisabled}}
                type="text"
                value={{this.contributorValue}}
                {{on "input" this.changeContributor}}
              />
              <span>{{this.contributorHint}}</span>
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
