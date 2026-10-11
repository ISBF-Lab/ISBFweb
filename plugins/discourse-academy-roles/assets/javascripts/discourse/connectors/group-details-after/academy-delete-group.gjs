import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import GroupDeleteDialog from "discourse/components/dialog-messages/group-delete";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class AcademyDeleteGroup extends Component {
  @service currentUser;
  @service dialog;
  @service router;

  @tracked deleting = false;

  get canDelete() {
    return (
      !this.currentUser?.admin &&
      this.currentUser?.academy_moderator_permissions?.manage_groups &&
      this.args.outletArgs.model.can_admin_group &&
      !this.args.outletArgs.model.automatic
    );
  }

  @action
  confirmDelete() {
    const model = this.args.outletArgs.model;
    this.dialog.deleteConfirm({
      title: i18n("admin.groups.delete_confirm", { group: model.name }),
      bodyComponent: GroupDeleteDialog,
      bodyComponentModel: model,
      didConfirm: async () => {
        this.deleting = true;
        try {
          await model.destroy();
          this.router.transitionTo("groups.index");
        } catch (error) {
          popupAjaxError(error);
        } finally {
          this.deleting = false;
        }
      },
    });
  }

  <template>
    {{#if this.canDelete}}
      <DButton
        class="btn-danger"
        @action={{this.confirmDelete}}
        @disabled={{this.deleting}}
        @icon="trash-can"
        @label="admin.groups.delete"
      />
    {{/if}}
  </template>
}
