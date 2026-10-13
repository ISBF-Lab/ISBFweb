import Component from "@glimmer/component";
import { get } from "@ember/object";
import { service } from "@ember/service";
import AvatarSelector from "discourse/components/modal/avatar-selector";
import Bookmark from "discourse/components/modal/bookmark";
import CreateInvite from "discourse/components/modal/create-invite";
import CreateInviteBulk from "discourse/components/modal/create-invite-bulk";
import CreateInviteWithRoles from "discourse/components/modal/create-invite-with-roles";
import DiscardDraft from "discourse/components/modal/discard-draft";
import EditUserDirectoryColumns from "discourse/components/modal/edit-user-directory-columns";
import GroupAddMembers from "discourse/components/modal/group-add-members";
import GroupDefaultNotifications from "discourse/components/modal/group-default-notifications";
import RequestGroupMembershipForm from "discourse/components/modal/request-group-membership-form";
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

const DIRECTORY_DIALOGS = new Set([EditUserDirectoryColumns]);
const BOOKMARK_DIALOGS = new Set([Bookmark]);
const DRAFT_DIALOGS = new Set([DiscardDraft]);
const GROUP_DIALOGS = new Set([
  GroupAddMembers,
  GroupDefaultNotifications,
  RequestGroupMembershipForm,
]);
const CONFIRMATION_SCOPES = new Set([
  "preferences",
  "invitations",
  "bookmarks",
  "drafts",
  "pending",
  "messages",
  "groups",
  "group",
  "group-manage",
  "group-messages",
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
  @service("dialog") _dialog;
  @service("modal") _modal;
  @service("router") _router;

  get #scope() {
    return frontendConsistencyScope(this._router.currentRouteName);
  }

  get #dialogEnabled() {
    const component = this._modal.activeModal?.component;
    const route = normalizedRouteName(this._router.currentRouteName);

    if (get(this._dialog, "show") && CONFIRMATION_SCOPES.has(this.#scope?.id)) {
      return true;
    }

    if (matchesComponent(component, INVITE_DIALOGS)) {
      return (
        this.#scope?.id === "invitations" ||
        ["groups", "group", "group-manage"].includes(this.#scope?.id) ||
        route === "new-invite" ||
        route.startsWith("discovery.")
      );
    }

    if (this.#scope?.id === "preferences") {
      return matchesComponent(component, PREFERENCE_DIALOGS);
    }

    if (this.#scope?.id === "bookmarks") {
      return matchesComponent(component, BOOKMARK_DIALOGS);
    }

    if (this.#scope?.id === "drafts") {
      return matchesComponent(component, DRAFT_DIALOGS);
    }

    if (
      ["groups", "group", "group-manage", "group-messages"].includes(
        this.#scope?.id
      )
    ) {
      return matchesComponent(component, GROUP_DIALOGS);
    }

    return (
      this.#scope?.id === "directory" &&
      matchesComponent(component, DIRECTORY_DIALOGS)
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
      } else {
        classes.push("has-frontend-page");
      }
    }
    if (this.#dialogEnabled) {
      classes.push("has-frontend-dialog");
    }
    return classes.join(" ");
  }

  <template>{{bodyClass this.bodyClasses}}</template>
}
