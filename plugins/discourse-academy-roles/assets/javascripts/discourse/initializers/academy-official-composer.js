import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "academy-official-composer",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.academy_roles_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.serializeOnCreate("academy_official", "academyOfficial");
      api.serializeToDraft("academy_official", "academyOfficial");
    });
  },
};
