import { withPluginApi } from "discourse/lib/plugin-api";
import User from "discourse/models/user";
import { i18n } from "discourse-i18n";
import {
  NAME_COLOR,
  NAME_COLOR_ENABLED,
  validNameColor,
} from "../lib/name-color";

export default {
  name: "academy-name-color",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => {
      api.addSaveableCustomFields("interface");
      const originalSave = User.prototype.save;

      api.addModelMethod("user", "save", function (fields) {
        const color = this.custom_fields?.[NAME_COLOR];
        if (
          api.container.lookup("service:site-settings").academy_roles_enabled &&
          (!fields || fields.includes("custom_fields")) &&
          !validNameColor(color)
        ) {
          return Promise.reject({
            jqXHR: {
              responseJSON: {
                errors: [i18n("academy_roles.name_color.invalid_color")],
              },
            },
          });
        }

        const currentUser = api.getCurrentUser();
        const userId = this.id;
        return originalSave.call(this, fields).then((result) => {
          const saved = result.user;
          const appearance = {};
          for (const key of [
            "academy_display_name_color",
            "academy_can_wear_name_color",
            "academy_can_customize_name_color",
          ]) {
            if (Object.hasOwn(saved, key)) {
              appearance[key] = saved[key];
            }
          }
          this.setProperties(appearance);
          if (
            userId === currentUser?.id &&
            api.getCurrentUser() === currentUser
          ) {
            currentUser.setProperties(appearance);
          }
          if (saved.academy_name_color_preferences) {
            const preferences = saved.academy_name_color_preferences;
            this.set("academy_name_color_preferences", preferences);
            if (saved.academy_can_wear_name_color !== false) {
              this.set("custom_fields", {
                ...this.custom_fields,
                [NAME_COLOR_ENABLED]: preferences.enabled,
                [NAME_COLOR]: preferences.color,
              });
            }
          }
          return result;
        });
      });
    });
  },
};
