import Component from "@glimmer/component";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import { i18n } from "discourse-i18n";

export default class AcademyActivityLevel extends Component {
  @service siteSettings;

  <template>
    {{#if this.siteSettings.academy_roles_enabled}}
      {{bodyClass "academy-roles-enabled"}}
      <span class="academy-activity-level" ...attributes>
        {{i18n
          "academy_roles.activity_level"
          level=@outletArgs.model.academy_activity_level
        }}
      </span>
      {{#if @outletArgs.model.academy_official_member}}
        <span class="academy-official-badge">
          {{i18n "academy_roles.official_badge"}}
        </span>
      {{/if}}
    {{/if}}
  </template>
}
