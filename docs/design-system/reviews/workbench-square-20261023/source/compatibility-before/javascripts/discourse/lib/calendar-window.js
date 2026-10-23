export function calendarMonthAnchor(month, day) {
  const year = month.getFullYear();
  const index = month.getMonth();
  const lastDay = new Date(year, index + 1, 0).getDate();
  return new Date(year, index, Math.min(day, lastDay), 12);
}

export function calendarWindow(month, compact, anchorDay) {
  const anchor = calendarMonthAnchor(month, compact ? anchorDay : 1);
  const mondayOffset = (anchor.getDay() + 6) % 7;
  const from = new Date(
    anchor.getFullYear(),
    anchor.getMonth(),
    anchor.getDate() - mondayOffset - (compact ? 14 : 0)
  );
  const dayCount = compact ? 35 : 42;
  const to = new Date(
    from.getFullYear(),
    from.getMonth(),
    from.getDate() + dayCount
  );
  return { from, to, dayCount };
}
