import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_ID = "isbf-account-switch";

export default {
  name: "isbf-account-switch-admin-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.setAdminPluginIcon(PLUGIN_ID, "users");
      api.addAdminPluginConfigurationNav(PLUGIN_ID, [
        {
          label: "isbf_account_switch.admin.nav",
          route: "adminPlugins.show.isbf-account-switch-links",
          description: "isbf_account_switch.admin.description",
        },
      ]);
    });
  },
};
