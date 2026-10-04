import Composer from "discourse/models/composer";
import {
  isUntitledTopicTitle,
  optionalTopicTitle,
} from "./optional-topic-title";

export function plainText(html) {
  const element = document.createElement("div");
  element.innerHTML = html ?? "";
  return element.textContent?.replace(/\s+/g, " ").trim() ?? "";
}

export function compactNumber(value) {
  const count = Number(value) || 0;
  return count
    ? new Intl.NumberFormat(undefined, { notation: "compact" }).format(count)
    : "";
}

export function postCardTitle(title, cookedHtml) {
  if (cookedHtml === null || cookedHtml === undefined) {
    return null;
  }
  const normalizedTitle = title?.replace(/\s+/g, " ").trim();
  const body = plainText(cookedHtml);
  if (
    !normalizedTitle ||
    isUntitledTopicTitle(normalizedTitle) ||
    (body &&
      (body.startsWith(normalizedTitle) ||
        normalizedTitle.startsWith(body.slice(0, 80))))
  ) {
    return null;
  }
  return normalizedTitle;
}

export async function openQuotedRepost({
  composer,
  router,
  currentUser,
  topicId,
  postNumber,
  username,
  cookedHtml,
  title,
}) {
  if (!currentUser) {
    router.transitionTo("login");
    return false;
  }

  const sourceText = plainText(cookedHtml).slice(0, 500);
  const body = `[quote="${username}, post:${postNumber}, topic:${topicId}"]\n${sourceText}\n[/quote]\n\n`;
  const previousModel = composer.model;
  const previousDraftKey = previousModel?.draftKey;
  await composer.openNewTopic({ body, title: optionalTopicTitle(title) });

  // Native openNewTopic returns undefined on both success and draft cancellation.
  const model = composer.model;
  if (
    !model ||
    model.action !== Composer.CREATE_TOPIC ||
    model.composeState !== Composer.OPEN ||
    !model.draftKey ||
    (model === previousModel && model.draftKey === previousDraftKey) ||
    model.reply !== body
  ) {
    return false;
  }

  model.set("isbf_repost_source_topic_id", topicId);
  return true;
}
