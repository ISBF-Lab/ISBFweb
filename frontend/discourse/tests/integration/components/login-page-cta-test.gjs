import { click, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import LoginPageCta from "discourse/components/login-page-cta";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

module("Integration | Component | LoginPageCta", function (hooks) {
  setupRenderingTest(hooks, { anonymous: true });

  test("disables code switching while password login is in progress", async function (assert) {
    let switches = 0;
    this.showCodeLogin = () => switches++;
    this.set("loggingIn", true);

    await render(
      <template>
        <LoginPageCta
          @canLoginLocal={{true}}
          @loggingIn={{this.loggingIn}}
          @loginButtonLabel="login.title"
          @loginDisabled={{true}}
          @onShowCodeLogin={{this.showCodeLogin}}
        />
      </template>
    );

    assert
      .dom("#one-time-code-link")
      .isDisabled("an active login cannot switch methods");

    this.set("loggingIn", false);
    await settled();
    await click("#one-time-code-link");

    assert.strictEqual(
      switches,
      1,
      "the available code button switches methods"
    );
  });

  test("keeps authentication method switching out of second factor prompts", async function (assert) {
    this.showCodeLogin = () => {};
    this.setProperties({ showSecondFactor: true, showSecurityKey: false });

    await render(
      <template>
        <LoginPageCta
          @canLoginLocal={{true}}
          @loginButtonLabel="login.title"
          @onShowCodeLogin={{this.showCodeLogin}}
          @showSecondFactor={{this.showSecondFactor}}
          @showSecurityKey={{this.showSecurityKey}}
        />
      </template>
    );

    assert
      .dom("#one-time-code-link")
      .doesNotExist("the code entry is hidden during a second factor prompt");
    assert
      .dom("#code-login-passwordless-hint")
      .doesNotExist("the code hint is hidden during a second factor prompt");

    this.setProperties({ showSecondFactor: false, showSecurityKey: true });
    await settled();

    assert
      .dom("#one-time-code-link")
      .doesNotExist("the code entry is hidden during a security key prompt");
  });
});
