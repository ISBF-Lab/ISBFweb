import { action } from "@ember/object";
import { apiInitializer } from "discourse/lib/api";
import {
  openPostReport,
  rememberHiddenPost,
  severeReportAvailable,
} from "../lib/report-post";

export default apiInitializer((api) => {
  const appEvents = api.container.lookup("service:app-events");
  const siteSettings = api.container.lookup("service:site-settings");
  const site = api.container.lookup("service:site");
  const currentUser = api.container.lookup("service:current-user");
  const messageBus = api.container.lookup("service:message-bus");

  messageBus.subscribe("/isbf/moderation/posts", (message) => {
    if (typeof message.hidden === "boolean") {
      rememberHiddenPost(
        message.post_id,
        appEvents,
        message.hidden,
        message.hidden
      );
    }
  });

  api.registerValueTransformer(
    "flag-button-render-decision",
    ({ value, context }) =>
      value ||
      Boolean(
        currentUser && severeReportAvailable(context.post, siteSettings, site)
      )
  );

  api.modifyClass(
    "route:topic",
    (Superclass) =>
      class extends Superclass {
        @action
        showFlags(post) {
          if (
            !this.currentUser ||
            post.post_type !== 1 ||
            post.topic?.archetype === "private_message"
          ) {
            return super.showFlags(...arguments);
          }
          return openPostReport({
            post,
            modal: this.modal,
            siteSettings,
            site,
            appEvents,
          });
        }
      }
  );
});
