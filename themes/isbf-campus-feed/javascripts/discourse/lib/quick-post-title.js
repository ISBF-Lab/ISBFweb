export function quickPostText(reply) {
  const withoutQuotes = (reply ?? "").replace(
    /\[quote(?:=[^\]]+)?\][\s\S]*?\[\/quote\]/gi,
    " "
  );
  return withoutQuotes
    .replace(/!\[[^\]]*\]\([^)]+\)/g, "图片")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .replace(/https?:\/\/\S+/g, "链接")
    .replace(/<[^>]+>/g, " ")
    .replace(/[#>*_~`|]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function quickPostTitle(reply, minimumLength, maximumLength) {
  if (!reply?.trim()) {
    return "";
  }

  const text = quickPostText(reply);

  const minimum = Math.max(1, Number(minimumLength) || 1);
  const maximum = Math.max(minimum, Number(maximumLength) || 255);
  const limit = Math.min(maximum, Math.max(minimum, 80));
  const truncate = (value, length) => {
    const truncated = value.slice(0, length);
    return /[\uD800-\uDBFF]$/.test(truncated)
      ? truncated.slice(0, -1)
      : truncated;
  };
  let title = truncate(text || "引用转发", limit);

  if (Array.from(title).length < minimum) {
    title = truncate(`校园动态：${title}`, maximum);
  }

  if (Array.from(title).length < minimum) {
    const timestamp = new Date().toISOString().slice(0, 16).replace("T", " ");
    title = truncate(`${title} · ${timestamp} · 国金综合平台`, maximum);
  }

  return title;
}
