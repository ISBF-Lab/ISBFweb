import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import CodeLoginForm from "discourse/components/code-login-form";
import Form from "discourse/components/form";
import Logo from "discourse/components/header/logo";
import InterfaceColorSelector from "discourse/components/interface-color-selector";
import LocalLoginForm from "discourse/components/local-login-form";
import LoginButtons from "discourse/components/login-buttons";
import LoginPageCta from "discourse/components/login-page-cta";
import NoLoginMethods from "discourse/components/no-login-methods";
import PluginOutlet from "discourse/components/plugin-outlet";
import bodyClass from "discourse/helpers/body-class";
import hideApplicationHeaderButtons from "discourse/helpers/hide-application-header-buttons";
import hideApplicationSidebar from "discourse/helpers/hide-application-sidebar";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import cookie from "discourse/lib/cookie";
import getURL from "discourse/lib/get-url";
import { applyValueTransformer } from "discourse/lib/transformer";
import DiscourseURL from "discourse/lib/url";
import { and, not, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DFlashMessage from "discourse/ui-kit/d-flash-message";
import { i18n } from "discourse-i18n";
import createAuthParticles from "../lib/academy-auth-particles";

export default class AcademyAuthPage extends Component {
  @service interfaceColor;
  @service router;
  @service session;
  @service site;
  @service siteSettings;

  @tracked alumniRegistration = false;
  @tracked completing = false;
  @tracked formHidden = false;
  @tracked noticeVisible = false;
  @tracked paused = false;
  @tracked inviteError;
  @tracked inviteInfo;
  @tracked verifyingInvite = false;

  privacyUrl = getURL("/privacy");
  termsUrl = getURL("/tos");

  #completed = false;
  #deadline;
  #entry;
  #formTimer;
  #navigationTimer;
  #operation = 0;
  #progressFrame;
  #renderer;
  #root;
  #run = 0;
  #scene;
  #sceneReady = false;

  constructor() {
    super(...arguments);
    this.alumniRegistration =
      new URLSearchParams(window.location.search).get("alumni") === "1";
    schedule("afterRender", () => {
      if (this.isDestroying || !this.interfaceColor.selectorAvailable) {
        return;
      }
      this.interfaceColor.ensureCorrectMode();
      if (!this.interfaceColor.colorMode) {
        this.interfaceColor.useAutoMode({ adjustStylesheets: false });
      }
    });
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#operation++;
    this.#cancelSuccess();
    this.#renderer?.destroy();
    document.removeEventListener("keydown", this.handleEscape);
    document.removeEventListener("visibilitychange", this.checkDeadline);
    window.removeEventListener("pagehide", this.cancelNavigation);
  }

  get view() {
    if (this.completing || this.formHidden) {
      return "success";
    }
    if (
      this.args.inviteInfo ||
      this.args.controller?.loginMode === "register"
    ) {
      return "register";
    }
    const controller = this.args.controller;
    if (
      controller?.loginMode === "login" ||
      controller?.loginMode === "code" ||
      controller?.loginMode === "password" ||
      controller?.codeLoginSelected ||
      controller?.showSecondFactor ||
      controller?.showSecurityKey ||
      controller?.flash
    ) {
      return "login";
    }
    return "welcome";
  }

  get isWelcome() {
    return this.view === "welcome";
  }

  get isLogin() {
    return this.view === "login";
  }

  get isRegister() {
    return this.view === "register";
  }

  get alumniRegistrationEnabled() {
    if (this.site.isbf_alumni) {
      return this.site.isbf_alumni.registration_enabled === true;
    }

    // Login-required sites omit plugin metadata from the anonymous Site payload.
    // These public settings expose the entry; the Alumni API still authorizes it.
    return (
      this.siteSettings.login_required === true &&
      this.siteSettings.isbf_alumni_enabled === true &&
      this.siteSettings.isbf_alumni_registration_enabled === true
    );
  }

  get invitation() {
    return this.args.inviteInfo || this.inviteInfo;
  }

  get logoUrl() {
    return this.#resolveLogo();
  }

  get logoUrlDark() {
    return this.session.darkModeAvailable ? this.#resolveLogo(true) : "";
  }

  get motionIcon() {
    return this.paused ? "play" : "pause";
  }

  get motionLabel() {
    return this.paused
      ? "academy_roles.auth.play_motion"
      : "academy_roles.auth.pause_motion";
  }

  @action
  selectRegistration(alumni) {
    this.alumniRegistration = alumni;
  }

  @action
  attach(element) {
    this.#root = element;
    this.#entry = this.args.controller?.loginMode;
    this.#renderer = createAuthParticles({
      root: element,
      onReady: this.sceneReady,
      onPauseChange: this.updatePause,
    });
    document.addEventListener("keydown", this.handleEscape);
    document.addEventListener("visibilitychange", this.checkDeadline);
    window.addEventListener("pagehide", this.cancelNavigation);
    this.syncScene();
  }

  @action
  entryChanged() {
    const entry = this.args.controller?.loginMode;
    if (entry !== this.#entry) {
      this.#entry = entry;
      this.#operation++;
      this.#cancelSuccess();
      this.completing = false;
      this.formHidden = false;
      this.noticeVisible = false;
      this.syncScene();
    }
  }

  @action
  syncScene() {
    const mode = this.isWelcome
      ? "welcome"
      : this.view === "success"
        ? "success"
        : "nebula";
    if (mode !== this.#scene) {
      this.#scene = mode;
      this.#sceneReady = false;
      this.#renderer?.requestScene(mode, ++this.#run);
    }
    if (this.isLogin) {
      cookie("destination_url", getURL("/"));
    }
  }

  @action
  openLogin() {
    this.#cancelSuccess();
    this.router.transitionTo("login", { queryParams: { mode: "login" } });
  }

  @action
  openRegistration() {
    if (this.#completed) {
      this.router
        .transitionTo("login", { queryParams: { mode: "register" } })
        .then(() => {
          if (!this.isDestroying) {
            this.#entry = this.args.controller?.loginMode;
            this.completing = true;
            this.formHidden = true;
            this.syncScene();
          }
        });
      return;
    }
    this.router.transitionTo("login", {
      queryParams: { mode: "register" },
    });
  }

  @action
  close() {
    this.#operation++;
    this.#cancelSuccess();
    this.completing = false;
    this.formHidden = false;
    this.noticeVisible = false;
    if (this.args.controller?.localLogin) {
      this.args.controller.setProperties({
        flash: null,
        codeLoginSelected: false,
        loginPassword: "",
        secondFactorRequired: false,
        secondFactorToken: "",
        securityKeyCredential: null,
        showLoginButtons: true,
        showSecondFactor: false,
        showSecurityKey: false,
      });
    }
    this.router.transitionTo("login", { queryParams: { mode: null } });
  }

  @action
  handleEscape(event) {
    if (
      event.key === "Escape" &&
      !this.isWelcome &&
      !document.querySelector(".d-modal__container, [role='dialog']")
    ) {
      event.preventDefault();
      this.close();
    }
  }

  @action
  async redeem({ code }) {
    if (this.verifyingInvite) {
      return;
    }
    const token = code?.trim();
    if (!token) {
      return;
    }
    const operation = ++this.#operation;
    this.verifyingInvite = true;
    this.inviteError = null;
    try {
      const info = await ajax(`/invites/${encodeURIComponent(token)}`);
      if (this.isDestroying || operation !== this.#operation) {
        return;
      }
      if (info.existing_user_id) {
        this.inviteError = i18n("academy_roles.auth.new_account_required");
        return;
      }
      if (!this.siteSettings.enable_local_logins_via_code) {
        DiscourseURL.redirectTo(`/invites/${encodeURIComponent(token)}`);
        return;
      }
      this.inviteInfo = { ...info, token };
    } catch (error) {
      if (!this.isDestroying && operation === this.#operation) {
        this.inviteError = extractError(error);
      }
    } finally {
      if (!this.isDestroying) {
        this.verifyingInvite = false;
      }
    }
  }

  @action
  authenticated({ accountCreated }) {
    if (this.isDestroying) {
      return;
    }
    if (!this.isRegister || !accountCreated) {
      DiscourseURL.redirectTo("/");
      return;
    }
    if (this.#completed) {
      return;
    }
    this.#completed = true;
    this.completing = true;
    this.syncScene();
    this.#formTimer = setTimeout(() => {
      if (this.isDestroying) {
        return;
      }
      this.formHidden = true;
      this.#revealSuccess();
    }, 250);
  }

  @action
  sceneReady({ mode, run }) {
    if (mode === "success" && run === this.#run && !this.isDestroying) {
      this.#sceneReady = true;
      this.#revealSuccess();
    }
  }

  @action
  updatePause(value) {
    if (!this.isDestroying && this.paused !== value) {
      this.paused = value;
    }
  }

  @action
  toggleMotion() {
    this.#renderer?.setPaused(!this.#renderer.paused);
  }

  @action
  checkDeadline() {
    if (this.#deadline && !document.hidden) {
      if (Date.now() >= this.#deadline) {
        this.#deadline = null;
        DiscourseURL.redirectTo("/");
      } else {
        this.#paintProgress();
      }
    }
  }

  @action
  cancelNavigation() {
    this.#cancelSuccess();
  }

  #revealSuccess() {
    if (!this.formHidden || !this.#sceneReady || this.#deadline) {
      return;
    }
    this.#deadline = Date.now() + 5000;
    this.noticeVisible = true;
    this.#navigationTimer = setTimeout(this.checkDeadline, 5000);
    this.#progressFrame = requestAnimationFrame(() => {
      this.#root.querySelector("#done-title")?.focus({ preventScroll: true });
      this.#paintProgress();
    });
  }

  #paintProgress() {
    cancelAnimationFrame(this.#progressFrame);
    if (!this.#deadline || this.isDestroying || document.hidden) {
      return;
    }
    const reduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;
    const remaining = Math.max(0, this.#deadline - Date.now());
    const ring = this.#root.querySelector("#redirect-progress-value");
    ring?.style.setProperty(
      "stroke-dashoffset",
      reduced ? "0" : String(100 - remaining / 50)
    );
    if (remaining && !reduced) {
      this.#progressFrame = requestAnimationFrame(() => this.#paintProgress());
    }
  }

  #cancelSuccess() {
    clearTimeout(this.#formTimer);
    clearTimeout(this.#navigationTimer);
    cancelAnimationFrame(this.#progressFrame);
    this.#deadline = null;
  }

  #resolveLogo(dark = false) {
    const name =
      this.siteSettings.site_logo_small_url ||
      this.siteSettings.site_logo_small_dark_url
        ? "logo_small"
        : "logo";
    const lightUrl = this.siteSettings[`site_${name}_url`] || "";
    const darkUrl = this.siteSettings[`site_${name}_dark_url`] || "";
    const url = dark
      ? darkUrl
      : this.session.defaultColorSchemeIsDark
        ? darkUrl || lightUrl
        : lightUrl;
    return applyValueTransformer("home-logo-image-url", url, { name, dark });
  }

  <template>
    {{bodyClass "academy-auth-page"}}
    {{hideApplicationHeaderButtons "search" "login" "signup" "menu"}}
    {{hideApplicationSidebar}}
    <section
      class="academy-auth"
      data-view={{this.view}}
      {{didInsert this.attach}}
      {{didUpdate this.entryChanged @controller.loginMode}}
      {{didUpdate this.syncScene this.view}}
    >
      <header class="academy-auth__header">
        <a class="academy-auth__brand" href={{getURL "/"}}>
          {{#if this.logoUrl}}
            <Logo
              @darkUrl={{this.logoUrlDark}}
              @key="academy-auth__logo"
              @title={{this.siteSettings.title}}
              @url={{this.logoUrl}}
            />
          {{/if}}
          <span>{{this.siteSettings.title}}</span>
        </a>
      </header>
      <div aria-hidden="true" class="academy-auth__stage">
        <canvas id="particle-canvas"></canvas>
        <div class="academy-auth__fallback" hidden id="particle-fallback">
          <span class="particle-stage__fallback-name">One</span>
          <svg class="particle-stage__fallback-check" viewBox="0 0 24 24">
            <path
              d="M5 12l4 4L19 6"
              fill="none"
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.8"
            />
          </svg>
          <div id="fallback-confetti"></div>
        </div>
      </div>
      {{#if this.isWelcome}}
        <div class="academy-auth__welcome">
          <h1 class="sr-only">{{i18n "academy_roles.auth.welcome"}}</h1>
          <div class="academy-auth__choices">
            <DButton
              class="btn-primary"
              @action={{this.openLogin}}
              @label="login.title"
            />
            <DButton
              class="btn-default"
              @action={{this.openRegistration}}
              @label="academy_roles.auth.register"
            />
          </div>
        </div>
      {{/if}}
      <div
        class={{if
          this.completing
          "academy-auth__panel is-exiting"
          "academy-auth__panel"
        }}
        hidden={{or this.isWelcome this.formHidden}}
        id="access-panel"
        inert={{this.completing}}
      >
        <DButton
          class="btn-flat academy-auth__close"
          @action={{this.close}}
          @ariaLabel="academy_roles.auth.back"
          @icon="xmark"
        />
        {{#if this.isLogin}}
          <DFlashMessage
            @flash={{@controller.flash}}
            @type={{@controller.flashType}}
          />
          {{#if @controller.hasNoLoginOptions}}
            <NoLoginMethods />
          {{else}}
            {{#unless @controller.showCodeLoginForm}}
              <h1 class="academy-auth__title">{{i18n "login.title"}}</h1>
            {{/unless}}
            {{#if @controller.canLoginLocal}}
              {{#if @controller.showCodeLoginForm}}
                <CodeLoginForm
                  @initialEmail={{@controller.loginName}}
                  @onAuthenticated={{this.authenticated}}
                  @onUsePassword={{@controller.usePassword}}
                />
              {{else}}
                <LocalLoginForm
                  @backupEnabled={{@controller.backupEnabled}}
                  @canLoginLocalWithEmail={{@controller.canLoginLocalWithEmail}}
                  @canUseCodeLogin={{@controller.canUseCodeLogin}}
                  @canUsePasskeys={{@controller.canUsePasskeys}}
                  @flashChanged={{@controller.flashChanged}}
                  @flashTypeChanged={{@controller.flashTypeChanged}}
                  @handleForgotPassword={{@controller.handleForgotPassword}}
                  @login={{@controller.localLogin}}
                  @loginName={{@controller.loginName}}
                  @loginNameChanged={{@controller.loginNameChanged}}
                  @loginPassword={{@controller.loginPassword}}
                  @loginPasswordChanged={{@controller.loginPasswordChanged}}
                  @otherMethodAllowed={{@controller.otherMethodAllowed}}
                  @passkeyLogin={{@controller.passkeyLogin}}
                  @secondFactorMethod={{@controller.secondFactorMethod}}
                  @secondFactorToken={{@controller.secondFactorToken}}
                  @secondFactorTokenChanged={{@controller.secondFactorTokenChanged}}
                  @securityKeyAllowedCredentialIds={{@controller.securityKeyAllowedCredentialIds}}
                  @securityKeyChallenge={{@controller.securityKeyChallenge}}
                  @securityKeyCredentialChanged={{@controller.securityKeyCredentialChanged}}
                  @showSecondFactor={{@controller.showSecondFactor}}
                  @showSecurityKey={{@controller.showSecurityKey}}
                  @totpEnabled={{@controller.totpEnabled}}
                />
                <LoginPageCta
                  @canLoginLocal={{@controller.canLoginLocal}}
                  @loggingIn={{@controller.loggingIn}}
                  @loginButtonLabel={{@controller.loginButtonLabel}}
                  @loginDisabled={{@controller.loginDisabled}}
                  @onShowCodeLogin={{if
                    @controller.canUseCodeLogin
                    @controller.showCodeLogin
                  }}
                  @showSecondFactor={{@controller.showSecondFactor}}
                  @showSecurityKey={{@controller.showSecurityKey}}
                />
              {{/if}}
            {{/if}}
            {{#if
              (and
                @controller.showLoginButtons
                (not @controller.showSecondFactor)
                (not @controller.showSecurityKey)
              )
            }}
              <LoginButtons
                @context="login"
                @externalLogin={{@controller.externalLogin}}
                @passkeyLogin={{@controller.passkeyLogin}}
              />
            {{/if}}
            <DButton
              class="btn-flat academy-auth__register-link"
              @action={{this.openRegistration}}
              @label="academy_roles.invite_title"
            />
          {{/if}}
        {{else if this.isRegister}}
          {{#if this.invitation}}
            <CodeLoginForm
              @context="invite"
              @emailLocked={{not this.invitation.is_invite_link}}
              @initialEmail={{this.invitation.email}}
              @inviteKey={{this.invitation.token}}
              @onAuthenticated={{this.authenticated}}
              @usernameHint={{i18n "academy_roles.auth.username_hint"}}
            />
          {{else}}
            {{#if this.alumniRegistrationEnabled}}
              <div
                aria-label={{i18n "academy_roles.auth.registration_method"}}
                class="academy-auth__registration-options"
                role="group"
              >
                <DButton
                  aria-pressed={{if this.alumniRegistration "false" "true"}}
                  @action={{fn this.selectRegistration false}}
                  @label="academy_roles.auth.invite_title"
                />
                <DButton
                  aria-pressed={{if this.alumniRegistration "true" "false"}}
                  @action={{fn this.selectRegistration true}}
                  @label="academy_roles.auth.alumni_registration"
                />
              </div>
            {{/if}}
            {{#if (and this.alumniRegistrationEnabled this.alumniRegistration)}}
              <PluginOutlet @name="academy-alumni-registration" />
            {{else}}
              <h1 class="academy-auth__title">{{i18n
                  "academy_roles.auth.invite_title"
                }}</h1>
              <Form @onSubmit={{this.redeem}} as |form|>
                <form.Field
                  class="academy-auth__invite-field"
                  @format="full"
                  @name="code"
                  @title={{i18n "academy_roles.invite_code"}}
                  @type="input"
                  @validation="required"
                  as |field|
                >
                  <field.Control
                    autocomplete="off"
                    autofocus="autofocus"
                    maxlength="128"
                    placeholder={{i18n "academy_roles.invite_code"}}
                    spellcheck="false"
                  />
                </form.Field>
                {{#if this.inviteError}}
                  <p
                    class="academy-auth__error"
                    role="alert"
                  >{{this.inviteError}}</p>
                {{/if}}
                <form.Submit
                  @disabled={{this.verifyingInvite}}
                  @label="continue"
                />
              </Form>
            {{/if}}
          {{/if}}
          <DButton
            class="btn-flat academy-auth__register-link"
            @action={{this.openLogin}}
            @label="login.title"
          />
        {{/if}}
      </div>
      <section
        class="academy-auth__success"
        hidden={{not this.formHidden}}
        id="success-view"
      >
        <h2
          aria-describedby="success-notice-text"
          class="sr-only"
          id="done-title"
          tabindex="-1"
        >{{i18n "academy_roles.auth.success"}}</h2>
        <p
          class="academy-auth__notice"
          hidden={{not this.noticeVisible}}
          id="success-notice"
        >
          <svg
            aria-hidden="true"
            class="academy-auth__progress"
            viewBox="0 0 16 16"
          >
            <circle class="academy-auth__progress-track" cx="8" cy="8" r="6" />
            <circle
              class="academy-auth__progress-value"
              cx="8"
              cy="8"
              id="redirect-progress-value"
              pathLength="100"
              r="6"
            />
          </svg>
          <span id="success-notice-text">{{i18n
              "academy_roles.auth.redirect_notice"
            }}</span>
        </p>
      </section>
      <footer class="academy-auth__footer">
        <div class="academy-auth__policies">
          <a href={{this.termsUrl}}>{{i18n "tos"}}</a>
          <a href={{this.privacyUrl}}>{{i18n "privacy"}}</a>
        </div>
        <div class="academy-auth__controls">
          {{#if
            (and
              this.interfaceColor.selectorAvailable
              this.interfaceColor.colorMode
            )
          }}
            <InterfaceColorSelector />
          {{/if}}
          <DButton
            aria-pressed={{not this.paused}}
            class="btn-flat academy-auth__motion"
            id="particle-motion-button"
            @action={{this.toggleMotion}}
            @ariaLabel={{this.motionLabel}}
            @icon={{this.motionIcon}}
          />
        </div>
      </footer>
    </section>
  </template>
}
