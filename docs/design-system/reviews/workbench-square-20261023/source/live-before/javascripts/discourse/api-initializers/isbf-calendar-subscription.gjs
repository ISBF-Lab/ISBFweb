import { apiInitializer } from "discourse/lib/api";
import ISBFCalendarSubscriptionFeed from "../components/isbf-calendar-subscription-feed";

export default apiInitializer((api) => {
  api.renderInOutlet(
    "calendar-subscriptions-feeds",
    ISBFCalendarSubscriptionFeed
  );
});
