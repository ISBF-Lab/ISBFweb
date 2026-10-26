import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import type { ComponentLike } from "@glint/template";
import { modifier } from "ember-modifier";
import DMenu, {
  type DMenuSignature,
} from "discourse/float-kit/components/d-menu";
import type DMenuInstance from "discourse/float-kit/lib/d-menu-instance";
import DButton from "discourse/ui-kit/d-button";
import NativeSelectUntyped, {
  NO_VALUE_OPTION,
} from "discourse/ui-kit/d-select/native";
import dMenuHighlight from "discourse/ui-kit/modifiers/d-menu-highlight";
import dRovingFocus from "discourse/ui-kit/modifiers/d-roving-focus";

type SelectValue<Multiple extends boolean> = Multiple extends true
  ? string[]
  : string | null;
type OptionComponent = ComponentLike<{
  Element: HTMLOptionElement;
  Args: {
    /** The option's submitted value. */
    value?: unknown;
    /** The current controlled value. */
    selected?: unknown;
  };
  Blocks: {
    /** The visible option label. */
    default: [];
  };
}>;

// TODO(typescript-pending): remove the boundary alias once the native option carrier has a Signature.
const NativeSelect = NativeSelectUntyped as unknown as ComponentLike<{
  Element: HTMLSelectElement;
  Args: {
    value?: unknown;
    includeNone?: boolean;
    nonePlaceholder?: string;
    onChange?: (value: string | null) => void;
  };
  Blocks: { default: [{ Option: OptionComponent }] };
}>;

// TODO(typescript-pending): remove this alias when the default menu trigger exposes its button Element.
const SelectMenu = DMenu as unknown as ComponentLike<
  Omit<DMenuSignature, "Element"> & { Element: HTMLButtonElement }
>;

interface DSelectSignature<Multiple extends boolean> {
  Element: HTMLButtonElement;
  Args: {
    /** The controlled value, using the existing native option value conventions. */
    value?: unknown;
    /** Called once when the reader changes the selection. */
    onChange?: (value: SelectValue<Multiple>) => unknown;
    /** A native input callback for existing form adapters. */
    onInput?: (event: Event) => unknown;
    /** Whether more than one option can be selected. */
    multiple?: Multiple;
    /** Whether to include the empty-value option. Defaults to true for single selection. */
    includeNone?: boolean;
    /** The empty-value option's label. */
    nonePlaceholder?: string;
    /** Whether the field is disabled. */
    disabled?: boolean;
    /** Whether an option must be selected. */
    required?: boolean;
    /** The successful form control's name. */
    name?: string;
    /** The associated form's id, when outside its form element. */
    form?: string;
  };
  Blocks: {
    /** Existing native Option blocks and raw option/optgroup markup remain supported. */
    default: [
      /** The option component, bound to the current selection. */
      select: { Option: OptionComponent },
    ];
  };
}

interface SelectOption {
  index: number;
  value: string;
  label: string;
  disabled: boolean;
  selected: boolean;
  group: string;
  groupStart: boolean;
}

/** A floating single or multiple select with a native form and Option compatibility carrier. */
export default class DSelect<
  Multiple extends boolean = false,
> extends Component<DSelectSignature<Multiple>> {
  @tracked options: SelectOption[] = [];
  @tracked label = "";
  @tracked validationMessage = "";

  observeNative = modifier((element: HTMLSelectElement, _args: [unknown]) => {
    void _args;
    this.#native = element;
    const refresh = () => scheduleOnce("afterRender", this, this.refresh);
    const captureInput = (event: Event) => {
      this.#lastInput = event;
    };
    const invalid = (event: Event) => {
      event.preventDefault();
      this.validationMessage = element.validationMessage;
      this.#menu?.triggerElement?.focus();
    };
    element.addEventListener("input", captureInput, true);
    element.addEventListener("invalid", invalid);
    const observer = new MutationObserver(refresh);
    observer.observe(element, {
      childList: true,
      subtree: true,
      attributes: true,
      characterData: true,
    });
    refresh();
    return () => {
      observer.disconnect();
      element.removeEventListener("input", captureInput, true);
      element.removeEventListener("invalid", invalid);
      this.#native = null;
    };
  });
  observeTrigger = modifier(
    (
      element: HTMLElement,
      _args: [unknown, unknown, unknown, unknown, unknown]
    ) => {
      void _args;
      const refresh = () => scheduleOnce("afterRender", this, this.refresh);
      const reset = () => requestAnimationFrame(refresh);
      const observer = new MutationObserver(refresh);
      observer.observe(element, {
        attributes: true,
        attributeFilter: ["name", "required", "disabled", "form", "multiple"],
      });
      const form =
        element instanceof HTMLButtonElement
          ? element.form
          : element.closest("form");
      form?.addEventListener("reset", reset);
      refresh();
      return () => {
        observer.disconnect();
        form?.removeEventListener("reset", reset);
      };
    }
  );
  #native: HTMLSelectElement | null = null;
  #menu: DMenuInstance | null = null;
  #fingerprint = "";

  #entered = false;

  #lastInput: Event | null = null;

  get includeNone() {
    return this.args.includeNone ?? !this.args.multiple;
  }

  @action
  changed() {
    const native = this.#native;
    if (!native) {
      return;
    }
    this.validationMessage = "";
    const value = native.multiple
      ? Array.from(native.selectedOptions, (option) => option.value)
      : native.value === NO_VALUE_OPTION
        ? null
        : native.value;
    this.args.onChange?.(value as SelectValue<Multiple>);
    if (this.#lastInput) {
      this.args.onInput?.(this.#lastInput);
    }
    this.refresh();
  }

  @action
  closed() {
    this.#entered = false;
  }

  @action
  enter() {
    if (!this.#entered) {
      this.#entered = true;
      const row =
        this.#menu?.content?.querySelector<HTMLElement>(
          '[role="option"][aria-selected="true"]:not(:disabled)'
        ) ??
        this.#menu?.content?.querySelector<HTMLElement>(
          '[role="option"]:not(:disabled)'
        );
      row?.focus({ preventScroll: true });
      row?.scrollIntoView({ block: "nearest" });
    }
  }

  @action
  keydown(event: KeyboardEvent) {
    if (
      (event.key === "ArrowDown" || event.key === "ArrowUp") &&
      !this.#native?.disabled
    ) {
      event.preventDefault();
      this.#menu?.show();
    }
  }

  @action
  async pick(option: SelectOption) {
    const native = this.#native;
    if (!native || option.disabled || native.disabled) {
      return;
    }
    if (!native.multiple && native.selectedIndex === option.index) {
      await this.#menu?.close();
      return;
    }
    if (native.multiple) {
      const selected = native.options.item(option.index);
      if (selected) {
        selected.selected = !selected.selected;
      }
    } else {
      native.selectedIndex = option.index;
    }
    native.dispatchEvent(new Event("input", { bubbles: true }));
    native.dispatchEvent(new Event("change", { bubbles: true }));
    if (!native.multiple) {
      await this.#menu?.close();
    }
  }

  @action
  refresh() {
    const native = this.#native;
    if (!native || this.isDestroying) {
      return;
    }
    const trigger = this.#menu?.triggerElement;
    if (trigger) {
      const attrs = {
        name: this.args.name ?? trigger.getAttribute("name"),
        form: this.args.form ?? trigger.getAttribute("form"),
        required:
          (this.args.required ?? trigger.hasAttribute("required")) ? "" : null,
        disabled:
          (this.args.disabled ?? trigger.matches(":disabled")) ? "" : null,
        multiple: this.args.multiple ? "" : null,
      };
      for (const [name, value] of Object.entries(attrs)) {
        if (value === null) {
          native.removeAttribute(name);
        } else if (native.getAttribute(name) !== value) {
          native.setAttribute(name, value);
        }
      }
    }
    native.setCustomValidity("");
    if (
      native.required &&
      native.value === NO_VALUE_OPTION &&
      !native.disabled
    ) {
      const index = native.selectedIndex;
      native.selectedIndex = -1;
      const message = native.validationMessage;
      native.selectedIndex = index;
      native.setCustomValidity(message);
    }
    let groupBefore = "";
    const options = Array.from(native.options)
      .map((option, index) => {
        const parent = option.parentElement;
        const group = parent instanceof HTMLOptGroupElement ? parent.label : "";
        const result = {
          index,
          value: option.value,
          label: option.label,
          disabled:
            option.disabled ||
            (parent instanceof HTMLOptGroupElement && parent.disabled),
          selected: option.selected,
          group,
          groupStart: Boolean(group && group !== groupBefore),
        };
        groupBefore = group;
        return option.hidden ? null : result;
      })
      .filter((option): option is SelectOption => option !== null);
    const label =
      Array.from(native.selectedOptions, (option) => option.label).join(", ") ||
      this.args.nonePlaceholder ||
      "";
    const fingerprint = JSON.stringify([options, label]);
    if (fingerprint !== this.#fingerprint) {
      this.#fingerprint = fingerprint;
      this.options = options;
      this.label = label;
    }
  }

  @action
  registerMenu(menu: DMenuInstance) {
    this.#menu = menu;
    scheduleOnce("afterRender", this, this.refresh);
  }

  <template>
    <SelectMenu
      aria-haspopup="listbox"
      aria-invalid={{if this.validationMessage "true"}}
      ...attributes
      @constrainHeightToViewport={{true}}
      @contentClass="d-select__menu"
      @contentRole="presentation"
      @disabled={{@disabled}}
      @icon="chevron-down"
      @inlineTabOrder={{true}}
      @label={{this.label}}
      @matchTriggerMinWidth={{true}}
      @onClose={{this.closed}}
      @onKeydown={{this.keydown}}
      @onPositioned={{this.enter}}
      @onRegisterApi={{this.registerMenu}}
      @placement="bottom-start"
      @triggerClass="d-select__trigger"
      {{this.observeTrigger @disabled @required @name @form @multiple}}
    >
      <:content>
        <ul
          aria-label={{this.label}}
          aria-multiselectable={{if @multiple "true"}}
          class="dropdown-menu d-select__options"
          role="listbox"
          {{dRovingFocus
            itemSelector="[role='option']"
            itemsKey=this.options
            orientation="vertical"
            typeAhead=true
          }}
          {{dMenuHighlight itemsKey=this.options}}
        >
          {{#each this.options key="index" as |option|}}
            {{#if option.groupStart}}
              <li
                class="dropdown-menu__subheader"
                role="presentation"
              >{{option.group}}</li>
            {{/if}}
            <li class="dropdown-menu__item" role="presentation">
              <DButton
                aria-selected={{if option.selected "true" "false"}}
                class="d-select__option"
                role="option"
                @action={{fn this.pick option}}
                @disabled={{option.disabled}}
              ><span>{{option.label}}</span></DButton>
            </li>
          {{/each}}
        </ul>
      </:content>
    </SelectMenu>
    <NativeSelect
      aria-hidden="true"
      class="d-select__native"
      disabled={{@disabled}}
      form={{@form}}
      multiple={{@multiple}}
      name={{@name}}
      required={{@required}}
      tabindex="-1"
      @includeNone={{this.includeNone}}
      @nonePlaceholder={{@nonePlaceholder}}
      @onChange={{this.changed}}
      @value={{@value}}
      {{this.observeNative @value}}
      as |select|
    >
      {{yield select}}
    </NativeSelect>
    {{#if this.validationMessage}}<p
        class="d-select__error"
        role="alert"
      >{{this.validationMessage}}</p>{{/if}}
  </template>
}
