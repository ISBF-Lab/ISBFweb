import Component from "@glimmer/component";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import { i18n } from "discourse-i18n";

export default class AcademyActivityLevel extends Component {
  @service siteSettings;

  // A hidden profile is served without the level, and level 0 is a real level.
  get hasLevel() {
    const level = this.args.outletArgs.model.academy_activity_level;
    return level !== undefined && level !== null;
  }

  <template>
    {{#if this.siteSettings.academy_roles_enabled}}
      {{bodyClass "academy-roles-enabled"}}
      {{#if this.hasLevel}}
        <span class="academy-activity-level" ...attributes>
          {{#if @outletArgs.model.academy_activity_level_name}}
            {{i18n
              "academy_roles.activity_level_named"
              level=@outletArgs.model.academy_activity_level
              name=@outletArgs.model.academy_activity_level_name
            }}
          {{else}}
            {{i18n
              "academy_roles.activity_level"
              level=@outletArgs.model.academy_activity_level
            }}
          {{/if}}
        </span>
      {{/if}}
      {{#if @outletArgs.model.academy_official_member}}
        <span class="academy-official-badge">
          {{i18n "academy_roles.official_badge"}}
        </span>
      {{/if}}
    {{/if}}
  </template>
}
