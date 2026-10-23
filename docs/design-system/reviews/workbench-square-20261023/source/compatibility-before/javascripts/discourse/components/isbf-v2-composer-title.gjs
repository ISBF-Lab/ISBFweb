import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import EmberObject, { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DPopupInputTip from "discourse/ui-kit/d-popup-input-tip";
import DTextField from "discourse/ui-kit/d-text-field";
import { i18n } from "discourse-i18n";
import {
  officialCalendarNeedsTitle,
  officialCalendarTopicTitle,
} from "../lib/official-calendar";
import { setOptionalTopicTitle } from "../lib/optional-topic-title";
import { isQuickPost } from "../lib/quick-post-scope";

export default class ISBFV2ComposerTitle extends Component {
  @service composer;
  @service site;
  @service siteSettings;

  @tracked focused = false;

  get model() {
    return this.args.outletArgs?.model;
  }

  get enabled() {
    return isQuickPost(this.model);
  }

  get disabled() {
    return this.model.loading || this.model.disableTitleInput;
  }

  get titleRequired() {
    return (
      this.siteSettings.academy_post_title_required ||
      officialCalendarNeedsTitle(this.model, this.site)
    );
  }

  get label() {
    if (this.siteSettings.academy_post_title_required) {
      return i18n("academy_roles.post_title.required");
    }
    return i18n(
      themePrefix(
        this.titleRequired
          ? "isbf_v2.schedule_post_title"
          : "isbf_v2.optional_title"
      )
    );
  }

  get validation() {
    if (this.focused) {
      return;
    }
    if (this.titleRequired && !officialCalendarTopicTitle(this.model)) {
      return EmberObject.create({
        failed: true,
        reason: this.siteSettings.academy_post_title_required
          ? i18n("academy_roles.post_title.required_error")
          : i18n(themePrefix("isbf_v2.schedule_title_required")),
        lastShownAt: this.composer.get("lastValidatedAt"),
      });
    }
    if (!this.model.isbf_optional_title?.trim()) {
      return;
    }

    let reason;
    if (this.model.missingTitleCharacters > 0) {
      reason = i18n("composer.error.title_too_short", {
        count: this.model.minimumTitleLength,
      });
    } else if (
      this.model.titleLength > this.siteSettings.max_topic_title_length
    ) {
      reason = i18n("composer.error.title_too_long", {
        count: this.siteSettings.max_topic_title_length,
      });
    }

    if (reason) {
      return EmberObject.create({
        failed: true,
        reason,
        lastShownAt: this.composer.get("lastValidatedAt"),
      });
    }
  }

  @action
  updateTitle(event) {
    setOptionalTopicTitle(this.model, event.target.value);
  }

  @action
  focusTitle() {
    this.focused = true;
  }

  @action
  blurTitle() {
    this.focused = false;
  }

  <template>
    {{#if this.enabled}}
      <div class="isbf-v2-composer-title">
        <div class="title-input">
          <DTextField
            aria-required={{if this.titleRequired "true" "false"}}
            @aria-label={{this.label}}
            @autocomplete="off"
            @disabled={{this.disabled}}
            @id="isbf-optional-title"
            @maxLength={{this.siteSettings.max_topic_title_length}}
            @placeholder={{this.label}}
            @value={{this.model.isbf_optional_title}}
            {{on "input" this.updateTitle}}
            {{on "focus" this.focusTitle}}
            {{on "blur" this.blurTitle}}
          />
          <DPopupInputTip @validation={{this.validation}} />
        </div>
      </div>
    {{/if}}
  </template>
}
