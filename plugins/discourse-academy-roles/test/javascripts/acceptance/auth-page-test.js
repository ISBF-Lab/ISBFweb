import { click, currentURL, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import cookie, { removeCookie } from "discourse/lib/cookie";
import getURL from "discourse/lib/get-url";
import PreloadStore from "discourse/lib/preload-store";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Academy authentication page", function (needs) {
  needs.settings({
    academy_roles_enabled: true,
    academy_auth_page_enabled: true,
    enable_local_logins: true,
    enable_local_logins_via_email: true,
    enable_local_logins_via_code: true,
    enable_passkeys: true,
    invite_only: true,
  });
  needs.site({
    auth_providers: [
      { name: "google_oauth2", icon_override: "fab-google" },
      { name: "github", icon_override: "fab-github" },
    ],
  });
  needs.hooks.afterEach(() => removeCookie("destination_url"));
  needs.pretender((server, helper) => {
    server.get("/invites/valid-student-code", () =>
      helper.response({ email: null, is_invite_link: true, username: "" })
    );
    server.get("/invites/expired-student-code", () =>
      helper.response(404, {
        errors: ["Invitation expired"],
        invite_status: "expired",
      })
    );
  });

  test("starts with two choices and opens real login methods", async function (assert) {
    await visit("/login");
    assert
      .dom(".academy-auth__choices .btn")
      .exists({ count: 2 }, "two entrance buttons are displayed");
    assert
      .dom("#login-account-name")
      .doesNotExist("credentials are requested after choosing login");
    assert
      .dom(".academy-auth [data-name='code'] input")
      .doesNotExist("the invitation field is inside registration");

    await click(".academy-auth__choices .btn-primary");
    assert
      .dom("#login-account-name")
      .exists("the existing login form is rendered");
    assert
      .dom("#login-buttons .google_oauth2")
      .exists("Google login is preserved");
    assert.dom("#login-buttons .github").exists("GitHub login is preserved");
    assert
      .dom("#login-buttons .passkey-login-button")
      .exists("passkey login is preserved");
    assert.dom("#one-time-code-link").exists("email code login is preserved");
    assert.strictEqual(
      cookie("destination_url"),
      getURL("/"),
      "successful authentication returns to the homepage"
    );
  });

  test("opens invitation registration and validates the code before email", async function (assert) {
    await visit("/login");
    await click(".academy-auth__choices .btn-default");
    assert
      .dom(".academy-auth [data-name='code'] input")
      .exists("the invitation field opens after registration is selected");
    await fillIn(
      ".academy-auth [data-name='code'] input",
      "valid-student-code"
    );
    await click(".academy-auth button[type=submit]");
    assert
      .dom(".code-login-form__email-step")
      .exists("a valid invitation opens the real email code form");
  });

  test("keeps an expired invitation on the invitation step", async function (assert) {
    await visit("/login?mode=register");
    await fillIn(
      ".academy-auth [data-name='code'] input",
      "expired-student-code"
    );
    await click(".academy-auth button[type=submit]");
    assert
      .dom(".academy-auth__error")
      .hasText(
        "An error occurred: Invitation expired",
        "the server error is displayed"
      );
    assert
      .dom(".code-login-form__email-step")
      .doesNotExist("an invalid invitation cannot request an email code");
  });

  test("keeps the direct email code login route", async function (assert) {
    await visit("/login?mode=code");
    assert
      .dom(".code-login-form__email-step")
      .exists("the existing direct code login URL works");
    assert
      .dom(".academy-auth__choices")
      .doesNotExist("the URL opens the chosen method directly");
  });

  test("routes signup through invitation registration", async function (assert) {
    await visit("/signup");
    assert.strictEqual(
      currentURL(),
      "/login?mode=register",
      "signup enters invitation registration"
    );
    assert
      .dom(".academy-auth [data-name='code'] input")
      .exists("signup requires an invitation");
  });

  test("uses the same registration page for a distributed invitation link", async function (assert) {
    PreloadStore.store("invite_info", {
      email: null,
      is_invite_link: true,
      username: "",
    });
    await visit("/invites/distributed-student-code");
    assert
      .dom(".academy-auth")
      .exists("the invitation opens the approved design");
    assert
      .dom(".code-login-form__email-step")
      .exists("the valid URL goes directly to email verification");
  });

  test("the page switch restores the original login UI", async function (assert) {
    this.siteSettings.academy_auth_page_enabled = false;
    await visit("/login");
    assert.dom(".academy-auth").doesNotExist("the new page can be disabled");
    assert
      .dom("#login-account-name")
      .exists("the original login form is available");
    assert
      .dom(".academy-invite-code")
      .exists("the original invitation entry is restored");
  });
});
