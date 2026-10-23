import { isFeedStylePost } from "./topic-card-scope";

export function isOfficialCalendarPost(
  post,
  site,
  path,
  nestedReplyView = false
) {
  const categoryId = Number(
    site?.isbf_official?.category_id ??
      site?.isbf_calendar?.official_category_id
  );
  return Boolean(
    Number.isSafeInteger(categoryId) &&
    categoryId > 0 &&
    post?.post_number === 1 &&
    Number(post.topic?.category_id ?? post.topic?.categoryId) === categoryId &&
    isFeedStylePost(post, path, nestedReplyView)
  );
}
