import { get } from "@ember/object";

export const PRIVATE_ROUTE = "user.profilePrivate";

/**
 * Whether the person viewing this profile is denied one of its sections.
 * The server lists only the sections hidden from the current viewer.
 *
 * @param {object} user - The profile owner as loaded for the viewer.
 * @param {"bio"|"summary"|"activity"} section
 * @returns {boolean}
 */
export function hidesSection(user, section) {
  return Boolean(
    get(user ?? {}, "isbf_hidden_profile_sections")?.includes(section)
  );
}

/**
 * The route to show instead of a section the viewer may not open, or null.
 *
 * @param {object} user
 * @param {"summary"|"activity"} section - The section being opened.
 * @param {boolean} activityTabDisabled - The site hides activity from other people.
 * @returns {string|null}
 */
export function fallbackRoute(user, section, activityTabDisabled) {
  if (get(user, "profile_hidden")) {
    return PRIVATE_ROUTE;
  }

  if (!hidesSection(user, section)) {
    return null;
  }

  if (section === "summary") {
    return hidesSection(user, "activity") || activityTabDisabled
      ? PRIVATE_ROUTE
      : "userActivity";
  }

  return hidesSection(user, "summary") ? PRIVATE_ROUTE : "user.summary";
}
