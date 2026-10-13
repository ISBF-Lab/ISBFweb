import { modifier } from "ember-modifier";

export default modifier((element, [frame]) => {
  const container =
    element.closest(
      ".avatar-frame__anchor, .isbf-avatar, .post-avatar, .user-card-avatar, .user-profile-avatar"
    ) || element.parentElement;
  const avatar = container.querySelector(
    "img.avatar, :scope > img:not(.avatar-frame__image)"
  );
  if (!avatar) {
    return;
  }

  const update = () => {
    const parent = element.offsetParent;
    if (!parent) {
      return;
    }
    const bounds = avatar.getBoundingClientRect();
    const origin = parent.getBoundingClientRect();
    const style = getComputedStyle(avatar);
    const number = (property) => parseFloat(style[property]) || 0;
    const leftInset = number("borderLeftWidth") + number("paddingLeft");
    const topInset = number("borderTopWidth") + number("paddingTop");
    const width =
      bounds.width -
      leftInset -
      number("borderRightWidth") -
      number("paddingRight");
    const height =
      bounds.height -
      topInset -
      number("borderBottomWidth") -
      number("paddingBottom");
    const diameter = Math.min(width, height);
    if (diameter <= 0) {
      element.style.visibility = "hidden";
      return;
    }

    const scale = Number.isFinite(frame.scale) ? frame.scale / 100 : 1.2;
    const offsetX = Number.isFinite(frame.offset_x) ? frame.offset_x / 100 : 0;
    const offsetY = Number.isFinite(frame.offset_y) ? frame.offset_y / 100 : 0;
    const size = diameter * scale;
    const left =
      bounds.left +
      leftInset -
      origin.left -
      parent.clientLeft +
      parent.scrollLeft +
      width / 2 -
      size / 2 +
      diameter * offsetX;
    const top =
      bounds.top +
      topInset -
      origin.top -
      parent.clientTop +
      parent.scrollTop +
      height / 2 -
      size / 2 +
      diameter * offsetY;
    element.style.width = `${size}px`;
    element.style.height = `${size}px`;
    element.style.left = `${left}px`;
    element.style.top = `${top}px`;
    element.style.visibility = "visible";
  };

  const observer = new ResizeObserver(update);
  observer.observe(avatar);
  observer.observe(container);
  avatar.addEventListener("load", update);
  update();

  return () => {
    observer.disconnect();
    avatar.removeEventListener("load", update);
  };
});
