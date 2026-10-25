import getUrl from "discourse/lib/get-url";
import NotificationTypeBase from "discourse/lib/notification-types/base";
import topicDisplayTitle from "discourse/lib/topic-display-title";
import { i18n } from "discourse-i18n";

export default class extends NotificationTypeBase {
  get linkTitle() {
    if (this.notification.data.bookmark_name) {
      return i18n("notifications.titles.bookmark_reminder_with_name", {
        name: this.notification.data.bookmark_name,
      });
    }
    return super.linkTitle;
  }

  get description() {
    return (
      super.description ||
      topicDisplayTitle(this.notification.data.title, this.notification)
    );
  }

  get label() {
    return null;
  }

  get linkHref() {
    let linkHref = super.linkHref;
    if (linkHref) {
      return linkHref;
    }
    if (this.notification.data.bookmarkable_url) {
      return getUrl(this.notification.data.bookmarkable_url);
    }
  }
}
