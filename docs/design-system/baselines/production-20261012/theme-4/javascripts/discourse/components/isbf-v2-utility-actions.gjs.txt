import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";
import { feedbackCategory, feedbackHref } from "../lib/feedback-category";
import ISBFV2AppearanceModal from "./isbf-v2-appearance-modal";
import ISBFV2JoinModal from "./isbf-v2-join-modal";

export default class ISBFV2UtilityActions extends Component {
  @service currentUser;
  @service dialog;
  @service interfaceColor;
  @service modal;
  @service router;
  @service site;

  get items() {
    return [
      {
        key: "settings",
        icon: "gear",
        label: i18n(themePrefix("isbf_v2.sidebar_settings")),
        action: this.openSettings,
      },
      {
        key: "appearance",
        icon: "circle-half-stroke",
        label: i18n(themePrefix("isbf_v2.appearance")),
        action: this.openAppearance,
      },
      {
        key: "feedback",
        icon: "comment",
        label: i18n(themePrefix("isbf_v2.feedback")),
        action: this.openFeedback,
      },
      {
        key: "join",
        icon: "user-group",
        label: i18n(themePrefix("isbf_v2.join_us")),
        action: this.openJoin,
      },
    ];
  }

  @action
  async openSettings() {
    await this.args.menu?.close();
    this.router.transitionTo(
      this.currentUser
        ? `/u/${encodeURIComponent(this.currentUser.username)}/preferences`
        : "/login",
    );
  }

  @action
  async openAppearance() {
    await this.args.menu?.close();
    if (!this.interfaceColor.selectorAvailable) {
      await this.dialog.alert(
        i18n(themePrefix("isbf_v2.appearance_unavailable")),
      );
      return;
    }
    this.modal.show(ISBFV2AppearanceModal);
  }

  @action
  async openFeedback() {
    await this.args.menu?.close();
    const href = feedbackHref(
      feedbackCategory(this.site, settings.feedback_category_id),
    );
    if (href) {
      this.router.transitionTo(href);
    } else {
      await this.dialog.alert(
        i18n(themePrefix("isbf_v2.feedback_unavailable")),
      );
    }
  }

  @action
  async openJoin() {
    await this.args.menu?.close();
    this.modal.show(ISBFV2JoinModal);
  }

  <template>
    <DDropdownMenu as |dropdown|>
      {{#each this.items key="key" as |item|}}
        <dropdown.item>
          <DButton
            class="btn-flat isbf-v2-more-menu__item"
            @action={{item.action}}
            @icon={{item.icon}}
            @translatedLabel={{item.label}}
          />
        </dropdown.item>
      {{/each}}
    </DDropdownMenu>
  </template>
}
