import { apiInitializer } from "discourse/lib/api";
import ISBFReplyNavigation from "../components/isbf-reply-navigation";
import {
  ISBFTopicBookmark,
  ISBFTopicLike,
  ISBFTopicReply,
  ISBFTopicRepost,
} from "../components/isbf-topic-actions";
import ISBFTopicMetadata from "../components/isbf-topic-metadata";
import ISBFTopicMore from "../components/isbf-topic-more";
import ISBFTopicViews from "../components/isbf-topic-views";
import {
  isConversationPost,
  isFeedStylePost,
  isFeedStyleTopic,
  rememberSecondaryMenu,
} from "../lib/topic-card-scope";

export default apiInitializer((api) => {
  const router = api.container.lookup("service:router");
  const siteSettings = api.container.lookup("service:site-settings");
  api.renderInOutlet("post-metadata", ISBFTopicMetadata);
  api.renderInOutlet("nested-topic-navigation", ISBFReplyNavigation);
  api.registerValueTransformer("post-meta-data-infos", ({ value, context }) => {
    if (isConversationPost(context.post, router.currentURL, siteSettings)) {
      value.delete(context.metaDataInfoKeys.REPLY_TO_TAB);
    }
    return value;
  });

  for (const [name, className] of [
    ["post-class", "isbf-topic-card"],
    ["post-article-class", "isbf-topic-card__article"],
  ]) {
    api.registerValueTransformer(name, ({ value, context }) =>
      isFeedStylePost(
        context.post,
        router.currentURL,
        context.state?.nestedReplyView
      )
        ? [...value, className]
        : value
    );
  }

  api.registerValueTransformer("post-show-topic-map", ({ value, context }) =>
    isFeedStylePost(
      context.post,
      router.currentURL,
      context.state?.nestedReplyView
    )
      ? false
      : value
  );
  api.registerValueTransformer(
    "topic-show-footer-buttons",
    ({ value, context }) =>
      isFeedStyleTopic(context.topic, router.currentURL) ? false : value
  );

  api.registerValueTransformer("post-menu-buttons", ({ value, context }) => {
    if (
      !isFeedStylePost(
        context.post,
        router.currentURL,
        context.state.nestedReplyView
      ) &&
      !isConversationPost(context.post, router.currentURL, siteSettings)
    ) {
      return;
    }

    const { buttonKeys } = context;
    const primaryKeys = [
      buttonKeys.REPLY,
      buttonKeys.LIKE,
      buttonKeys.BOOKMARK,
      buttonKeys.SHOW_MORE,
    ];
    const entries = value.entries();
    rememberSecondaryMenu(
      context.post,
      entries.filter(([key]) => !primaryKeys.includes(key))
    );
    entries.forEach(([key]) => value.delete(key));

    value.add("isbfReply", ISBFTopicReply, { before: "isbfRepost" });
    value.add("isbfRepost", ISBFTopicRepost, {
      after: "isbfReply",
      before: "isbfLike",
    });
    value.add("isbfLike", ISBFTopicLike, {
      after: "isbfRepost",
      before: "isbfViews",
    });
    value.add("isbfViews", ISBFTopicViews, {
      after: "isbfLike",
      before: "isbfBookmark",
    });
    value.add("isbfBookmark", ISBFTopicBookmark, { after: "isbfViews" });
    value.add(buttonKeys.SHOW_MORE, ISBFTopicMore);
  });
});
