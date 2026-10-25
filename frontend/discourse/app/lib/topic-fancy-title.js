import { censor } from "pretty-text/censored-words";
import { emojiUnescape } from "discourse/lib/text";
import topicDisplayTitle from "discourse/lib/topic-display-title";
import { escapeExpression } from "discourse/lib/utilities";
import Site from "discourse/models/site";

export function fancyTitle(
  topicTitle,
  supportMixedTextDirection,
  resource = {}
) {
  const original = resource.title ?? resource.topic?.title ?? topicTitle;
  const displayed = topicDisplayTitle(original, resource);
  let title = censor(
    emojiUnescape(
      displayed === original ? topicTitle : escapeExpression(displayed)
    ) || "",
    Site.currentProp("censored_regexp")
  );

  if (supportMixedTextDirection) {
    return `<span dir="auto">${title}</span>`;
  }

  return title;
}
