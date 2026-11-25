import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "isbf-moderation-admin-plugin-configuration-nav",

  initialize(container) {
    if (!container.lookup("service:current-user")?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.addAdminPluginConfigurationNav("isbf-moderation", [
        {
          label: "isbf_moderation.admin.modes.title",
          route: "adminPlugins.show.isbf-moderation-modes",
          description: "isbf_moderation.admin.modes.description",
        },
      ]);
    });
  },
};
