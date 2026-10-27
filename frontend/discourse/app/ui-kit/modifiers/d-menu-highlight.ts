import { registerDestructor } from "@ember/destroyable";
import type Owner from "@ember/owner";
import Modifier, { type ArgsFor } from "ember-modifier";
import MenuHighlight, {
  type MenuHighlightOptions,
} from "discourse/ui-kit/-internals/menu-highlight";

interface DMenuHighlightSignature {
  Element: HTMLElement;
  Args: {
    Positional: [];
    Named: MenuHighlightOptions & {
      /** Reactive option state which should refresh the visual cursor. */
      itemsKey?: unknown;
    };
  };
}

/** Shares a menu's visual cursor without owning its input or selection behavior. */
export default class DMenuHighlight extends Modifier<DMenuHighlightSignature> {
  #highlight: MenuHighlight | null = null;
  #element: HTMLElement | null = null;

  constructor(owner: Owner, args: ArgsFor<DMenuHighlightSignature>) {
    super(owner, args);
    registerDestructor(this, () => this.#highlight?.disconnect());
  }

  modify(
    element: HTMLElement,
    _positional: [],
    options: DMenuHighlightSignature["Args"]["Named"]
  ) {
    if (element !== this.#element) {
      this.#highlight?.disconnect();
      this.#element = element;
      this.#highlight = new MenuHighlight(element, options);
    } else {
      this.#highlight?.refresh();
    }
  }
}
