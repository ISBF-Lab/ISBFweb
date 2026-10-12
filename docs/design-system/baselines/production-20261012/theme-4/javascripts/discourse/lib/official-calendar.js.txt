import { themePrefix } from "virtual:theme";
import I18n, { i18n } from "discourse-i18n";

export const OFFICIAL_CALENDAR_FIELD = "isbf_official_calendar_items";
export const OFFICIAL_TIMEZONE = "Asia/Shanghai";

export function isOfficialCalendarPath(path, officialPath) {
  if (!path || !officialPath) {
    return false;
  }
  const currentPath = path.split(/[?#]/)[0];
  const categoryPath = officialPath.split("/l/")[0].replace(/\/$/, "");
  return (
    currentPath === categoryPath || currentPath.startsWith(`${categoryPath}/`)
  );
}

function parts(value, withTime = false) {
  return Object.fromEntries(
    new Intl.DateTimeFormat("en-CA", {
      timeZone: OFFICIAL_TIMEZONE,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      ...(withTime
        ? { hour: "2-digit", minute: "2-digit", hourCycle: "h23" }
        : {}),
    })
      .formatToParts(new Date(value))
      .map((part) => [part.type, part.value])
  );
}

export function officialDateKey(value) {
  const date = parts(value);
  return `${date.year}-${date.month}-${date.day}`;
}

export function officialOccursOn(item, key) {
  const dayStart = new Date(`${key}T00:00:00+08:00`).getTime();
  const nextDay = dayStart + 86400000;
  const start = new Date(item.starts_at).getTime();
  const end = new Date(item.ends_at).getTime();
  return start === end
    ? start >= dayStart && start < nextDay
    : start < nextDay && end > dayStart;
}

function officialInput(value, allDay) {
  const date = parts(value, !allDay);
  const day = `${date.year}-${date.month}-${date.day}`;
  return allDay ? day : `${day}T${date.hour}:${date.minute}`;
}

export function officialTimeLabel(item) {
  if (!item?.starts_at || !item?.ends_at) {
    return "";
  }
  const format = new Intl.DateTimeFormat(
    I18n.currentLocale().replace("_", "-"),
    {
      timeZone: OFFICIAL_TIMEZONE,
      year: "numeric",
      month: "short",
      day: "numeric",
      ...(!item.all_day
        ? { hour: "2-digit", minute: "2-digit", hourCycle: "h23" }
        : {}),
    }
  );
  const start = format.format(new Date(item.starts_at));
  if (item.schedule_kind === "deadline") {
    return i18n(
      themePrefix(
        item.all_day
          ? "isbf_v2.schedule_deadline_day"
          : "isbf_v2.schedule_deadline_time"
      ),
      { date: start }
    );
  }
  const endTime = new Date(item.ends_at).getTime() - (item.all_day ? 1 : 0);
  if (
    item.ends_at === item.starts_at ||
    (item.all_day &&
      officialDateKey(item.starts_at) === officialDateKey(endTime))
  ) {
    return i18n(
      themePrefix(
        item.all_day
          ? "isbf_v2.schedule_event_day"
          : "isbf_v2.schedule_event_time"
      ),
      { date: start }
    );
  }
  return i18n(themePrefix("isbf_v2.schedule_event_range"), {
    start,
    end: format.format(new Date(endTime)),
  });
}

export function isOfficialCalendarComposer(model, site) {
  const categoryId = site?.isbf_calendar?.official_category_id;
  return Boolean(
    Number(categoryId) > 0 &&
    model &&
    !model.privateMessage &&
    !model.creatingPrivateMessage &&
    model.archetypeId !== "private_message" &&
    model.topic?.archetype !== "private_message" &&
    Number(model.categoryId ?? model.topic?.category_id) ===
      Number(categoryId) &&
    (model.creatingTopic || model.editingFirstPost)
  );
}

export function canonicalCalendarItems(items = []) {
  const active = items.filter((item) => !item.cancelled);
  return active.map((item) => {
    const result = {
      ...(item.id ? { id: item.id, revision: item.revision } : {}),
      title: item.title,
      schedule_kind: item.schedule_kind,
      starts_at: item.starts_at,
      ends_at: item.ends_at,
      all_day: Boolean(item.all_day),
    };
    if (item.schedule_kind === "event") {
      for (const field of ["location", "organizer"]) {
        if (Object.hasOwn(item, field)) {
          result[field] = item[field]?.trim() || "";
        }
      }
      if (
        Object.hasOwn(item, "registration_deadline_index") ||
        Object.hasOwn(item, "registration_deadline_id")
      ) {
        const deadline = registrationDeadline(item, items);
        result.registration_deadline_index = deadline
          ? active.indexOf(deadline)
          : null;
      }
    }
    return result;
  });
}

function registrationDeadline(item, items) {
  const deadline = Object.hasOwn(item, "registration_deadline_index")
    ? items[item.registration_deadline_index]
    : items.find(
        (candidate) =>
          candidate.id && candidate.id === item.registration_deadline_id
      );
  return deadline &&
    !deadline.cancelled &&
    deadline.schedule_kind === "deadline"
    ? deadline
    : null;
}

export function officialCalendarGroups(items = []) {
  const active = items.filter((item) => !item.cancelled);
  const linked = new Set();
  const groups = active.map((item) => {
    const deadline =
      item.schedule_kind === "event" ? registrationDeadline(item, items) : null;
    if (deadline) {
      linked.add(deadline);
    }
    return { item, deadline, isEvent: item.schedule_kind === "event" };
  });
  return groups.filter((group) => !linked.has(group.item));
}

function calendarEditorItem(item) {
  return {
    ...item,
    start: officialInput(item.starts_at, item.all_day),
    end:
      item.ends_at === item.starts_at
        ? ""
        : officialInput(
            new Date(item.ends_at).getTime() - (item.all_day ? 86400000 : 0),
            item.all_day
          ),
  };
}

export function calendarEditorItems(items) {
  return officialCalendarGroups(canonicalCalendarItems(items)).map(
    ({ item, deadline }) => ({
      ...calendarEditorItem(item),
      has_registration_deadline: Boolean(deadline),
      registration_deadline: deadline
        ? calendarEditorItem(deadline)
        : {
            title: "",
            schedule_kind: "deadline",
            all_day: false,
            start: "",
            end: "",
          },
    })
  );
}

export function calendarItemsFromEditor(items) {
  const result = [];
  for (const item of items) {
    const source = calendarItemFromEditor(item);
    result.push(source);
    if (item.schedule_kind !== "event") {
      continue;
    }
    source.registration_deadline_index = null;
    if (item.has_registration_deadline) {
      const deadline = item.registration_deadline;
      source.registration_deadline_index = result.length;
      result.push(
        calendarItemFromEditor({
          ...deadline,
          title: deadline.id
            ? deadline.title
            : i18n(themePrefix("isbf_v2.schedule_registration_name"), {
                name: item.title,
              }).slice(0, 120),
          schedule_kind: "deadline",
        })
      );
    }
  }
  return result;
}

export function calendarItemFromEditor(item) {
  const starts = new Date(
    `${item.start}${item.all_day ? "T00:00:00" : ""}+08:00`
  );
  if (
    !Number.isFinite(starts.getTime()) ||
    officialDateKey(starts) !== item.start.slice(0, 10)
  ) {
    throw new RangeError("Invalid official calendar date");
  }
  let ends = starts;
  if (item.all_day) {
    const endDate =
      item.schedule_kind === "deadline" ? item.start : item.end || item.start;
    const end = new Date(`${endDate}T00:00:00+08:00`);
    if (!Number.isFinite(end.getTime()) || officialDateKey(end) !== endDate) {
      throw new RangeError("Invalid official calendar end date");
    }
    ends = new Date(end.getTime() + 86400000);
  } else if (item.schedule_kind === "event" && item.end) {
    ends = new Date(`${item.end}+08:00`);
    if (
      !Number.isFinite(ends.getTime()) ||
      officialDateKey(ends) !== item.end.slice(0, 10)
    ) {
      throw new RangeError("Invalid official calendar end date");
    }
  }
  if (ends < starts) {
    throw new RangeError("Invalid official calendar time range");
  }
  return canonicalCalendarItems([
    { ...item, starts_at: starts.toISOString(), ends_at: ends.toISOString() },
  ])[0];
}
