import PluginOutlet from "discourse/components/plugin-outlet";
import { and, not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

const LoginPageCta = <template>
  <div class="login-page-cta">
    <div class="login-page-cta__buttons">
      {{#if @canLoginLocal}}
        {{#unless @showSecurityKey}}
          <DButton
            class="btn-large btn-primary login-page-cta__login"
            form="login-form"
            id="login-button"
            tabindex={{unless @showSecondFactor "2"}}
            @disabled={{@loginDisabled}}
            @isLoading={{@loggingIn}}
            @label={{@loginButtonLabel}}
            @type="submit"
          />
        {{/unless}}

        {{#if
          (and @onShowCodeLogin (not @showSecondFactor) (not @showSecurityKey))
        }}
          <div class="login-page-cta__code-login">
            <DButton
              aria-describedby="code-login-passwordless-hint"
              class="btn-large btn-default login-page-cta__code-login-button"
              id="one-time-code-link"
              tabindex="2"
              @action={{@onShowCodeLogin}}
              @disabled={{@loggingIn}}
              @icon="envelope"
              @label="code_login.login_with_code"
            />
            <span
              class="login-page-cta__code-login-hint"
              id="code-login-passwordless-hint"
            >
              {{i18n "code_login.passwordless_hint"}}
            </span>
          </div>
        {{/if}}

        {{#if @showSignupLink}}
          <span class="login-page-cta__no-account-yet">
            {{i18n "create_account.no_account_yet"}}
          </span>
          <DButton
            class="btn-large btn-flat login-page-cta__signup"
            id="new-account-link"
            tabindex="3"
            @action={{@createAccount}}
            @disabled={{@loggingIn}}
            @label="create_account.title"
          />
        {{/if}}
      {{/if}}
    </div>
    <PluginOutlet @connectorTagName="div" @name="login-after-modal-footer" />
  </div>
</template>;

export default LoginPageCta;
