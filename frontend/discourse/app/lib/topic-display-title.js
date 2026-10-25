import { applyValueTransformer } from "discourse/lib/transformer";

export default function topicDisplayTitle(title, resource = {}) {
  return applyValueTransformer("topic-display-title", title, { resource });
}
