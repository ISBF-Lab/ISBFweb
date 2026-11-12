import { computed } from "@ember/object";
import { apiInitializer } from "discourse/lib/api";
import {
  fallbackRoute,
  hidesSection,
  PRIVATE_ROUTE,
} from "../lib/profile-visibility";

function redirectHiddenSection(route, section) {
  const target = fallbackRoute(
    route.modelFor("user"),
    section,
    route.siteSettings.hide_user_activity_tab
  );
  return target ? route.router.replaceWith(target) : null;
}

export default apiInitializer((api) => {
  if (
    !api.container.lookup("service:site-settings")
      .isbf_profile_visibility_enabled
  ) {
    return;
  }

  api.modifyClass(
    "controller:user",
    (Superclass) =>
      class extends Superclass {
        @computed("model.isbf_hidden_profile_sections")
        get showSummaryTab() {
          return !hidesSection(this.model, "summary");
        }

        @computed(
          "viewingSelf",
          "currentUser.admin",
          "model.isbf_hidden_profile_sections"
        )
        get showActivityTab() {
          if (hidesSection(this.model, "activity")) {
            return false;
          }

          return (
            this.viewingSelf ||
            this.currentUser?.admin ||
            !this.siteSettings.hide_user_activity_tab
          );
        }

        /**
         * The route where other people see the expanded header. It follows
         * the same fallback as the summary and activity routes, so a public
         * bio stays reachable when the summary is hidden.
         */
        @computed(
          "router.currentRouteName",
          "showSummaryTab",
          "showActivityTab"
        )
        get isProfileLandingRoute() {
          const routeName = this.router?.currentRouteName;

          if (this.showSummaryTab) {
            return routeName === "user.summary";
          }

          return this.showActivityTab
            ? Boolean(routeName?.startsWith("userActivity"))
            : routeName === PRIVATE_ROUTE;
        }

        @computed(
          "model.profile_hidden",
          "isProfileLandingRoute",
          "viewingSelf",
          "forceExpand"
        )
        get collapsedInfo() {
          // A theme that always expands the header has no design for the collapsed one.
          if (this.model?.profile_hidden && !this.forceExpand) {
            return true;
          }

          return (
            (!this.isProfileLandingRoute || this.viewingSelf) &&
            !this.forceExpand
          );
        }
      }
  );

  api.modifyClass(
    "route:user.summary",
    (Superclass) =>
      class extends Superclass {
        model() {
          return (
            redirectHiddenSection(this, "summary") ?? super.model(...arguments)
          );
        }
      }
  );

  api.modifyClass(
    "route:user-activity",
    (Superclass) =>
      class extends Superclass {
        model() {
          return (
            redirectHiddenSection(this, "activity") ?? super.model(...arguments)
          );
        }
      }
  );
});
