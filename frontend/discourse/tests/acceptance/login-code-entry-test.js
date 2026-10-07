import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

for (const mobile of [false, true]) {
  acceptance(
    `Login code entry - ${mobile ? "mobile" : "desktop"}`,
    function (needs) {
      needs.settings({
        enable_local_logins: true,
        enable_local_logins_via_email: true,
        enable_local_logins_via_code: true,
      });

      if (mobile) {
        needs.mobileView();
      }

      let codeRequests;

      needs.hooks.beforeEach(() => {
        codeRequests = 0;
      });

      needs.pretender((server, helper) => {
        server.get("/session/hp.json", () =>
          helper.response({
            value: "hp-value",
            challenge: "abc",
            expires_in: 300,
          })
        );
        server.post("/session/login-code", () => {
          codeRequests++;
          return helper.response({ success: "OK" });
        });
      });

      test("offers a code button below password login without requiring a password", async function (assert) {
        await visit("/login");

        assert
          .dom("#login-account-password")
          .exists("password login is the default")
          .hasValue("", "the code entry is available with an empty password");
        assert
          .dom(
            "#login-button + .login-page-cta__code-login #one-time-code-link"
          )
          .exists(
            "the code button appears directly below the password login button"
          );
        assert
          .dom("#one-time-code-link")
          .exists({ count: 1 }, "there is one code entry")
          .isEnabled("code login does not require a password")
          .hasAttribute(
            "type",
            "button",
            "the code button does not submit password login"
          )
          .hasText(
            i18n("code_login.login_with_code"),
            "the button names the login method"
          );
        assert
          .dom("#code-login-passwordless-hint")
          .hasText(
            i18n("code_login.passwordless_hint"),
            "the hint explains how to log in without a password"
          );

        await click("#one-time-code-link");

        assert
          .dom(".code-login-form__email-step")
          .exists("the button opens code login");
        assert.strictEqual(
          codeRequests,
          0,
          "switching modes does not send a code"
        );
      });

      test("preserves the email when switching between login methods", async function (assert) {
        await visit("/login");
        await fillIn("#login-account-name", "student@example.com");
        await click("#one-time-code-link");

        assert
          .dom(".code-login-form__email-step input[type='email']")
          .hasValue(
            "student@example.com",
            "code login receives the entered email"
          );

        await click(".code-login-form__password-toggle");

        assert
          .dom("#login-account-password")
          .exists("the user can return to password login");
        assert
          .dom("#login-account-name")
          .hasValue(
            "student@example.com",
            "password login retains the entered email"
          );
        assert
          .dom("#one-time-code-link")
          .exists("code login remains available");
      });

      test("keeps the email link when code login is disabled", async function (assert) {
        this.siteSettings.enable_local_logins_via_code = false;

        await visit("/login");

        assert
          .dom("#login-account-password")
          .exists("password login remains available");
        assert
          .dom("#one-time-code-link")
          .doesNotExist("the code entry is hidden");
        assert
          .dom("#code-login-passwordless-hint")
          .doesNotExist("the code hint is hidden");
        assert
          .dom("#email-login-link")
          .exists("the existing email link remains available");
      });

      test("supports opening code login directly", async function (assert) {
        await visit("/login?mode=code");

        assert
          .dom(".code-login-form__email-step")
          .exists("the code URL opens code login");
        assert
          .dom("#login-account-password")
          .doesNotExist("the password form is hidden");
        assert
          .dom("#one-time-code-link")
          .doesNotExist("the code form has no duplicate entry");
      });
    }
  );
}
