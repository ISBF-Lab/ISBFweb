import { apiInitializer } from "discourse/lib/api";
import ISBFReplyNavigation from "../components/isbf-reply-navigation";
import solvedActionFor from "../components/isbf-solved-action";
import ISBFSolvedSummary from "../components/isbf-solved-summary";
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

const initializer = apiInitializer((api) => {
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
  api.renderAfterWrapperOutlet("post-content-cooked-html", ISBFSolvedSummary);

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

    const conversation = isConversationPost(
      context.post,
      router.currentURL,
      siteSettings
    );
    const { buttonKeys } = context;
    const primaryKeys = [
      buttonKeys.REPLY,
      buttonKeys.LIKE,
      buttonKeys.BOOKMARK,
      buttonKeys.SHOW_MORE,
    ];
    const entries = value.entries();
    const nativeSolved = siteSettings.solved_enabled
      ? entries.find(([key]) => key === "solved")
      : null;
    const SolvedAction =
      nativeSolved && !conversation ? solvedActionFor(nativeSolved[1]) : null;
    rememberSecondaryMenu(
      context.post,
      entries.filter(
        ([key]) =>
          !primaryKeys.includes(key) && !(SolvedAction && key === "solved")
      )
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
    if (SolvedAction) {
      value.add("solved", SolvedAction, { after: "isbfBookmark" });
    }
    value.add(buttonKeys.SHOW_MORE, ISBFTopicMore);
  });
});

initializer.after = ["inject-objects", "extend-for-solved-button"];

export default initializer;
