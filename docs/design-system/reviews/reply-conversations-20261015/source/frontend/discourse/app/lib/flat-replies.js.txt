export function flatRepliesEnabled(siteSettings) {
  return (
    siteSettings.nested_replies_enabled &&
    siteSettings.nested_replies_cap_nesting_depth &&
    siteSettings.nested_replies_max_depth === 1
  );
}

export const REPLY_PREVIEW_COUNT = 3;
export const CHILDREN_PAGE_SIZE = 50;
