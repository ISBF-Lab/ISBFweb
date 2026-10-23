import { apiInitializer } from "discourse/lib/api";
import CustomNotification from "discourse/lib/notification-types/custom";
import { i18n } from "discourse-i18n";
import ISBFOfficialCalendarItems from "../components/isbf-official-calendar-items";
import { isOfficialCalendarPost } from "../lib/official-topic-scope";

export default apiInitializer((api) => {
  const router = api.container.lookup("service:router");
  const site = api.container.lookup("service:site");
  api.registerValueTransformer("post-article-class", ({ value, context }) =>
    isOfficialCalendarPost(
      context.post,
      site,
      router.currentURL,
      context.state?.nestedReplyView
    )
      ? [...value, "isbf-official-topic-card"]
      : value
  );
  api.renderAfterWrapperOutlet(
    "post-content-cooked-html",
    ISBFOfficialCalendarItems
  );
  api.registerNotificationTypeRenderer(
    "custom",
    () =>
      class extends CustomNotification {
        get isCalendarChange() {
          return this.notification.data.message === "isbf_calendar.changed";
        }

        get description() {
          return this.isCalendarChange
            ? i18n("notifications.isbf_calendar.changed", {
                topic_title: this.notification.data.topic_title,
              })
            : super.description;
        }

        get icon() {
          return this.isCalendarChange ? "calendar-days" : super.icon;
        }

        get label() {
          return this.isCalendarChange ? null : super.label;
        }

        get linkHref() {
          return this.isCalendarChange
            ? `/isbf/calendar?entry_id=${encodeURIComponent(this.notification.data.entry_id)}`
            : super.linkHref;
        }

        get linkTitle() {
          return this.isCalendarChange ? this.description : super.linkTitle;
        }
      }
  );
});
