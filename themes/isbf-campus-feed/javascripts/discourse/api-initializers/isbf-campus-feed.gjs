import { scheduleOnce } from "@ember/runloop";
import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";
import ISBFV2ComposerCancel from "../components/isbf-v2-composer-cancel";
import ISBFV2ComposerOptions from "../components/isbf-v2-composer-options";
import ISBFV2Shell from "../components/isbf-v2-shell";
import { canPublishAnonymously } from "../lib/anonymous-post-scope";
import { isQuickPost } from "../lib/quick-post-scope";
import { quickPostText, quickPostTitle } from "../lib/quick-post-title";

function syncQuickPostTitle(model) {
  if (!isQuickPost(model)) {
    return;
  }

  const title = quickPostTitle(
    model.reply,
    model.minimumTitleLength,
    model.siteSettings.max_topic_title_length
  );

  if (
    model.isbf_repost_source_topic_id &&
    !quickPostText(model.reply) &&
    model.title
  ) {
    return;
  }

  if (model.title !== title) {
    model.set("title", title);
  }
}

function focusComposerInput() {
  document
    .querySelector(
      "#reply-control.open.composer-action-create-topic .d-editor-input"
    )
    ?.focus();
}

export default apiInitializer((api) => {
  Composer.serializeOnCreate(
    "isbf_repost_source_topic_id",
    "isbf_repost_source_topic_id"
  );
  Composer.serializeToDraft(
    "isbf_repost_source_topic_id",
    "isbf_repost_source_topic_id"
  );
  Composer.serializeOnCreate("isbf_anonymous", "isbf_anonymous");
  Composer.serializeToDraft("isbf_anonymous", "isbf_anonymous");
  api.renderInOutlet("before-main-outlet", ISBFV2Shell);
  api.renderInOutlet("before-composer-controls", ISBFV2ComposerCancel);
  api.renderInOutlet("before-composer-fields", ISBFV2ComposerOptions);

  api.customizeComposerText({
    actionTitle: (model) =>
      isQuickPost(model) ? i18n(themePrefix("isbf_v2.quick_post")) : null,
    saveLabel: (model) =>
      isQuickPost(model) ? themePrefix("isbf_v2.compose") : null,
  });

  api.onAppEvent("composer:category-changed", (model) => {
    if (
      model.isbf_anonymous &&
      !canPublishAnonymously(
        model,
        api.container.lookup("service:current-user"),
        api.container.lookup("service:site-settings")
      )
    ) {
      model.set("isbf_anonymous", false);
    }
  });

  api.onAppEvent("composer:opened", () => {
    scheduleOnce("afterRender", null, focusComposerInput);
  });

  api.registerValueTransformer(
    "composer-editor-reply-placeholder",
    ({ value, context }) => {
      const model = context?.model?.model;
      return isQuickPost(model) && !model.requiredCategoryMissing
        ? themePrefix("isbf_v2.compose_prompt")
        : value;
    }
  );

  api.registerValueTransformer(
    "composer-service-cannot-submit-post",
    ({ value, context }) => {
      const model = context?.model;
      if (!isQuickPost(model)) {
        return value;
      }

      syncQuickPostTitle(model);
      return model.cantSubmitPost;
    }
  );

  // Discourse's own mobile topic renderer already has an avatar, title,
  // excerpt, categories, tags, reply count and activity time.
  api.registerValueTransformer(
    "topic-list-item-mobile-layout",
    ({ value, context }) =>
      context?.listContext === "discovery" ? true : value
  );

  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value, context }) => {
      if (context?.listContext !== "discovery") {
        return value;
      }

      return value.includes("isbf-v2-topic")
        ? value
        : [...value, "isbf-v2-topic"];
    }
  );

  api.registerValueTransformer(
    "topic-list-item-expand-pinned",
    ({ value, context }) =>
      context?.listContext === "discovery" ? true : value
  );
});
