import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import EmberObject, { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DPopupInputTip from "discourse/ui-kit/d-popup-input-tip";
import DTextField from "discourse/ui-kit/d-text-field";
import { i18n } from "discourse-i18n";
import { setOptionalTopicTitle } from "../lib/optional-topic-title";
import { isQuickPost } from "../lib/quick-post-scope";

export default class ISBFV2ComposerTitle extends Component {
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

  get label() {
    return i18n(themePrefix("isbf_v2.optional_title"));
  }

  get validation() {
    if (this.focused || !this.model.isbf_optional_title?.trim()) {
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
      return EmberObject.create({ failed: true, reason });
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
