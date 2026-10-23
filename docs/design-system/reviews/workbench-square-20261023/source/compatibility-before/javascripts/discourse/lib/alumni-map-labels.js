export function labelFontSize(zoom) {
  return Math.max(10, Math.min(9 + zoom, 18));
}

export function visibleLabelLayers(candidates, size) {
  const accepted = [];
  const ordered = [...candidates].sort(
    (left, right) =>
      Number(Boolean(right.selected)) - Number(Boolean(left.selected)),
  );
  for (const candidate of ordered) {
    const box = candidate.box;
    if (
      box.left < 0 ||
      box.top < 0 ||
      box.right > size.x ||
      box.bottom > size.y ||
      accepted.some(
        ({ box: other }) =>
          box.left < other.right &&
          box.right > other.left &&
          box.top < other.bottom &&
          box.bottom > other.top,
      )
    ) {
      continue;
    }
    accepted.push(candidate);
  }
  return accepted.map(({ layer }) => layer);
}
