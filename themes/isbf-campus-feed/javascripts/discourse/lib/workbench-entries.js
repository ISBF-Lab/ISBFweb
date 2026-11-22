export const WORKBENCH_ENTRIES = Object.freeze(
  [
    {
      key: "learning_resources",
      icon: "isbf-workbench-book-open",
      mobileIcon: "book-open",
      tone: "blue",
    },
    {
      key: "library",
      icon: "isbf-workbench-database",
      mobileIcon: "database",
      tone: "indigo",
    },
    {
      key: "courses",
      icon: "isbf-workbench-graduation-cap",
      mobileIcon: "graduation-cap",
      tone: "violet",
    },
    {
      key: "careers",
      icon: "isbf-workbench-briefcase",
      mobileIcon: "briefcase",
      tone: "amber",
    },
    {
      key: "resume",
      icon: "isbf-workbench-file-lines",
      mobileIcon: "file-lines",
      tone: "mint",
    },
    {
      key: "campus_services",
      icon: "isbf-workbench-building-columns",
      mobileIcon: "building-columns",
      tone: "sky",
    },
    {
      key: "student_identity",
      icon: "isbf-workbench-id-card",
      mobileIcon: "id-card",
      tone: "rose",
    },
    {
      key: "alumni",
      icon: "isbf-workbench-user-group",
      mobileIcon: "user-group",
      tone: "teal",
    },
    {
      key: "marketplace",
      icon: "isbf-workbench-bag-shopping",
      mobileIcon: "bag-shopping",
      tone: "amber",
    },
    {
      key: "teamup",
      icon: "isbf-workbench-user-group",
      mobileIcon: "user-group",
      tone: "violet",
    },
    { key: "mbti", icon: "brain", mobileIcon: "brain", tone: "blue" },
    {
      key: "ai_assistant",
      icon: "discobot",
      mobileIcon: "discobot",
      tone: "blue",
    },
    {
      key: "guides",
      icon: "isbf-workbench-guides",
      mobileIcon: "isbf-workbench-guides",
      tone: "blue",
    },
  ].map(Object.freeze)
);

export const WORKBENCH_PALETTE_TONES = Object.freeze([
  "theme",
  "mint",
  "amber",
  "violet",
]);

export function mergeWorkbenchEntries(value, iconExists = () => false) {
  const defaults = new Map(
    WORKBENCH_ENTRIES.map((entry) => [entry.key, entry])
  );
  const entries = new Map();

  for (const configured of Array.isArray(value) ? value : []) {
    if (!configured || typeof configured !== "object") {
      continue;
    }

    const original = defaults.get(configured.key);
    if (!original || entries.has(configured.key)) {
      continue;
    }

    const icon =
      typeof configured.icon === "string" ? configured.icon.trim() : "";
    const paletteTone = WORKBENCH_PALETTE_TONES.includes(configured.tone)
      ? configured.tone
      : "";
    entries.set(configured.key, {
      ...original,
      ...(icon && iconExists(icon) ? { icon, mobileIcon: icon } : {}),
      ...(paletteTone ? { tone: paletteTone } : {}),
      paletteTone,
    });
  }

  for (const original of WORKBENCH_ENTRIES) {
    if (!entries.has(original.key)) {
      entries.set(original.key, { ...original, paletteTone: "" });
    }
  }

  return [...entries.values()];
}
