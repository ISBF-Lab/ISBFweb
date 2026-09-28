export function quickPostTitle(reply, minimumLength, maximumLength) {
  if (!reply?.trim()) {
    return "";
  }

  const text = reply
    .replace(/!\[[^\]]*\]\([^)]+\)/g, "图片")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .replace(/https?:\/\/\S+/g, "链接")
    .replace(/<[^>]+>/g, " ")
    .replace(/[#>*_~`|]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  const minimum = Math.max(1, Number(minimumLength) || 1);
  const maximum = Math.max(minimum, Number(maximumLength) || 255);
  const limit = Math.min(maximum, 80);
  let title = (text || "校园图片分享").slice(0, limit);

  if (title.length < minimum) {
    title = `校园动态：${title}`.slice(0, maximum);
  }

  if (title.length < minimum) {
    const timestamp = new Date().toISOString().slice(0, 16).replace("T", " ");
    title = `${title} · ${timestamp} · 国金综合平台`.slice(0, maximum);
  }

  return title;
}
