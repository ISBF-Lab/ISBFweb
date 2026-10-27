import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class AcademyStudentInvitesPage extends Component {
  @service currentUser;

  <template>
    {{#if this.currentUser.admin}}<LinkTo
        @route="adminPlugins.show.academy-student-group-batches"
      >{{i18n "academy_roles.student_groups.title"}}</LinkTo>{{/if}}
    {{outlet}}
  </template>
}
