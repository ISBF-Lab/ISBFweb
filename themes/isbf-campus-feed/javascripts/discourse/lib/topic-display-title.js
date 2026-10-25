import { themePrefix } from "virtual:theme";
import { localizedTopicTitle } from "discourse/lib/topic-display-title";
import { i18n } from "discourse-i18n";
import { isUntitledTopicTitle } from "./optional-topic-title";
import { postPreview } from "./post-preview";

export function unavailableTitleContent(resource) {
  return Boolean(
    resource.hidden ||
    resource.deleted ||
    resource.deleted_at ||
    resource.topic?.hidden ||
    resource.topic?.deleted ||
    resource.topic?.deleted_at
  );
}

export default function topicDisplayTitle(title, resource = {}) {
  if (!isUntitledTopicTitle(title)) {
    return title;
  }

  const localized = localizedTopicTitle(resource);
  if (localized) {
    return postPreview(localized).text;
  }

  const loadedPost = resource.postStream?.posts?.find(
    (post) => post.post_number === 1
  );
  const unavailable =
    unavailableTitleContent(resource) ||
    (loadedPost && unavailableTitleContent(loadedPost));
  const body = unavailable
    ? ""
    : resource.cooked ||
      resource.expandedExcerpt?.toString() ||
      resource.excerpt ||
      resource.blurb ||
      resource.topic?.excerpt ||
      loadedPost?.cooked;
  const preview = postPreview(body);
  return (
    preview.text ||
    i18n(
      themePrefix(
        preview.images.length
          ? "isbf_v2.preview_picture"
          : "isbf_v2.preview_post"
      )
    )
  );
}
