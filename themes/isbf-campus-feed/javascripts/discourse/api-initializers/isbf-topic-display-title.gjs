import { apiInitializer } from "discourse/lib/api";
import ISBFOptionalTopicTitleEditor from "../components/isbf-optional-topic-title-editor";
import ISBFTopicLinkTitle from "../components/isbf-topic-link-title";
import topicDisplayTitle from "../lib/topic-display-title";

export default apiInitializer((api) => {
  api.registerValueTransformer("topic-display-title", ({ value, context }) =>
    topicDisplayTitle(value, context.resource)
  );
  api.renderInOutlet("topic-link-title", ISBFTopicLinkTitle);
  api.renderInOutlet("edit-topic-title", ISBFOptionalTopicTitleEditor);
});
