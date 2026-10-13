import CustomNotification from "discourse/lib/notification-types/custom";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "avatar-frame-notifications",

  initialize() {
    withPluginApi((api) => {
      api.registerNotificationTypeRenderer("custom", () => {
        return class extends CustomNotification {
          get isFrameGrant() {
            return this.notification.data.message === "avatar_frames.granted";
          }

          get linkHref() {
            return this.isFrameGrant
              ? "/my/preferences/profile"
              : super.linkHref;
          }

          get icon() {
            return this.isFrameGrant ? "award" : super.icon;
          }

          get label() {
            return this.isFrameGrant
              ? i18n("avatar_frames.granted_title")
              : super.label;
          }

          get description() {
            if (!this.isFrameGrant) {
              return super.description;
            }
            const data = this.notification.data;
            return i18n("avatar_frames.granted", {
              name: data.name_key ? i18n(data.name_key) : data.frame_name,
            });
          }

          get linkTitle() {
            return this.isFrameGrant
              ? i18n("avatar_frames.granted_title")
              : super.linkTitle;
          }
        };
      });

      if (api.getCurrentUser()?.admin) {
        api.setAdminPluginIcon("discourse-avatar-frames", "award");
        api.addAdminPluginConfigurationNav("discourse-avatar-frames", [
          {
            label: "avatar_frames.admin.frames",
            route: "adminPlugins.show.avatar-frames",
          },
        ]);
      }
    });
  },
};
