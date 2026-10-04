export function notificationsEnabled(path, currentUser, siteSettings) {
  if (!currentUser || !siteSettings.isbf_notifications_enabled) {
    return false;
  }
  const match = path
    .split("?")[0]
    .match(/^\/u\/([^/]+)\/notifications(?:\/|$)/);
  return Boolean(
    match &&
    decodeURIComponent(match[1]).toLowerCase() ===
      currentUser.username.toLowerCase()
  );
}

export function mergeEntries(existing, incoming) {
  const entries = new Map(existing.map((entry) => [entry.key, entry]));
  for (const entry of incoming) {
    if (!entries.has(entry.key)) {
      entries.set(entry.key, entry);
    }
  }
  return [...entries.values()];
}

let initialTab = "all";

export function setInitialNotificationTab(tab) {
  initialTab = tab;
}

export function consumeInitialNotificationTab() {
  const tab = initialTab;
  initialTab = "all";
  return tab;
}
