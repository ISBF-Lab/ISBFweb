import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import PluginOutlet from "discourse/components/plugin-outlet";
import DMenu from "discourse/float-kit/components/d-menu";
import lazyHash from "discourse/helpers/lazy-hash";
import { ajax } from "discourse/lib/ajax";
import logout from "discourse/lib/logout";
import { getCurrentPushSubscription } from "discourse/lib/push-notifications";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dMenuHighlight from "discourse/ui-kit/modifiers/d-menu-highlight";
import { i18n } from "discourse-i18n";

export default class ISBFV2AccountMenu extends Component {
  @service a11y;
  @service currentUser;
  @service dialog;
  @service site;
  @service siteSettings;

  @tracked errorMessage;
  @tracked emailCodeSent = false;
  @tracked emailCodeExpiresIn;
  @tracked isBusy = false;
  @tracked isLinkFormOpen = false;
  @tracked isLinkedAccountsOpen = false;
  @tracked isOpen = false;
  @tracked isSwitchAccessDenied = false;
  @tracked linkedAccounts = [];
  @tracked requestedUsername = "";
  @tracked verificationData = {};
  @tracked verificationLinkId;

  #rootElement;
  #menu;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#removeDocumentListeners();
  }

  get activeLinks() {
    return this.linkedAccounts.filter((link) =>
      ["pending_target", "pending_admin", "approved"].includes(link.status)
    );
  }

  get avatarUrl() {
    return this.currentUser?.avatar_template?.replace("{size}", "96");
  }

  get canLinkAccounts() {
    return (
      this.currentUser?.admin && this.siteSettings.isbf_account_switch_enabled
    );
  }

  get canSwitchAccounts() {
    return (
      !this.isSwitchAccessDenied &&
      this.siteSettings.isbf_account_switch_enabled &&
      (this.currentUser?.admin || this.currentUser?.can_switch_linked_accounts)
    );
  }

  get displayName() {
    return this.currentUser?.name || this.currentUser?.username;
  }

  get emailCodeSentMessage() {
    return i18n(themePrefix("isbf_v2.email_code_sent"), {
      minutes: Math.ceil(this.emailCodeExpiresIn / 60),
    });
  }

  get profileHref() {
    return `/u/${this.currentUser.username}`;
  }

  get showLinkedAccounts() {
    return this.canLinkAccounts || this.isLinkedAccountsOpen;
  }

  @action
  registerMenu(menu) {
    this.#menu = menu;
    this.#rootElement = menu.triggerElement.closest(".isbf-v2-account-menu");
  }

  @action
  menuShown() {
    this.isOpen = true;
    this.#loadAccounts();
  }

  @action
  menuClosed() {
    this.isOpen = false;
    this.#resetForms();
  }

  @action
  closeMenu() {
    this.#menu?.close();
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
      await this.#signOut();
    }
  }

  @action
  async createLink(event) {
    event.preventDefault();
    const username = this.requestedUsername.trim();
    if (!username) {
      return;
    }

    await this.#runRequest(async () => {
      await ajax("/isbf/account-switch/links", {
        type: "POST",
        data: { username },
      });
      this.requestedUsername = "";
      this.isLinkFormOpen = false;
      await this.#loadAccounts();
    });
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
    // Removing or disabling a focused control can leave no focus destination.
    if (
      event.relatedTarget &&
      !event.currentTarget.contains(event.relatedTarget) &&
      !this.#menu?.content?.contains(event.relatedTarget)
    ) {
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
  onMouseLeave() {
    if (this.args.mobile) {
      return;
    }
    if (!this.#rootElement?.contains(document.activeElement)) {
      this.#menu?.scheduleHoverClose();
    }
  }

  @action
  onOutsidePointer(event) {
    if (!this.#rootElement?.contains(event.target)) {
      this.closeMenu();
    }
  }

  @action
  selectVerification(link) {
    this.errorMessage = null;
    this.emailCodeSent = false;
    this.verificationData = {
      verificationMethod: "password",
      secondFactorMethod: "1",
    };
    this.verificationLinkId = link.id;
  }

  @action
  async sendEmailCode(link) {
    if (this.isBusy) {
      return;
    }
    await this.#runRequest(async () => {
      const response = await ajax(
        `/isbf/account-switch/links/${link.id}/email-code`,
        { type: "POST" }
      );
      this.emailCodeExpiresIn = response.expires_in;
      this.emailCodeSent = true;
      this.a11y.announce(this.emailCodeSentMessage, "polite");
    });
  }

  @action
  async switchAccount(link) {
    if (!link.device_authorized) {
      this.selectVerification(link);
      return;
    }

    await this.#runRequest(async () => {
      const response = await ajax(
        `/isbf/account-switch/links/${link.id}/switch`,
        { type: "POST" }
      );
      window.location.assign(response.redirect_url || "/");
    });
  }

  @action
  toggleLinkForm() {
    this.errorMessage = null;
    if (this.canLinkAccounts) {
      this.isLinkFormOpen = !this.isLinkFormOpen;
    } else {
      this.isLinkedAccountsOpen = !this.isLinkedAccountsOpen;
    }
    this.verificationLinkId = null;
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
  updateRequestedUsername(event) {
    this.requestedUsername = event.target.value;
  }

  @action
  async verifyAndSwitch(link, formData) {
    const data = {
      verification_method: formData.verificationMethod,
      second_factor_method: formData.secondFactorMethod,
      second_factor_token: formData.secondFactorToken,
    };
    if (formData.verificationMethod === "email_code") {
      data.email_code = formData.emailCode;
    } else {
      data.password = formData.password;
    }

    await this.#runRequest(async () => {
      const response = await ajax(
        `/isbf/account-switch/links/${link.id}/verify`,
        { type: "POST", data }
      );
      window.location.assign(response.redirect_url || "/");
    });
  }

  #errorText(error) {
    return (
      error?.jqXHR?.responseJSON?.errors?.[0] ||
      error?.jqXHR?.responseJSON?.error ||
      i18n(themePrefix("isbf_v2.account_action_failed"))
    );
  }

  async #loadAccounts() {
    if (!this.canSwitchAccounts) {
      return;
    }

    try {
      const response = await ajax("/isbf/account-switch/accounts");
      this.linkedAccounts = response.links || [];
    } catch (error) {
      if (error?.jqXHR?.status === 403 && !this.currentUser.admin) {
        this.isSwitchAccessDenied = true;
        this.linkedAccounts = [];
        this.currentUser.set("can_switch_linked_accounts", false);
        return;
      }
      if (error?.jqXHR?.status !== 404) {
        this.errorMessage = this.#errorText(error);
      }
    }
  }

  #removeDocumentListeners() {
    document.removeEventListener("pointerdown", this.onOutsidePointer, true);
    document.removeEventListener("keydown", this.onKeyDown, true);
  }

  #resetForms() {
    this.errorMessage = null;
    this.isLinkFormOpen = false;
    this.isLinkedAccountsOpen = false;
    this.emailCodeSent = false;
    this.verificationData = {};
    this.requestedUsername = "";
    this.verificationLinkId = null;
  }

  async #runRequest(callback) {
    this.errorMessage = null;
    this.isBusy = true;
    try {
      await callback();
    } catch (error) {
      this.errorMessage = this.#errorText(error);
    } finally {
      this.isBusy = false;
    }
  }

  #showMenu(target) {
    this.#rootElement = target.closest(".isbf-v2-account-menu");
    this.#menu?.show();
  }

  async #signOut() {
    if (this.site.isReadOnly && !this.site.isStaffWritesOnly) {
      await this.dialog.alert(i18n("read_only_mode.logout_disabled"));
      return;
    }

    try {
      const pushSubscription = await getCurrentPushSubscription();
      const response = await this.currentUser.destroySession(pushSubscription);
      logout({ redirect: response.redirect_url });
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
            <span class="isbf-avatar"><img
                alt=""
                height="40"
                src={{this.avatarUrl}}
                width="40"
              /><PluginOutlet
                @name="user-avatar-frame"
                @outletArgs={{lazyHash user=this.currentUser motion="static"}}
              /></span>
            <span>
              <b>{{this.displayName}}</b>
              <small>@{{this.currentUser.username}}</small>
            </span>
          </a>
        {{/unless}}

        <DMenu
          @ariaLabel={{i18n (themePrefix "isbf_v2.account_actions")}}
          @contentClass="isbf-v2-account-menu__float"
          @hoverGracePeriod={{250}}
          @inlineTabOrder={{true}}
          @onClose={{this.menuClosed}}
          @onRegisterApi={{this.registerMenu}}
          @onShow={{this.menuShown}}
          @placement={{if @mobile "bottom-start" "top-start"}}
          @triggerClass="isbf-v2-account-menu__trigger"
          @untriggers={{if @mobile (array "click") (array)}}
        >
          <:trigger>

            {{#unless @mobile}}
              <span
                class="isbf-avatar isbf-v2-account-menu__compact-avatar"
              ><img
                  alt=""
                  height="40"
                  src={{this.avatarUrl}}
                  width="40"
                /><PluginOutlet
                  @name="user-avatar-frame"
                  @outletArgs={{lazyHash user=this.currentUser motion="static"}}
                /></span>
            {{/unless}}
            {{dIcon "ellipsis"}}
          </:trigger>
          <:content>

            <div
              aria-label={{i18n (themePrefix "isbf_v2.account_actions")}}
              class="isbf-v2-account-menu__panel"
              role="group"
              {{dMenuHighlight
                itemSelector=":scope > a, :scope > button, .isbf-v2-account-menu__linked-account > button"
              }}
            >
              {{#unless @mobile}}
                <a
                  class="isbf-v2-account-menu__compact-profile"
                  href={{this.profileHref}}
                  {{on "click" this.closeMenu}}
                >
                  {{i18n (themePrefix "isbf_v2.profile")}}
                </a>
              {{/unless}}
              <a href="/isbf-anonymous/posts" {{on "click" this.closeMenu}}>
                {{i18n (themePrefix "isbf_v2.my_anonymous_posts")}}
              </a>

              {{#if this.canSwitchAccounts}}
                {{#if this.showLinkedAccounts}}
                  {{#each this.activeLinks as |link|}}
                    <div class="isbf-v2-account-menu__linked-account">
                      <span class="isbf-avatar"><img
                          alt=""
                          height="32"
                          src={{link.account.avatar_template}}
                          width="32"
                        /><PluginOutlet
                          @name="user-avatar-frame"
                          @outletArgs={{lazyHash
                            user=link.account
                            motion="static"
                          }}
                        /></span>
                      <span class="isbf-v2-account-menu__account-info">
                        <b class="isbf-v2-account-menu__account-name">
                          {{or link.account.name link.account.username}}
                        </b>
                        <small class="isbf-v2-account-menu__account-username">
                          @{{link.account.username}}
                        </small>
                      </span>
                      {{#if (eq link.status "approved")}}
                        <button
                          disabled={{this.isBusy}}
                          type="button"
                          {{on "click" (fn this.switchAccount link)}}
                        >
                          {{if
                            link.device_authorized
                            (i18n (themePrefix "isbf_v2.switch_now"))
                            (i18n (themePrefix "isbf_v2.verify_device"))
                          }}
                        </button>
                      {{else}}
                        <small class="isbf-v2-account-menu__status">
                          {{i18n (themePrefix "isbf_v2.account_link_pending")}}
                        </small>
                      {{/if}}

                      {{#if (eq this.verificationLinkId link.id)}}
                        <Form
                          class="isbf-v2-account-menu__verify"
                          @data={{this.verificationData}}
                          @onSubmit={{fn this.verifyAndSwitch link}}
                          as |form draft|
                        >
                          {{#if link.account.email_code_enabled}}
                            <form.Field
                              @disabled={{this.isBusy}}
                              @name="verificationMethod"
                              @title={{i18n
                                (themePrefix
                                  "isbf_v2.device_verification_method"
                                )
                              }}
                              @type="select"
                              @validation="required"
                              as |field|
                            >
                              <field.Control @includeNone={{false}} as |select|>
                                <select.Option @value="password">
                                  {{i18n
                                    (themePrefix
                                      "isbf_v2.password_verification"
                                    )
                                  }}
                                </select.Option>
                                <select.Option @value="email_code">
                                  {{i18n
                                    (themePrefix
                                      "isbf_v2.email_code_verification"
                                    )
                                  }}
                                </select.Option>
                              </field.Control>
                            </form.Field>
                          {{/if}}

                          {{#if (eq draft.verificationMethod "email_code")}}
                            <DButton
                              class="isbf-v2-account-menu__send-code"
                              @action={{fn this.sendEmailCode link}}
                              @disabled={{this.isBusy}}
                              @translatedLabel={{if
                                this.emailCodeSent
                                (i18n (themePrefix "isbf_v2.resend_email_code"))
                                (i18n (themePrefix "isbf_v2.send_email_code"))
                              }}
                            />
                            {{#if this.emailCodeSent}}
                              <p class="isbf-v2-account-menu__code-status">
                                {{this.emailCodeSentMessage}}
                              </p>
                            {{/if}}
                            <form.Field
                              @disabled={{this.isBusy}}
                              @name="emailCode"
                              @title={{i18n
                                (themePrefix "isbf_v2.target_email_code")
                              }}
                              @type="input"
                              @validation="required|length:6,6"
                              as |field|
                            >
                              <field.Control
                                autocomplete="one-time-code"
                                inputmode="numeric"
                                maxlength="6"
                                pattern="[0-9]{6}"
                              />
                            </form.Field>
                          {{else}}
                            <form.Field
                              @disabled={{this.isBusy}}
                              @name="password"
                              @title={{i18n
                                (themePrefix "isbf_v2.target_password")
                              }}
                              @type="input-password"
                              @validation="required"
                              as |field|
                            >
                              <field.Control autocomplete="current-password" />
                            </form.Field>
                          {{/if}}

                          {{#if
                            (or
                              link.account.totp_enabled
                              link.account.backup_codes_enabled
                            )
                          }}
                            <form.Field
                              @description={{i18n
                                (themePrefix
                                  (if
                                    (eq draft.secondFactorMethod "2")
                                    "isbf_v2.backup_code_help"
                                    "isbf_v2.authenticator_code_help"
                                  )
                                )
                              }}
                              @disabled={{this.isBusy}}
                              @name="secondFactorToken"
                              @title={{i18n
                                (themePrefix "isbf_v2.second_factor_code")
                              }}
                              @type="input"
                              @validation="required"
                              as |field|
                            >
                              <field.Control autocomplete="one-time-code" />
                            </form.Field>
                          {{/if}}
                          {{#if link.account.backup_codes_enabled}}
                            <form.Field
                              @disabled={{this.isBusy}}
                              @name="secondFactorMethod"
                              @title={{i18n
                                (themePrefix "isbf_v2.second_factor_method")
                              }}
                              @type="select"
                              @validation="required"
                              as |field|
                            >
                              <field.Control @includeNone={{false}} as |select|>
                                <select.Option @value="1">
                                  {{i18n
                                    (themePrefix "isbf_v2.authenticator_code")
                                  }}
                                </select.Option>
                                <select.Option @value="2">
                                  {{i18n (themePrefix "isbf_v2.backup_code")}}
                                </select.Option>
                              </field.Control>
                            </form.Field>
                          {{/if}}
                          <form.Submit
                            @disabled={{this.isBusy}}
                            @label={{themePrefix "isbf_v2.verify_and_switch"}}
                          />
                        </Form>
                      {{/if}}
                    </div>
                  {{/each}}
                {{/if}}

                <button
                  aria-expanded={{if
                    this.canLinkAccounts
                    (if this.isLinkFormOpen "true" "false")
                    (if this.isLinkedAccountsOpen "true" "false")
                  }}
                  class="isbf-v2-account-menu__link"
                  type="button"
                  {{on "click" this.toggleLinkForm}}
                >
                  {{i18n (themePrefix "isbf_v2.link_account")}}
                </button>

                {{#if (and this.canLinkAccounts this.isLinkFormOpen)}}
                  <form
                    class="isbf-v2-account-menu__link-form"
                    {{on "submit" this.createLink}}
                  >
                    <label>
                      {{i18n (themePrefix "isbf_v2.account_username")}}
                      <input
                        autocomplete="username"
                        placeholder={{i18n
                          (themePrefix "isbf_v2.account_username_placeholder")
                        }}
                        required
                        type="text"
                        value={{this.requestedUsername}}
                        {{on "input" this.updateRequestedUsername}}
                      />
                    </label>
                    <button disabled={{this.isBusy}} type="submit">
                      {{i18n (themePrefix "isbf_v2.send_link_request")}}
                    </button>
                  </form>
                {{/if}}

                {{#if this.errorMessage}}
                  <p class="isbf-v2-account-menu__error" role="alert">
                    {{this.errorMessage}}
                  </p>
                {{/if}}
              {{/if}}

              <button type="button" {{on "click" this.confirmLogout}}>
                {{i18n (themePrefix "isbf_v2.logout")}}
                @{{this.currentUser.username}}
              </button>
            </div>
          </:content>
        </DMenu>
      </div>
    {{/if}}
  </template>
}
