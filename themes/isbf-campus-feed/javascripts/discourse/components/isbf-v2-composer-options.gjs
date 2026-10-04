import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";
import { canPublishAnonymously } from "../lib/anonymous-post-scope";
import { isQuickPost } from "../lib/quick-post-scope";

export default class ISBFV2ComposerOptions extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked anonymousSelection = null;

  get model() {
    return this.args.outletArgs?.model;
  }

  get isQuickPost() {
    return isQuickPost(this.model);
  }

  get canAnonymize() {
    return canPublishAnonymously(
      this.model,
      this.currentUser,
      this.siteSettings
    );
  }

  get isAnonymous() {
    const selected = Boolean(this.model?.isbf_anonymous);
    return this.anonymousSelection?.model === this.model
      ? selected && this.anonymousSelection.value
      : selected;
  }

  @action
  toggleAnonymous() {
    const selected = !this.isAnonymous;
    this.model.set("isbf_anonymous", selected);
    this.anonymousSelection = { model: this.model, value: selected };
  }

  <template>
    <span aria-hidden="true" class="isbf-v2-composer"></span>
    {{#if this.isQuickPost}}
      <div class="isbf-v2-composer-options">
        <div aria-hidden="true" class="isbf-v2-composer-options__avatar">
          {{dAvatar this.currentUser imageSize="large"}}
        </div>
      </div>
    {{/if}}
    {{#if this.canAnonymize}}
      <div class="isbf-v2-anonymous-option">
        <DButton
          class="isbf-v2-anonymous-option__toggle"
          @action={{this.toggleAnonymous}}
          @ariaPressed={{this.isAnonymous}}
          @label={{themePrefix "isbf_v2.anonymous_post"}}
        />
        <span>{{i18n (themePrefix "isbf_v2.anonymous_post_hint")}}</span>
      </div>
    {{/if}}
  </template>
}
