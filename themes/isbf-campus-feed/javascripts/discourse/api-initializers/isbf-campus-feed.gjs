import { scheduleOnce } from "@ember/runloop";
import { settings, themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import ISBFV2Shell from "../components/isbf-v2-shell";
import { quickPostTitle } from "../lib/quick-post-title";

function isQuickPost(model) {
  return (
    model?.action === "createTopic" &&
    !model.creatingEvent &&
    Number(model.categoryId) !== Number(settings.calendar_category_id) &&
    Boolean(document.querySelector(".isbf-v2-shell"))
  );
}

function syncQuickPostTitle(model) {
  if (!isQuickPost(model)) {
    return;
  }

  const title = quickPostTitle(
    model.reply,
    model.minimumTitleLength,
    model.siteSettings.max_topic_title_length
  );

  if (model.title !== title) {
    model.set("title", title);
  }
}

export default apiInitializer((api) => {
  api.renderInOutlet("before-main-outlet", ISBFV2Shell);
  const composer = api.container.lookup("service:composer");

  function applyEventComposerClass(model) {
    document
      .querySelector("#reply-control")
      ?.classList.toggle(
        "isbf-event-composer",
        Number(model?.categoryId) === Number(settings.calendar_category_id) &&
          Number(settings.calendar_category_id) > 0
      );
  }

  function syncEventComposerClass(model) {
    scheduleOnce("afterRender", null, applyEventComposerClass, model);
  }

  function focusComposerInput() {
    document
      .querySelector(
        "#reply-control.open.composer-action-create-topic .d-editor-input"
      )
      ?.focus();
  }

  api.customizeComposerText({
    actionTitle: (model) =>
      isQuickPost(model) ? i18n(themePrefix("isbf_v2.quick_post")) : null,
    saveLabel: (model) =>
      isQuickPost(model) ? themePrefix("isbf_v2.compose") : null,
  });

  api.onAppEvent("composer:opened", () => {
    syncEventComposerClass(composer.model);
    scheduleOnce("afterRender", null, focusComposerInput);
  });

  api.onAppEvent("composer:category-changed", syncEventComposerClass);

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
