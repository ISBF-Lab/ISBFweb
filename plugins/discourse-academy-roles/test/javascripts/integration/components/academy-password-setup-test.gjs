import { click, render, settled, triggerKeyEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";
import AcademyPasswordSetup from "discourse/plugins/discourse-academy-roles/discourse/components/modal/academy-password-setup";

const endpoint = "/academy-roles/password-setup.json";
const password = "new-setup-password-94!";

async function showPasswordSetup(context) {
  await render(<template><ModalContainer /></template>);
  context.owner.lookup("service:modal").show(AcademyPasswordSetup);
  await settled();
}

async function fillPasswords(confirmation = password) {
  const form = formKit(".academy-password-setup form");
  await form.field("password").fillIn(password);
  await form.field("passwordConfirmation").fillIn(confirmation);
}

module("Integration | Component | AcademyPasswordSetup", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.min_password_length = 10;
    this.currentUser.setProperties({
      no_password: true,
      academy_password_setup_pending: true,
    });
    this.requests = [];
    pretender.put(endpoint, (request) => {
      this.requests.push(new URLSearchParams(request.requestBody));
      return response({
        success: true,
        no_password: false,
        academy_password_setup_pending: false,
      });
    });
    pretender.delete(endpoint, () => [204, {}, ""]);
  });

  test("validates both passwords and supports visibility before saving", async function (assert) {
    await showPasswordSetup(this);
    await click(".academy-password-setup .d-modal__footer .btn-primary");
    assert.strictEqual(this.requests.length, 0, "empty passwords are not sent");

    await fillPasswords("another-password-94!");
    await click(".academy-password-setup .d-modal__footer .btn-primary");
    assert
      .dom('[data-name="passwordConfirmation"]')
      .includesText(
        i18n("academy_roles.password_setup.password_mismatch"),
        "a mismatch is explained beside the confirmation"
      );
    assert.strictEqual(
      this.requests.length,
      0,
      "mismatched passwords are not sent"
    );

    const form = formKit(".academy-password-setup form");
    await form.field("password").toggle();
    assert
      .dom(form.field("password").inputElement)
      .hasAttribute("type", "text", "the password can be revealed");
    await form.field("passwordConfirmation").fillIn(password);
    await click(".academy-password-setup .d-modal__footer .btn-primary");

    assert.strictEqual(this.requests.length, 1, "the form submits once");
    assert.strictEqual(
      this.requests[0].get("password"),
      password,
      "the password reaches the endpoint"
    );
    assert.strictEqual(
      this.requests[0].get("password_confirmation"),
      password,
      "confirmation reaches the endpoint"
    );
    assert.false(
      this.currentUser.no_password,
      "the current account has a password"
    );
    assert.false(
      this.currentUser.academy_password_setup_pending,
      "the reminder is completed"
    );
    assert
      .dom(".academy-password-setup")
      .doesNotExist("success closes the modal");
  });

  test("save failure preserves the fields and allows retry", async function (assert) {
    let failed = true;
    pretender.put(endpoint, () =>
      failed
        ? response(503, { errors: ["Please retry"] })
        : response({
            no_password: false,
            academy_password_setup_pending: false,
          })
    );
    await showPasswordSetup(this);
    await fillPasswords();
    await click(".academy-password-setup .d-modal__footer .btn-primary");

    assert
      .dom(".academy-password-setup")
      .includesText("Please retry", "the failure is visible");
    assert
      .form(".academy-password-setup form")
      .field("password")
      .hasValue(password, "the password draft is retained");
    assert
      .form(".academy-password-setup form")
      .field("passwordConfirmation")
      .hasValue(password, "confirmation is retained");
    assert.true(
      this.currentUser.academy_password_setup_pending,
      "failure keeps the reminder pending"
    );
    failed = false;
    await click(".academy-password-setup .d-modal__footer .btn-primary");
    assert.dom(".academy-password-setup").doesNotExist("the retry completes");
  });

  for (const closeWith of ["skip", "button", "escape", "backdrop"]) {
    test(`${closeWith} persists dismissal without setting a password`, async function (assert) {
      let dismissed = 0;
      pretender.delete(endpoint, () => {
        dismissed++;
        return [204, {}, ""];
      });
      await showPasswordSetup(this);
      if (closeWith === "skip") {
        await click(".academy-password-setup .d-modal__footer .btn-default");
      } else if (closeWith === "button") {
        await click(".academy-password-setup .modal-close");
      } else if (closeWith === "escape") {
        await triggerKeyEvent(
          ".academy-password-setup input",
          "keydown",
          "Escape"
        );
      } else {
        await click(".d-modal__backdrop");
      }
      assert.strictEqual(dismissed, 1, "dismissal is saved exactly once");
      assert.true(
        this.currentUser.no_password,
        "skipping does not create a password"
      );
      assert.false(
        this.currentUser.academy_password_setup_pending,
        "the reminder is completed"
      );
      assert.dom(".academy-password-setup").doesNotExist("the modal closes");
    });
  }

  test("dismissal failure retains the reminder until retry succeeds", async function (assert) {
    let failed = true;
    pretender.delete(endpoint, () =>
      failed ? response(503, { errors: ["Please retry"] }) : [204, {}, ""]
    );
    await showPasswordSetup(this);
    await click(".academy-password-setup .d-modal__footer .btn-default");
    assert
      .dom(".academy-password-setup")
      .includesText("Please retry", "the failed dismissal is explained");
    assert.true(
      this.currentUser.academy_password_setup_pending,
      "a failed request cannot consume the reminder"
    );
    failed = false;
    await click(".academy-password-setup .d-modal__footer .btn-default");
    assert
      .dom(".academy-password-setup")
      .doesNotExist("dismissal can be retried");
  });

  test("an expired trust window opens the existing email verification flow", async function (assert) {
    pretender.put(endpoint, () =>
      response(403, { error_type: "password_setup_verification_required" })
    );
    await showPasswordSetup(this);
    await fillPasswords();
    await click(".academy-password-setup .d-modal__footer .btn-primary");

    assert
      .dom(".forgot-password-modal")
      .exists("the existing email flow is opened");
    assert
      .dom(".academy-password-setup")
      .doesNotExist("the forms do not overlap");
    assert.true(
      this.currentUser.academy_password_setup_pending,
      "verification does not silently dismiss the reminder"
    );
    assert.true(
      this.currentUser.no_password,
      "no password is set before verification"
    );
  });
});
