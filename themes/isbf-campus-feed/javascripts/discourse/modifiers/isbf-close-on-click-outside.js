import DCloseOnClickOutside from "discourse/ui-kit/modifiers/d-close-on-click-outside";

export default class ISBFCloseOnClickOutside extends DCloseOnClickOutside {
  modify(element, args) {
    this.cleanup();
    super.modify(element, args);
    document.removeEventListener("pointerdown", this.check);

    // Dismiss before the native navigation queues a delayed close.
    document.addEventListener("pointerdown", this.check, {
      capture: true,
      passive: true,
    });
  }

  cleanup() {
    super.cleanup();
    document.removeEventListener("pointerdown", this.check, true);
  }
}
