const origins = new WeakMap<HTMLElement, HTMLElement>();

/** Associates a portaled float with the control which owns it. */
export function registerFloatingOrigin(
  content: HTMLElement,
  trigger: HTMLElement | null
) {
  if (trigger) {
    origins.set(content, trigger);
  }
  return () => origins.delete(content);
}

/** Includes nested portaled menus when checking whether a pointer left a float. */
export function containsFloatingTarget(
  content: HTMLElement,
  target: EventTarget | null
): boolean {
  if (!(target instanceof Node)) {
    return false;
  }
  if (content.contains(target)) {
    return true;
  }
  let child = (
    target instanceof Element ? target : target.parentElement
  )?.closest<HTMLElement>("[data-content]");
  const visited = new Set<HTMLElement>();
  while (child && !visited.has(child)) {
    visited.add(child);
    const trigger = origins.get(child);
    if (!trigger) {
      return false;
    }
    if (content.contains(trigger)) {
      return true;
    }
    child = trigger.closest<HTMLElement>("[data-content]");
  }
  return false;
}
