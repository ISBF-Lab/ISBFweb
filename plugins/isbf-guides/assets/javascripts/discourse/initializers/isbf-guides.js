import cookie from "discourse/lib/cookie";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "isbf-guides",

  initialize(container) {
    withPluginApi((api) => {
      api.onPageChange((url) => {
        if (!url.startsWith("/login")) {
          return;
        }
        const saved = window.sessionStorage.getItem("isbf-guides-return");
        const value = saved || cookie("destination_url");
        if (value) {
          const destination = new URL(value, window.location.origin);
          if (
            destination.origin === window.location.origin &&
            /^\/guides(?:\/|$)/.test(destination.pathname)
          ) {
            const fragment = destination.hash || window.location.hash;
            cookie(
              "destination_url",
              destination.pathname + destination.search + fragment
            );
          }
        }
        window.sessionStorage.removeItem("isbf-guides-return");
      });
      if (!container.lookup("service:current-user")?.admin) {
        return;
      }
      api.setAdminPluginIcon("isbf-guides", "book-open");
      api.addAdminPluginConfigurationNav("isbf-guides", [
        {
          label: "isbf_guides.admin.title",
          route: "adminPlugins.show.isbf-guides-guides.index",
          description: "isbf_guides.admin.description",
        },
      ]);
    });
  },
};
