import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import ISBFActivityPreview from "../components/isbf-activity-preview";
import ISBFV2ComposerCancel from "../components/isbf-v2-composer-cancel";
import ISBFV2ComposerOptions from "../components/isbf-v2-composer-options";
import ISBFV2ComposerTitle from "../components/isbf-v2-composer-title";
import ISBFV2Shell from "../components/isbf-v2-shell";
import { canPublishAnonymously } from "../lib/anonymous-post-scope";
import { prepareOptionalTopicTitle } from "../lib/optional-topic-title";
import { isActivityPreview } from "../lib/post-preview";
import { isQuickPost } from "../lib/quick-post-scope";

function focusComposer() {
  document
    .querySelector(
      "#reply-control.open.composer-action-create-topic .d-editor-input"
    )
    ?.focus();
}

export default apiInitializer((api) => {
  api.modifyClass("controller:user", {
    pluginId: "isbf-ui-profile-expanded",
    forceExpand: true,
  });

  api.modifyClass(
    "component:post-list/item",
    (Superclass) =>
      class ISBFActivityPostListItem extends Superclass {
        @service router;

        get itemClasses() {
          return dConcatClass(
            super.itemClasses,
            this.args.additionalItemClasses === "user-stream-item" &&
              isActivityPreview(this.args.post, this.router.currentURL) &&
              "isbf-activity-item"
          );
        }
      }
  );
  api.renderInOutlet("user-stream-item-above", ISBFActivityPreview);

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
  api.renderInOutlet("composer-fields", ISBFV2ComposerTitle);

  api.customizeComposerText({
    titlePlaceholder: (model) =>
      isQuickPost(model) ? themePrefix("isbf_v2.optional_title") : null,
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
    const model = api.container.lookup("service:composer").model;
    if (isQuickPost(model)) {
      prepareOptionalTopicTitle(model);
    }
    scheduleOnce("afterRender", focusComposer);
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

  api.registerValueTransformer("topic-list-class", ({ value, context }) => {
    const listContext = context?.listContext;
    if (listContext !== "discovery" && listContext !== "suggested") {
      return value;
    }

    return [...value, "isbf-v2-topic-list", `--${listContext}`];
  });

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
