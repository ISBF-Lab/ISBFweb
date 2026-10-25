import { get } from "@ember/object";
import { applyValueTransformer } from "discourse/lib/transformer";

export function localizedTopicTitle(resource = {}) {
  const topic = resource?.topic ?? resource;
  const title = topic && get(topic, "fancy_title");
  return topic &&
    get(topic, "fancy_title_localized") &&
    typeof title === "string" &&
    title.trim()
    ? title
    : null;
}

export default function topicDisplayTitle(title, resource = {}) {
  return applyValueTransformer("topic-display-title", title, { resource });
}
