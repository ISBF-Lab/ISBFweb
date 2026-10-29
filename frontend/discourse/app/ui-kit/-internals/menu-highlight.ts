/** The list rows eligible for a menu's visual cursor. */
export const MENU_ITEMS = [
  "[role='menuitem']",
  "[role='menuitemradio']",
  "[role='menuitemcheckbox']",
  "[role='option']",
  ".dropdown-menu__item button",
  ".dropdown-menu__item a",
  ".dropdown-menu__item > label",
  ".dropdown-menu__item[role='button']",
].join(",");

/** DOM conventions supplied by a selector's existing navigation engine. */
export interface MenuHighlightOptions {
  /** The actionable rows, excluding headings and search fields. */
  itemSelector?: string;
  /** Rows marked by an existing keyboard cursor. */
  activeSelector?: string;
  /** Ancestor scroller which clips and scrolls the visual cursor with its rows. */
  viewportSelector?: string;
}

/** A visual cursor which never changes focus, selection, or event activation. */
export default class MenuHighlight {
  #element: HTMLElement;
  #cursorElement: HTMLElement | null = null;
  #options: MenuHighlightOptions;
  #active: HTMLElement | null = null;
  #selected: HTMLElement[] = [];
  #rows: HTMLElement[] = [];
  #frame: number | null = null;
  #instant = true;
  #mutations: MutationObserver;
  #resize: ResizeObserver;

  #onPointer = (event: PointerEvent) => {
    if (event.pointerType === "touch") {
      return;
    }
    const row = this.#rowFor(event.target);
    if (row) {
      this.#instant = false;
      this.#move(row);
    }
  };

  #onFocus = (event: FocusEvent) => {
    const row = this.#rowFor(event.target);
    if (row) {
      this.#instant = true;
      this.#move(row);
    }
  };

  #onKey = () => {
    this.#instant = true;
    this.#schedule();
  };

  #onChange = () => {
    this.#instant = true;
    this.refresh();
  };

  constructor(element: HTMLElement, options: MenuHighlightOptions = {}) {
    this.#element = element;
    this.#options = options;
    element.classList.add("d-menu-highlight");
    element.addEventListener("pointerover", this.#onPointer);
    element.addEventListener("focusin", this.#onFocus);
    element.addEventListener("keydown", this.#onKey, true);
    element.addEventListener("change", this.#onChange);
    this.#mutations = new MutationObserver(() => this.#schedule());
    this.#mutations.observe(element, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: [
        "aria-checked",
        "aria-selected",
        "aria-pressed",
        "aria-disabled",
        "class",
        "disabled",
      ],
    });
    this.#resize = new ResizeObserver(() => {
      this.#instant = true;
      this.#schedule();
    });
    this.#resize.observe(element);
    this.refresh();
  }

  /** Reconciles dynamic options and externally changed selected values. */
  refresh() {
    const element = this.#element;
    if (!element.classList.contains("d-menu-highlight")) {
      element.classList.add("d-menu-highlight");
    }
    const selector = this.#options.itemSelector ?? MENU_ITEMS;
    this.#rows = Array.from(
      element.querySelectorAll<HTMLElement>(selector)
    ).filter((row) => {
      const parent = row.parentElement?.closest(selector);
      return (
        row.closest(".d-menu-highlight") === element &&
        (!parent || !element.contains(parent))
      );
    });
    const selected: HTMLElement[] = [];
    for (const row of this.#rows) {
      row.dataset.dMenuRow = "";
      const checked =
        row.matches(
          '[aria-checked="true"], [aria-selected="true"], [aria-pressed="true"], .is-selected'
        ) || Boolean(row.querySelector("input:checked"));
      if (checked) {
        selected.push(row);
        row.dataset.dMenuSelected = "";
      } else {
        delete row.dataset.dMenuSelected;
      }
    }
    const selectionChanged =
      selected.length !== this.#selected.length ||
      selected.some((row, index) => row !== this.#selected[index]);
    this.#selected = selected;
    const marked = this.#rows.find((row) =>
      row.matches(
        this.#options.activeSelector ??
          ".is-highlighted, .--preselected, .is-active"
      )
    );
    if (selectionChanged) {
      this.#instant = true;
      this.#move(selected[0] ?? marked ?? null);
    } else if (marked && this.#canHighlight(marked)) {
      this.#move(marked);
    } else if (this.#active && this.#rows.includes(this.#active)) {
      this.#move(this.#active);
    } else {
      this.#move(selected[0] ?? null);
    }
  }

  /** Releases observers and visual markers when the list is closed or destroyed. */
  disconnect() {
    if (this.#frame !== null) {
      cancelAnimationFrame(this.#frame);
    }
    this.#mutations.disconnect();
    this.#resize.disconnect();
    this.#clearCursorElement();
    const element = this.#element;
    element.removeEventListener("pointerover", this.#onPointer);
    element.removeEventListener("focusin", this.#onFocus);
    element.removeEventListener("keydown", this.#onKey, true);
    element.removeEventListener("change", this.#onChange);
    element.classList.remove("d-menu-highlight");
    delete element.dataset.dMenuReady;
    delete element.dataset.dMenuMotion;
    for (const row of this.#rows) {
      delete row.dataset.dMenuRow;
      delete row.dataset.dMenuSelected;
    }
  }

  #canHighlight(row: HTMLElement) {
    return (
      !row.matches(":disabled, [aria-disabled='true'], [hidden]") &&
      !row.querySelector("input:disabled") &&
      row.getClientRects().length > 0
    );
  }

  #clearCursorElement() {
    const element = this.#cursorElement;
    if (!element) {
      return;
    }
    delete element.dataset.dMenuReady;
    delete element.dataset.dMenuMotion;
    if (element !== this.#element) {
      this.#resize.unobserve(element);
      element.classList.remove("d-menu-highlight__viewport");
    }
    this.#cursorElement = null;
  }

  #move(row: HTMLElement | null) {
    if (!row || !this.#canHighlight(row)) {
      this.#clearCursorElement();
      this.#active = null;
      return;
    }
    const viewport = this.#options.viewportSelector
      ? row.closest<HTMLElement>(this.#options.viewportSelector)
      : null;
    const element =
      viewport && this.#element.contains(viewport) ? viewport : this.#element;
    this.#setCursorElement(element);
    if (!this.#instant && element.dataset.dMenuMotion === "instant") {
      element.dataset.dMenuMotion = "pointer";
      // Commit the keyboard position before enabling pointer interpolation.
      void getComputedStyle(element, "::before").translate;
    }
    this.#active = row;
    const root = element.getBoundingClientRect();
    const bounds = row.getBoundingClientRect();
    const scale = root.height / element.offsetHeight || 1;
    element.style.setProperty(
      "--d-menu-highlight-y",
      `${(bounds.top - root.top) / scale + element.scrollTop - element.clientTop}px`
    );
    element.style.setProperty(
      "--d-menu-highlight-height",
      `${bounds.height / scale}px`
    );
    element.style.setProperty(
      "--d-menu-highlight-x",
      `${(bounds.left - root.left) / scale + element.scrollLeft - element.clientLeft}px`
    );
    element.style.setProperty(
      "--d-menu-highlight-width",
      `${bounds.width / scale}px`
    );
    element.dataset.dMenuReady = "";
    element.dataset.dMenuMotion = this.#instant ? "instant" : "pointer";
  }

  #rowFor(target: EventTarget | null) {
    if (!(target instanceof Element)) {
      return null;
    }
    return (
      this.#rows.find((row) => row === target || row.contains(target)) ?? null
    );
  }

  #schedule() {
    if (this.#frame === null) {
      this.#frame = requestAnimationFrame(() => {
        this.#frame = null;
        this.refresh();
      });
    }
  }

  #setCursorElement(element: HTMLElement) {
    if (element === this.#cursorElement) {
      return;
    }
    this.#clearCursorElement();
    this.#cursorElement = element;
    if (element !== this.#element) {
      element.classList.add("d-menu-highlight__viewport");
      this.#resize.observe(element);
    }
  }
}
