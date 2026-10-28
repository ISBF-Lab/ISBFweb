export function isTopTopicsPath(url) {
  return /^\/top\/?$/.test((url ?? "").split(/[?#]/)[0]);
}
