import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import ForgotPassword from "discourse/components/modal/forgot-password";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import PasswordValidationHelper from "discourse/lib/password-validation-helper";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dUniqueId from "discourse/ui-kit/helpers/d-unique-id";
import { i18n } from "discourse-i18n";

export default class AcademyPasswordSetup extends Component {
  @service a11y;
  @service currentUser;
  @service modal;
  @service siteSettings;

  @tracked busy = false;
  @tracked error;

  formId = dUniqueId();

  #completed = false;

  @action
  async beforeClose() {
    if (this.busy) {
      return false;
    }
    return this.#completed || this.#dismiss();
  }

  @action
  async save(data) {
    if (this.busy) {
      return;
    }

    this.busy = true;
    this.error = null;
    try {
      const result = await ajax("/academy-roles/password-setup.json", {
        type: "PUT",
        data: {
          password: data.password,
          password_confirmation: data.passwordConfirmation,
        },
      });

      if (!this.isDestroying) {
        this.#completed = true;
        this.currentUser.setProperties({
          no_password: result.no_password,
          academy_password_setup_pending: result.academy_password_setup_pending,
        });
        this.a11y.announce(i18n("academy_roles.password_setup.success"));
        this.args.closeModal();
      }
    } catch (error) {
      if (!this.isDestroying) {
        const response = (error.jqXHR ?? error).responseJSON;
        if (response?.error_type === "password_setup_verification_required") {
          this.a11y.announce(
            i18n("academy_roles.password_setup.verification_required")
          );
          this.modal.show(ForgotPassword, {
            model: {
              emailOrUsername:
                this.currentUser.email || this.currentUser.username,
            },
          });
        } else {
          this.error = extractError(error);
          this.a11y.announce(this.error, "assertive");
        }
      }
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }

  @action
  async skip() {
    if (!this.busy && (await this.#dismiss()) && !this.isDestroying) {
      this.args.closeModal();
    }
  }

  @action
  validatePasswords(data, { addError }) {
    const helper = new PasswordValidationHelper({
      accountPassword: data.password,
      accountUsername: this.currentUser.username,
      accountName: this.currentUser.name,
      accountEmail: this.currentUser.email,
      admin: this.currentUser.admin,
      passwordRequired: true,
      forceValidationReason: true,
      siteSettings: this.siteSettings,
    });
    const validation = helper.passwordValidation;

    if (data.password && validation.failed) {
      addError("password", {
        title: i18n("academy_roles.password_setup.new_password"),
        message: validation.reason || validation.message,
      });
    }
    if (
      data.passwordConfirmation &&
      data.password !== data.passwordConfirmation
    ) {
      addError("passwordConfirmation", {
        title: i18n("academy_roles.password_setup.confirm_password"),
        message: i18n("academy_roles.password_setup.password_mismatch"),
      });
    }
  }

  async #dismiss() {
    this.busy = true;
    this.error = null;
    try {
      await ajax("/academy-roles/password-setup.json", { type: "DELETE" });
      this.#completed = true;
      this.currentUser.set("academy_password_setup_pending", false);
      return true;
    } catch (error) {
      if (!this.isDestroying) {
        this.error = extractError(error);
        this.a11y.announce(this.error, "assertive");
      }
      return false;
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }

  <template>
    <DModal
      class="academy-password-setup"
      ...attributes
      @beforeClose={{this.beforeClose}}
      @closeModal={{@closeModal}}
      @dismissable={{not this.busy}}
      @flash={{this.error}}
      @flashType="error"
      @title={{i18n "academy_roles.password_setup.title"}}
    >
      <:body>
        <p>{{i18n "academy_roles.password_setup.description"}}</p>
        <Form
          id={{this.formId}}
          @onSubmit={{this.save}}
          @validate={{this.validatePasswords}}
          as |form|
        >
          <form.Field
            @disabled={{this.busy}}
            @format="full"
            @name="password"
            @title={{i18n "academy_roles.password_setup.new_password"}}
            @type="password"
            @validation="required"
            as |field|
          >
            <field.Control maxlength="200" />
          </form.Field>
          <form.Field
            @disabled={{this.busy}}
            @format="full"
            @name="passwordConfirmation"
            @title={{i18n "academy_roles.password_setup.confirm_password"}}
            @type="password"
            @validation="required"
            as |field|
          >
            <field.Control maxlength="200" />
          </form.Field>
        </Form>
      </:body>
      <:footer>
        <DButton
          class="btn-primary"
          @disabled={{this.busy}}
          @form={{this.formId}}
          @isLoading={{this.busy}}
          @label="academy_roles.password_setup.submit"
          @type="submit"
        />
        <DButton
          class="btn-default"
          @action={{this.skip}}
          @disabled={{this.busy}}
          @label="academy_roles.password_setup.skip"
        />
      </:footer>
    </DModal>
  </template>
}
