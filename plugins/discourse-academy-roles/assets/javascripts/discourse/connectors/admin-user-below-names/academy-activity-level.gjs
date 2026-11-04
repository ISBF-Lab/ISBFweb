import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class AcademyAdminActivityLevel extends Component {
  @service siteSettings;

  <template>
    {{#if this.siteSettings.academy_roles_enabled}}
      <div class="display-row academy-admin-activity-level">
        <div class="field">{{i18n "academy_roles.activity_title"}}</div>
        <div class="value">
          {{#if @outletArgs.user.academy_activity_level_name}}
            {{i18n
              "academy_roles.activity_value_named"
              level=@outletArgs.user.academy_activity_level
              name=@outletArgs.user.academy_activity_level_name
            }}
          {{else}}
            {{i18n
              "academy_roles.activity_value"
              level=@outletArgs.user.academy_activity_level
            }}
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
