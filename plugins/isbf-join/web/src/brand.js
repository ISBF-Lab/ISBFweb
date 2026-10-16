// The central sign uses the same tightly tracked, correctly cased brand name.
// Canvas lettering is kept local and uses the already-loaded Inter family.
export function drawBrandWordmark(ctx, { x, y, width, maxHeight = Infinity, color = '#ffffff', weight = 550 }) {
  const letters = [...'ISBF-One'];
  const font = (size) => `${weight} ${size}px Inter, Arial, sans-serif`;
  ctx.save();
  ctx.font = font(100);
  const baseWidth = letters.reduce((sum, letter) => sum + ctx.measureText(letter).width, 0) - 5.2 * (letters.length - 1);
  const size = Math.min(width / baseWidth * 100, maxHeight);
  ctx.font = font(size);
  ctx.fillStyle = color;
  ctx.textAlign = 'left';
  ctx.textBaseline = 'middle';
  const spacing = -size * 0.052;
  const actualWidth = letters.reduce((sum, letter) => sum + ctx.measureText(letter).width, 0) + spacing * (letters.length - 1);
  let cursor = x - actualWidth / 2;
  for (const letter of letters) {
    ctx.fillText(letter, cursor, y);
    cursor += ctx.measureText(letter).width + spacing;
  }
  ctx.restore();
}
