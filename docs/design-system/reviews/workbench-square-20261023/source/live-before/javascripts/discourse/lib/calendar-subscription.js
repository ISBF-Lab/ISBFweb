export const PERSONAL_CALENDAR_FEED = "isbf_personal";

export function calendarSubscriptionURL(url, origin, path) {
  if (!url) {
    return null;
  }
  try {
    const parsed = new URL(url);
    if (
      parsed.origin !== origin ||
      parsed.protocol !== "https:" ||
      parsed.pathname !== path ||
      parsed.username ||
      parsed.password ||
      parsed.hash ||
      !parsed.searchParams.get("user_api_key")
    ) {
      return null;
    }
    return parsed.href;
  } catch {
    return null;
  }
}

export function appleCalendarURL(url, origin, path) {
  return (
    calendarSubscriptionURL(url, origin, path)?.replace(/^https:/, "webcal:") ??
    null
  );
}
