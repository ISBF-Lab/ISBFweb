import { apiInitializer } from "discourse/lib/api";
import UserMenuNotificationItem from "discourse/lib/user-menu/notification-item";
import { isFeedStylePost } from "../lib/topic-card-scope";
import { displayName, notificationDisplayLabel } from "../lib/user-display";

export default apiInitializer((api) => {
  const router = api.container.lookup("service:router");

  api.modifyClass("component:post/meta-data/poster-name", (Superclass) => {
    return class extends Superclass {
      get name() {
        return isFeedStylePost(this.args.post, router.currentURL)
          ? displayName(this.user)
          : super.name;
      }
    };
  });

  api.modifyClass("component:user-menu/menu-item", (Superclass) => {
    return class extends Superclass {
      get label() {
        return this.args.item instanceof UserMenuNotificationItem
          ? notificationDisplayLabel(this.args.item, super.label)
          : super.label;
      }
    };
  });
});
