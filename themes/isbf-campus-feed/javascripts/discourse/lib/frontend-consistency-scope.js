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

export function normalizedRouteName(routeName = "") {
  return (routeName ?? "").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
}

export function frontendConsistencyScope(routeName) {
  const name = normalizedRouteName(routeName);
  const [parent, child] = name.split(".");

  if (parent === "preferences" && PREFERENCES.has(child)) {
    return { id: "preferences", layout: "feature", userContent: true };
  }

  if (name === "users" || name === "users.index") {
    return { id: "directory", layout: "feature", userContent: false };
  }

  if (name === "user-invited.index" || name === "user-invited.show") {
    return { id: "invitations", layout: "feature", userContent: true };
  }

  return null;
}
