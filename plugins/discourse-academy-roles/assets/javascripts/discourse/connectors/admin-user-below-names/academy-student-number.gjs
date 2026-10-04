import Component from "@glimmer/component";
import { service } from "@ember/service";
import { and } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class AcademyStudentNumber extends Component {
  @service currentUser;
  @service siteSettings;

  <template>
    {{#if (and this.currentUser.admin this.siteSettings.academy_roles_enabled)}}
      <div class="display-row academy-student-number" ...attributes>
        <div class="field">{{i18n "academy_roles.student_number"}}</div>
        <div class="value">
          {{#if @outletArgs.user.academy_student_number}}
            {{@outletArgs.user.academy_student_number}}
          {{else}}
            {{i18n "academy_roles.student_invites.unbound"}}
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
