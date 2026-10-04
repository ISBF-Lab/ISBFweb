import { apiInitializer } from "discourse/lib/api";
import { setInitialNotificationTab } from "../lib/notification-groups";

export default apiInitializer((api) => {
  const router = api.container.lookup("service:router");
  const siteSettings = api.container.lookup("service:site-settings");
  const currentUser = api.container.lookup("service:current-user");
  const appEvents = api.container.lookup("service:app-events");

  router.on("routeWillChange", (transition) => {
    const name = transition.to?.name;
    if (
      !siteSettings.isbf_notifications_enabled ||
      !currentUser ||
      !name?.startsWith("userNotifications.") ||
      name === "userNotifications.index"
    ) {
      return;
    }
    const userRoute = transition.to.find((route) =>
      Boolean(route.params.username)
    );
    const username = userRoute?.params.username;
    if (username?.toLowerCase() !== currentUser.username.toLowerCase()) {
      return;
    }
    const child = name.split(".").pop();
    const tab = ["mentions", "responses", "reactionsReceived"].includes(child)
      ? "mentions"
      : "all";
    setInitialNotificationTab(tab);
    appEvents.trigger("isbf:notification-tab", tab);
    transition.abort();
    router.replaceWith(`/u/${encodeURIComponent(username)}/notifications`);
  });

  api.modifyClass("route:user-notifications", {
    pluginId: "isbf-notification-groups",

    model() {
      const username = this.modelFor("user").get("username");
      if (
        siteSettings.isbf_notifications_enabled &&
        currentUser?.username?.toLowerCase() === username.toLowerCase()
      ) {
        return {
          content: [],
          loading: false,
          loadingMore: false,
          loadMore() {},
        };
      }
      return this._super(...arguments);
    },
  });
});
