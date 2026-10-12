const PREFERENCES = new Set([
  "account",
  "security",
  "profile",
  "emails",
  "notifications",
  "tracking",
  "users",
  "tags",
  "interface",
  "apps",
  "navigation-menu",
  "calendar-subscriptions",
  "email",
  "second-factor",
]);

const PRIVATE_MESSAGES = new Set([
  "user-private-messages.user.index",
  "user-private-messages.user.new",
  "user-private-messages.user.unread",
  "user-private-messages.user.archive",
  "user-private-messages.user.sent",
  "user-private-messages.user.warnings",
  "user-private-messages.group.index",
  "user-private-messages.group.new",
  "user-private-messages.group.unread",
  "user-private-messages.group.archive",
  "user-private-messages.tags.index",
  "user-private-messages.tags.show",
]);

const USER_CONTENT = new Map([
  ["user-activity.bookmarks", "bookmarks"],
  ["user-activity.bookmarks-with-reminders", "bookmarks"],
  ["user-activity.drafts", "drafts"],
  ["user-activity.pending", "pending"],
  ["user.summary", "profile-summary"],
  ["user.badges", "profile-badges"],
  ["user.deleted-posts", "deleted-posts"],
  ["user.profile-hidden", "profile-hidden"],
]);

export function normalizedRouteName(routeName = "") {
  return (routeName ?? "").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
}

export function frontendConsistencyScope(routeName) {
  const name = normalizedRouteName(routeName);
  const [parent, child] = name.split(".");

  if (
    parent === "preferences" &&
    PREFERENCES.has(child) &&
    name === `${parent}.${child}`
  ) {
    return { id: "preferences", layout: "feature", userContent: true };
  }

  if (name === "users" || name === "users.index") {
    return { id: "directory", layout: "feature", userContent: false };
  }

  if (name === "user-invited.index" || name === "user-invited.show") {
    return { id: "invitations", layout: "feature", userContent: true };
  }

  if (USER_CONTENT.has(name)) {
    return { id: USER_CONTENT.get(name), layout: "feed", userContent: true };
  }

  if (PRIVATE_MESSAGES.has(name)) {
    return { id: "messages", layout: "feed", userContent: true };
  }

  if (name === "badges.index" || name === "badges.show") {
    return { id: "badges", layout: "feed", userContent: false };
  }

  return null;
}
