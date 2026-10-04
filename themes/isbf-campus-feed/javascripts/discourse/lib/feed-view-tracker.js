import { createViewTracker } from "./view-tracker";

export const recordVisibleView = createViewTracker(
  "/isbf/views/impressions",
  "topic_ids"
);

export const recordVisiblePostView = createViewTracker(
  "/isbf/views/post-impressions",
  "post_ids"
);
