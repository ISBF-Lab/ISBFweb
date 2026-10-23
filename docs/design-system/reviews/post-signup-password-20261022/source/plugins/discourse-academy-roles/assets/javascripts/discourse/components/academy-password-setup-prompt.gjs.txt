import Component from "@glimmer/component";
import { action } from "@ember/object";
import { cancel, scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import AcademyPasswordSetup from "./modal/academy-password-setup";

export default class AcademyPasswordSetupPrompt extends Component {
  @service currentUser;
  @service dialog;
  @service modal;
  @service router;
  @service siteSettings;

  #opening = false;
  #scheduled;

  willDestroy() {
    super.willDestroy(...arguments);
    cancel(this.#scheduled);
  }

  get shouldPrompt() {
    return (
      this.siteSettings.academy_roles_enabled &&
      this.siteSettings.enable_local_logins &&
      !this.siteSettings.enable_discourse_connect &&
      this.currentUser?.academy_password_setup_pending &&
      this.currentUser.no_password &&
      !this.currentUser.is_impersonating &&
      /^\/(?:latest|hot|top|new|unread|following|filter)?\/?$/.test(
        (this.router.currentURL ?? "").split(/[?#]/)[0]
      )
    );
  }

  @action
  schedulePrompt(shouldPrompt, activeModal, dialogShown) {
    if (shouldPrompt && !activeModal && !dialogShown && !this.#opening) {
      this.#scheduled = scheduleOnce("afterRender", this, this.#showPrompt);
    }
  }

  async #showPrompt() {
    if (
      this.isDestroying ||
      !this.shouldPrompt ||
      this.modal.activeModal ||
      this.dialog.show ||
      this.#opening
    ) {
      return;
    }

    this.#opening = true;
    try {
      await this.modal.show(AcademyPasswordSetup);
    } finally {
      this.#opening = false;
    }
  }

  <template>
    {{this.schedulePrompt
      this.shouldPrompt
      this.modal.activeModal
      this.dialog.show
    }}
  </template>
}
