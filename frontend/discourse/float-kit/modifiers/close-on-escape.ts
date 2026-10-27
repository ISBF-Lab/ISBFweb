import { registerDestructor } from "@ember/destroyable";
import type Owner from "@ember/owner";
import Modifier, { type ArgsFor } from "ember-modifier";
import { bind } from "discourse/lib/decorators";
import { containsFloatingTarget } from "discourse/ui-kit/-internals/floating-family";

const activeHandlers = new Set<FloatKitCloseOnEscape>();

interface FloatKitCloseOnEscapeSignature {
  Element: HTMLElement;
  Args: {
    Positional: [
      /** Called when Escape is pressed. */
      close: () => void,
    ];
  };
}

export default class FloatKitCloseOnEscape extends Modifier<FloatKitCloseOnEscapeSignature> {
  declare closeFn: () => void;
  declare element: HTMLElement;

  constructor(owner: Owner, args: ArgsFor<FloatKitCloseOnEscapeSignature>) {
    super(owner, args);
    registerDestructor(this, (instance) => instance.cleanup());
  }

  modify(
    element: HTMLElement,
    [closeFn]: FloatKitCloseOnEscapeSignature["Args"]["Positional"]
  ) {
    this.closeFn = closeFn;
    this.element = element;

    activeHandlers.add(this);
    document.addEventListener("keydown", this.check, { capture: true });
  }

  @bind
  check(event: KeyboardEvent) {
    if (event.key !== "Escape" || event.defaultPrevented) {
      return;
    }
    const handlers = [...activeHandlers].filter(
      (handler) => handler.element.isConnected
    );
    const innermost = handlers
      .reverse()
      .find(
        (handler) =>
          !handlers.some(
            (other) =>
              other !== handler &&
              containsFloatingTarget(handler.element, other.element)
          )
      );
    if (innermost !== this) {
      return;
    }
    event.stopPropagation();
    event.preventDefault();
    this.closeFn();
  }

  cleanup() {
    activeHandlers.delete(this);
    document.removeEventListener("keydown", this.check, { capture: true });
  }
}
