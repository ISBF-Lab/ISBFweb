import { get } from "@ember/object";
import { i18n } from "discourse-i18n";

export function displayName(user) {
  return user?.name?.trim() ? user.name : user?.username;
}

export function feedAuthorColor(user, currentUser) {
  const source =
    user?.id === currentUser?.id &&
    currentUser &&
    get(currentUser, "academy_display_name_color") !== undefined
      ? currentUser
      : user;
  const color = source && get(source, "academy_display_name_color");
  if (color === "theme") {
    return "var(--isbf-v2-accent)";
  }
  return typeof color === "string" &&
    color.length <= 128 &&
    color.trim() === color &&
    (/^#[0-9a-f]{6}$/i.test(color) ||
      /^linear-gradient\((?:90|180)deg, #[0-9a-f]{6}(?:, #[0-9a-f]{6}){1,9}\)$/i.test(
        color
      ))
    ? color
    : null;
}

export function feedAuthorStyle(user, currentUser) {
  const color = feedAuthorColor(user, currentUser);
  if (!color) {
    return null;
  }
  if (color.startsWith("linear-gradient(")) {
    return `--isbf-feed-author-color: ${color.match(/#[0-9a-f]{6}/i)[0]}; --isbf-feed-author-gradient: ${color};`;
  }
  return `--isbf-feed-author-color: ${color};`;
}

export function displayIdentity(user) {
  return user?.name?.trim() && user.username
    ? `${user.name} @${user.username}`
    : displayName(user);
}

export function notificationDisplayLabel(item, fallback) {
  const notification = item.notification;
  const data = notification.data;
  const director = item.renderDirector;
  const type = director.notificationName;

  if (
    !fallback ||
    !data.display_username ||
    (type === "replied" &&
      data.reply_to_post_number != null &&
      data.consolidated_count > 1)
  ) {
    return fallback;
  }

  const name = item.siteSettings.enable_names
    ? (notification.acting_user_name ?? data.display_name)
    : null;
  const actor = displayIdentity({ name, username: data.display_username });

  if (type === "liked" || type === "reaction") {
    const count = Number(data.count) || 1;
    const multipleActors = type === "liked" || Boolean(data.username2);

    if (multipleActors && count > 2) {
      return i18n(
        type === "liked"
          ? "notifications.liked_by_multiple_users"
          : "notifications.reaction_multiple_users",
        { username: actor, count: count - 1 }
      );
    }

    if (multipleActors && count === 2 && data.username2) {
      return i18n(
        type === "liked"
          ? "notifications.liked_by_2_users"
          : "notifications.reaction_2_users",
        {
          username: actor,
          username2: displayIdentity({
            name: item.siteSettings.enable_names ? data.name2 : null,
            username: data.username2,
          }),
        }
      );
    }

    return actor;
  }

  if (type === "group_mentioned") {
    return `${actor} @${data.group_name}`;
  }

  if (type === "moved_post") {
    return i18n("notifications.user_moved_post", { username: actor });
  }

  return [
    director.username,
    notification.acting_user_name,
    data.display_name,
  ].includes(fallback)
    ? actor
    : fallback;
}
