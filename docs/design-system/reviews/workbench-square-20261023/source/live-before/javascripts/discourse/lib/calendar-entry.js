import { themePrefix } from "virtual:theme";
import I18n, { i18n } from "discourse-i18n";

export function calendarEntryKind(entry) {
  return entry.source_item_id ? "official" : "personal";
}

export function calendarEntryTime(entry) {
  if (entry.all_day) {
    return i18n(themePrefix("isbf_v2.calendar_all_day"));
  }
  const locale = I18n.currentLocale().replace("_", "-");
  const timeZone = entry.source_item_id ? "Asia/Shanghai" : undefined;
  const clock = new Intl.DateTimeFormat(locale, {
    hour: "2-digit",
    minute: "2-digit",
    timeZone,
  });
  const day = new Intl.DateTimeFormat(locale, {
    month: "numeric",
    day: "numeric",
    timeZone,
  });
  const start = new Date(entry.starts_at);
  const end = new Date(entry.ends_at);
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
    return "";
  }
  if (end <= start) {
    return clock.format(start);
  }
  const fullDay = new Intl.DateTimeFormat(locale, {
    year: "numeric",
    month: "numeric",
    day: "numeric",
    timeZone,
  });
  return fullDay.format(start) === fullDay.format(end)
    ? `${clock.format(start)}–${clock.format(end)}`
    : `${day.format(start)} ${clock.format(start)}–${day.format(end)} ${clock.format(end)}`;
}
