import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "isbf-join-admin-nav",

  initialize(container) {
    if (!container.lookup("service:current-user")?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.setAdminPluginIcon("isbf-join", "user-group");
      api.addAdminPluginConfigurationNav("isbf-join", [
        {
          label: "isbf_join.admin.applications",
          route: "adminPlugins.show.isbf-join-applications",
          description: "isbf_join.admin.description",
        },
      ]);
    });
  },
};
