import Component from "@glimmer/component";
import { service } from "@ember/service";
import AvatarSelector from "discourse/components/modal/avatar-selector";
import CreateInvite from "discourse/components/modal/create-invite";
import CreateInviteBulk from "discourse/components/modal/create-invite-bulk";
import CreateInviteWithRoles from "discourse/components/modal/create-invite-with-roles";
import EditUserDirectoryColumns from "discourse/components/modal/edit-user-directory-columns";
import SecondFactorAddSecurityKey from "discourse/components/modal/second-factor-add-security-key";
import SecondFactorAddTotp from "discourse/components/modal/second-factor-add-totp";
import SecondFactorBackupEdit from "discourse/components/modal/second-factor-backup-edit";
import SecondFactorEdit from "discourse/components/modal/second-factor-edit";
import SecondFactorEditSecurityKey from "discourse/components/modal/second-factor-edit-security-key";
import bodyClass from "discourse/helpers/body-class";
import {
  frontendConsistencyScope,
  normalizedRouteName,
} from "../lib/frontend-consistency-scope";

const INVITE_DIALOGS = new Set([
  CreateInvite,
  CreateInviteBulk,
  CreateInviteWithRoles,
]);

const PREFERENCE_DIALOGS = new Set([
  AvatarSelector,
  SecondFactorAddSecurityKey,
  SecondFactorAddTotp,
  SecondFactorBackupEdit,
  SecondFactorEdit,
  SecondFactorEditSecurityKey,
]);

function matchesComponent(component, candidates) {
  return [...candidates].some(
    (candidate) =>
      candidate === component ||
      (component?.prototype &&
        candidate.prototype &&
        Object.prototype.isPrototypeOf.call(
          candidate.prototype,
          component.prototype
        ))
  );
}

export default class ISBFFrontendScope extends Component {
  @service("modal") _modal;
  @service("router") _router;

  get #scope() {
    return frontendConsistencyScope(this._router.currentRouteName);
  }

  get #dialogEnabled() {
    const component = this._modal.activeModal?.component;
    const route = normalizedRouteName(this._router.currentRouteName);

    if (matchesComponent(component, INVITE_DIALOGS)) {
      return (
        this.#scope?.id === "invitations" ||
        route === "new-invite" ||
        route.startsWith("discovery.")
      );
    }

    if (this.#scope?.id === "preferences") {
      return matchesComponent(component, PREFERENCE_DIALOGS);
    }

    return (
      this.#scope?.id === "directory" &&
      matchesComponent(component, new Set([EditUserDirectoryColumns]))
    );
  }

  get bodyClasses() {
    if (!this.#scope && !this.#dialogEnabled) {
      return null;
    }

    const classes = ["isbf-frontend"];
    if (this.#scope) {
      classes.push(`is-frontend-${this.#scope.id}`);
      if (this.#scope.layout === "feature") {
        classes.push("has-frontend-feature");
      }
      if (this.#scope.userContent) {
        classes.push("has-frontend-user-content");
      }
    }
    if (this.#dialogEnabled) {
      classes.push("has-frontend-dialog");
    }
    return classes.join(" ");
  }

  <template>{{bodyClass this.bodyClasses}}</template>
}
