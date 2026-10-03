import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import getURL from "discourse/lib/get-url";
import logout from "discourse/lib/logout";
import { getCurrentPushSubscription } from "discourse/lib/push-notifications";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ISBFV2AccountMenu extends Component {
  @service currentUser;
  @service dialog;
  @service site;

  @tracked isOpen = false;

  #rootElement;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#removeDocumentListeners();
  }

  get avatarUrl() {
    return this.currentUser?.avatar_template?.replace("{size}", "96");
  }

  get displayName() {
    return this.currentUser?.name || this.currentUser?.username;
  }

  get profileHref() {
    return `/u/${this.currentUser.username}`;
  }

  @action
  openMenu(event) {
    if (this.args.mobile || this.isOpen) {
      return;
    }
    this.#showMenu(event.currentTarget);
  }

  @action
  onFocusOut(event) {
    if (!event.currentTarget.contains(event.relatedTarget)) {
      this.closeMenu();
    }
  }

  @action
  onMouseLeave() {
    if (this.args.mobile) {
      return;
    }
    if (!this.#rootElement?.contains(document.activeElement)) {
      this.closeMenu();
    }
  }

  @action
  onOutsidePointer(event) {
    if (!this.#rootElement?.contains(event.target)) {
      this.closeMenu();
    }
  }

  @action
  onKeyDown(event) {
    if (event.key === "Escape" && this.isOpen) {
      event.preventDefault();
      this.#rootElement
        ?.querySelector(".isbf-v2-account-menu__trigger")
        ?.focus();
      this.closeMenu();
    }
  }

  @action
  toggleMenu(event) {
    if (this.isOpen && this.args.mobile) {
      this.closeMenu();
    } else if (this.isOpen) {
      this.#rootElement
        ?.querySelector(".isbf-v2-account-menu__panel button")
        ?.focus();
    } else {
      this.#showMenu(event.currentTarget);
    }
  }

  @action
  closeMenu() {
    this.isOpen = false;
    this.#removeDocumentListeners();
  }

  @action
  async confirmLogout() {
    this.closeMenu();
    if (
      await this.dialog.confirm({
        message: i18n(themePrefix("isbf_v2.logout_confirm"), {
          username: this.currentUser.username,
        }),
        confirmButtonLabel: themePrefix("isbf_v2.logout"),
      })
    ) {
      await this.#signOut(false);
    }
  }

  @action
  async confirmSwitch() {
    this.closeMenu();
    if (
      await this.dialog.confirm({
        message: i18n(themePrefix("isbf_v2.switch_account_confirm")),
        confirmButtonLabel: themePrefix("isbf_v2.switch_account"),
      })
    ) {
      await this.#signOut(true);
    }
  }

  #showMenu(target) {
    this.#rootElement = target.closest(".isbf-v2-account-menu");
    this.isOpen = true;
    document.addEventListener("pointerdown", this.onOutsidePointer, true);
    document.addEventListener("keydown", this.onKeyDown, true);
  }

  #removeDocumentListeners() {
    document.removeEventListener("pointerdown", this.onOutsidePointer, true);
    document.removeEventListener("keydown", this.onKeyDown, true);
  }

  async #signOut(switchAccount) {
    if (this.site.isReadOnly && !this.site.isStaffWritesOnly) {
      await this.dialog.alert(i18n("read_only_mode.logout_disabled"));
      return;
    }

    try {
      const pushSubscription = await getCurrentPushSubscription();
      const response = await this.currentUser.destroySession(pushSubscription);
      logout({
        redirect:
          response.redirect_url ||
          (switchAccount ? getURL("/login") : undefined),
      });
    } catch {
      await this.dialog.alert(i18n(themePrefix("isbf_v2.logout_failed")));
    }
  }

  <template>
    {{#if this.currentUser}}
      <div
        class={{if
          @mobile
          "isbf-v2-account-menu isbf-v2-account-menu--mobile"
          "isbf-v2-account-menu isbf-v2-account-menu--side"
        }}
        {{on "focusin" this.openMenu}}
        {{on "focusout" this.onFocusOut}}
        {{on "mouseenter" this.openMenu}}
        {{on "mouseleave" this.onMouseLeave}}
      >
        {{#unless @mobile}}
          <a
            class="isbf-v2-side__account"
            href={{this.profileHref}}
            {{on "click" this.closeMenu}}
          >
            <img alt="" height="40" src={{this.avatarUrl}} width="40" />
            <span><b>{{this.displayName}}</b><small
              >@{{this.currentUser.username}}</small></span>
          </a>
        {{/unless}}
        <button
          aria-expanded={{if this.isOpen "true" "false"}}
          aria-label={{i18n (themePrefix "isbf_v2.account_actions")}}
          class="isbf-v2-account-menu__trigger"
          type="button"
          {{on "click" this.toggleMenu}}
        >
          {{#unless @mobile}}<img
              alt=""
              class="isbf-v2-account-menu__compact-avatar"
              height="40"
              src={{this.avatarUrl}}
              width="40"
            />{{/unless}}
          {{dIcon "ellipsis"}}
        </button>
        {{#if this.isOpen}}
          <div
            aria-label={{i18n (themePrefix "isbf_v2.account_actions")}}
            class="isbf-v2-account-menu__panel"
            role="group"
          >
            {{#unless @mobile}}<a
                class="isbf-v2-account-menu__compact-profile"
                href={{this.profileHref}}
                {{on "click" this.closeMenu}}
              >{{i18n (themePrefix "isbf_v2.profile")}}</a>{{/unless}}
            <a href="/isbf-anonymous/posts" {{on "click" this.closeMenu}}>{{i18n
                (themePrefix "isbf_v2.my_anonymous_posts")
              }}</a>
            <button type="button" {{on "click" this.confirmSwitch}}>{{i18n
                (themePrefix "isbf_v2.switch_account")
              }}</button>
            <button type="button" {{on "click" this.confirmLogout}}>{{i18n
                (themePrefix "isbf_v2.logout")
              }}
              @{{this.currentUser.username}}</button>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
