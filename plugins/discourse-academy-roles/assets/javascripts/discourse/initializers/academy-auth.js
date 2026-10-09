import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "academy-auth",

  initialize() {
    withPluginApi((api) => {
      const extendSignup = Object.assign(
        (Base) =>
          class extends Base {
            beforeModel(transition) {
              if (
                this.siteSettings.academy_roles_enabled &&
                this.siteSettings.academy_auth_page_enabled &&
                !this.currentUser &&
                !document.getElementById("data-authentication")
              ) {
                return this.router.replaceWith("login", {
                  queryParams: { mode: "register" },
                });
              }
              return super.beforeModel(transition);
            }
          },
        { pluginId: "discourse-academy-roles-auth" }
      );
      api.modifyClass("route:signup", extendSignup);
    });
  },
};
