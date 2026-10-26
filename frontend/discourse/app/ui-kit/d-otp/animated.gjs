import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { guidFor } from "@ember/object/internals";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { cancel, schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { isTesting } from "discourse/lib/environment";
import discourseLater from "discourse/lib/later";
import loadMotion from "discourse/lib/load-motion";
import { prefersReducedMotion } from "discourse/lib/utilities";
import preventScrollOnFocus from "discourse/modifiers/prevent-scroll-on-focus";
import { or } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const SETTLE = 0.3;
const CASCADE = 0.02;
const EASE_OUT = [0.23, 1, 0.32, 1];
const digitsOf = (value) => String(value ?? "").replace(/\D/g, "");
const slotsOf = (value, count) => {
  const code = digitsOf(value).slice(0, count);
  return Array.from({ length: count }, (_, index) => code[index] ?? "");
};
const firstEmpty = (slots) => {
  const index = slots.indexOf("");
  return index < 0 ? slots.length - 1 : index;
};

/**
 * @typedef AnimatedOtpSignature
 * @property {HTMLInputElement} Element
 * @property {object} Args
 * @property {boolean} [Args.autoFocus]
 * @property {string} [Args.autocomplete]
 * @property {string} [Args.describedBy]
 * @property {boolean} [Args.disabled]
 * @property {boolean} [Args.invalid]
 * @property {boolean} [Args.mask]
 * @property {(code: string) => void} [Args.onChange]
 * @property {(code: string) => void} [Args.onFill]
 * @property {number} [Args.slots]
 * @property {"idle" | "error" | "success"} [Args.status]
 * @property {string} [Args.value]
 */

/** @extends {Component<AnimatedOtpSignature>} */
export default class AnimatedOtp extends Component {
  @service a11y;
  @service capabilities;

  @tracked characters = slotsOf(this.args.value, this.count);
  @tracked shown = [...this.characters];
  @tracked active = firstEmpty(this.characters);
  @tracked rejecting = false;

  descriptionId = `${guidFor(this)}-progress`;

  #element;
  #input;
  #motion;
  #animations = new Map();
  #drainTimer;
  #generation = 0;
  #emitted = this.characters.join("");
  #status;
  #restoreFocus = false;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#generation++;
    cancel(this.#drainTimer);
    this.#stopAnimations();
  }

  get count() {
    return Math.max(1, Math.min(12, Math.trunc(this.args.slots) || 6));
  }

  get code() {
    return this.characters.join("");
  }

  get status() {
    return this.args.status ?? "idle";
  }

  get busy() {
    return this.args.disabled || this.rejecting || this.status === "success";
  }

  get reduceMotion() {
    return isTesting() || prefersReducedMotion();
  }

  get description() {
    return this.status === "success"
      ? i18n("d_otp.accepted")
      : i18n("d_otp.progress", {
          entered: this.characters.filter(Boolean).length,
          length: this.count,
        });
  }

  get describedBy() {
    return [this.descriptionId, this.args.describedBy]
      .filter(Boolean)
      .join(" ");
  }

  @action
  setup(element) {
    this.#element = element;
    this.#input = element.querySelector("input");
    this.sync();
    if ((this.args.autoFocus ?? true) && !this.capabilities.isIOS) {
      this.#input.focus({ preventScroll: true });
    }
    if (!this.reduceMotion) {
      loadMotion().then(
        (motion) => {
          if (!this.isDestroying) {
            this.#motion = motion;
          }
        },
        () => {}
      );
    }
  }

  @action
  sync() {
    if (!this.#element || this.isDestroying) {
      return;
    }

    this.#element.style.setProperty("--d-otp-slots", this.count);
    const clean = digitsOf(this.args.value).slice(0, this.count);
    if (
      this.characters.length !== this.count ||
      (this.args.value !== undefined && clean !== this.#emitted)
    ) {
      this.#generation++;
      cancel(this.#drainTimer);
      this.rejecting = false;
      this.#commit(slotsOf(clean, this.count), false);
    }

    if (this.#status !== this.status) {
      this.#generation++;
      cancel(this.#drainTimer);
      this.rejecting = false;
      this.#stopAnimations();
      this.#status = this.status;
      if (this.status === "error") {
        this.#reject();
      } else if (this.status === "success") {
        this.#accept();
      }
    }

    if (!this.busy && this.#restoreFocus) {
      this.#restoreFocus = false;
      if (document.activeElement === document.body) {
        this.#input.focus({ preventScroll: true });
      }
    }
  }

  @action
  isActive(index) {
    return index === this.active && this.status !== "success";
  }

  @action
  isFilled(index) {
    return Boolean(this.characters[index]);
  }

  @action
  displayChar(char) {
    return this.args.mask && char ? "•" : char;
  }

  @action
  onBlur() {
    this.#restoreFocus = this.args.disabled && this.status !== "success";
  }

  @action
  onPointerUp(event) {
    if (this.busy || event.button > 0) {
      return;
    }
    event.preventDefault();
    const slots = [...this.#element.querySelectorAll(".d-otp-animated__slot")];
    const index = slots.findIndex((slot) => {
      const rect = slot.getBoundingClientRect();
      return event.clientX >= rect.left && event.clientX <= rect.right;
    });
    if (index >= 0) {
      this.active = Math.min(index, firstEmpty(this.characters));
    }
    this.#input.focus({ preventScroll: true });
    this.#input.setSelectionRange(this.active, this.active);
  }

  @action
  onKeyDown(event) {
    if (
      this.busy ||
      event.metaKey ||
      event.ctrlKey ||
      event.altKey ||
      event.isComposing
    ) {
      return;
    }

    const key = event.key;
    if (/^[0-9]$/.test(key)) {
      event.preventDefault();
      this.#insert(key);
    } else if (key === "Backspace" || key === "Delete") {
      event.preventDefault();
      this.#remove(key === "Backspace");
    } else if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(key)) {
      event.preventDefault();
      const offset = key === "ArrowLeft" ? -1 : 1;
      this.active =
        key === "Home"
          ? 0
          : key === "End"
            ? this.count - 1
            : Math.max(0, Math.min(this.count - 1, this.active + offset));
      this.#input.setSelectionRange(this.active, this.active);
    }
  }

  @action
  onPaste(event) {
    event.preventDefault();
    if (this.busy) {
      return;
    }
    const code = digitsOf(event.clipboardData?.getData("text"));
    const replaceAll = code.length >= this.count || this.#allSelected();
    this.#insert(code, replaceAll ? 0 : this.active);
  }

  @action
  onInput(event) {
    if (this.busy) {
      event.target.value = this.code;
      return;
    }
    if (event.inputType?.startsWith("delete")) {
      const position = event.target.selectionStart;
      this.#commit(slotsOf(event.target.value, this.count));
      if (position !== null) {
        this.active = Math.max(0, Math.min(this.count - 1, position));
      }
    } else if (
      event.inputType === "insertText" &&
      digitsOf(event.data).length === 1
    ) {
      this.#insert(event.data);
    } else {
      this.#commit(slotsOf(event.target.value, this.count));
    }
    event.target.value = this.code;
  }

  #allSelected() {
    return (
      this.#input?.selectionStart === 0 &&
      this.#input?.selectionEnd === this.code.length
    );
  }

  #insert(raw, from = this.#allSelected() ? 0 : this.active) {
    const digits = digitsOf(raw);
    if (!digits) {
      return;
    }
    const next = this.#allSelected()
      ? slotsOf("", this.count)
      : [...this.characters];
    let index = from;
    for (const digit of digits) {
      if (index >= this.count) {
        break;
      }
      next[index++] = digit;
    }
    this.#commit(next);
    this.active = Math.min(index, this.count - 1);
    this.#input?.setSelectionRange(this.active, this.active);
  }

  #remove(backward) {
    const next = [...this.characters];
    if (this.#allSelected()) {
      this.#commit(slotsOf("", this.count));
      return;
    }
    if (backward && !next[this.active] && this.active > 0) {
      this.active--;
    }
    next[this.active] = "";
    const active = this.active;
    this.#commit(next);
    this.active = active;
    this.#input?.setSelectionRange(this.active, this.active);
  }

  #commit(next, emit = true, animate = true) {
    const previous = this.characters;
    this.characters = next;
    this.shown = next.map((char, index) => char || this.shown[index] || "");
    this.active = firstEmpty(next);
    this.#emitted = next.join("");
    if (this.#input) {
      this.#input.value = this.#emitted;
    }

    if (animate) {
      schedule("afterRender", this, this.#animateChanges, previous, next);
    } else {
      this.#stopAnimations();
    }

    if (emit) {
      this.args.onChange?.(this.#emitted);
      this.a11y.announce(this.description);
    }
    if (!previous.every(Boolean) && next.every(Boolean)) {
      this.args.onFill?.(this.#emitted);
    }
  }

  #animateChanges(previous, next) {
    if (this.isDestroying || this.rejecting || this.status !== "idle") {
      return;
    }
    let landing = 0;
    next.forEach((char, index) => {
      if (char !== previous[index]) {
        this.#animateSlot(index, Boolean(char), char ? landing++ * CASCADE : 0);
      }
    });
  }

  #animateSlot(index, filled, delay = 0) {
    const slot = this.#element?.querySelectorAll(".d-otp-animated__slot")[
      index
    ];
    if (!slot) {
      return;
    }
    this.#animate(
      slot.querySelector(".d-otp-animated__fill"),
      {
        transform: filled ? ["scale(0)", "scale(1)"] : ["scale(1)", "scale(0)"],
      },
      { type: "spring", duration: SETTLE, bounce: 0.2, delay }
    );
    this.#animate(
      slot.querySelector(".d-otp-animated__digit"),
      {
        transform: filled
          ? ["translateY(8px)", "translateY(0px)"]
          : ["translateY(0px)", "translateY(8px)"],
        opacity: filled ? [0, 1] : [1, 0],
      },
      { duration: SETTLE, ease: EASE_OUT, delay }
    );
  }

  #reject() {
    const filled = this.characters
      .map((char, index) => (char ? index : -1))
      .filter((index) => index >= 0)
      .reverse();
    if (!filled.length) {
      return;
    }
    this.rejecting = true;
    this.active = 0;
    filled.forEach((index, order) =>
      this.#animateSlot(index, false, order * CASCADE)
    );
    const generation = this.#generation;
    this.#drainTimer = discourseLater(
      () => {
        if (this.isDestroying || generation !== this.#generation) {
          return;
        }
        this.rejecting = false;
        this.#commit(slotsOf("", this.count), true, false);
        this.#input?.focus({ preventScroll: true });
      },
      this.reduceMotion ? 0 : (SETTLE + (filled.length - 1) * CASCADE) * 1000
    );
  }

  #accept() {
    this.a11y.announce(i18n("d_otp.accepted"));
    this.#animate(
      this.#element.querySelector(".d-otp-animated__wash"),
      {
        clipPath: ["inset(0 50% round 12px)", "inset(0 0% round 12px)"],
      },
      { duration: 0.3, ease: EASE_OUT }
    );
    this.#element
      .querySelectorAll(".d-otp-animated__digit")
      .forEach((digit, index) => {
        this.#animate(
          digit,
          {
            transform: ["translateY(0px)", "translateY(26px)"],
            opacity: [1, 0],
          },
          {
            duration: 0.3,
            delay: 0.06 + index * 0.03,
            ease: EASE_OUT,
          }
        );
      });
    this.#animate(
      this.#element.querySelector(".d-otp-animated__check"),
      {
        transform: ["translateY(8px) scale(0.85)", "translateY(0px) scale(1)"],
        opacity: [0, 1],
      },
      { type: "spring", duration: 0.35, bounce: 0.2, delay: 0.28 }
    );
  }

  #animate(element, keyframes, options) {
    if (!element) {
      return;
    }
    this.#animations.get(element)?.stop();
    if (this.reduceMotion) {
      return;
    }
    let animation;
    if (this.#motion) {
      animation = this.#motion.animate(element, keyframes, options);
    } else if (element.animate) {
      const native = element.animate(keyframes, {
        duration: options.duration * 1000,
        delay: (options.delay ?? 0) * 1000,
        easing: "cubic-bezier(0.23, 1, 0.32, 1)",
        fill: "both",
      });
      animation = { stop: () => native.cancel() };
    }
    if (animation) {
      this.#animations.set(element, animation);
    }
  }

  #stopAnimations() {
    this.#animations.forEach((animation, element) => {
      animation.stop();
      element.style.removeProperty("transform");
      element.style.removeProperty("opacity");
      element.style.removeProperty("clip-path");
    });
    this.#animations.clear();
  }

  <template>
    <div
      class="d-otp d-otp-animated"
      data-disabled={{if @disabled ""}}
      data-status={{this.status}}
      {{didInsert this.setup}}
      {{didUpdate this.sync @value @status @slots @disabled}}
    >
      <div aria-hidden="true" class="d-otp-animated__row">
        {{#each this.shown as |char index|}}
          <span
            class="d-otp-animated__slot"
            data-active={{if (this.isActive index) ""}}
            data-filled={{if (this.isFilled index) ""}}
            data-index={{index}}
          >
            <span class="d-otp-animated__fill" />
            <span class="d-otp-animated__digit">{{this.displayChar char}}</span>
            {{#if (this.isActive index)}}
              <span class="d-otp-animated__caret" />
            {{/if}}
          </span>
        {{/each}}
        <span class="d-otp-animated__wash">
          <span class="d-otp-animated__check">{{dIcon "check"}}</span>
        </span>
      </div>
      <input
        aria-describedby={{this.describedBy}}
        aria-invalid={{if (or @invalid this.rejecting) "true" "false"}}
        aria-label={{i18n "d_otp.screen_reader" count=this.count}}
        autocapitalize="off"
        autocomplete={{@autocomplete}}
        autocorrect="off"
        class="d-otp-input d-otp-animated__input"
        data-slot="input-otp"
        disabled={{@disabled}}
        inputmode="numeric"
        maxlength={{this.count}}
        pattern="[0-9]*"
        readonly={{this.busy}}
        spellcheck="false"
        type="text"
        value={{this.code}}
        ...attributes
        {{preventScrollOnFocus}}
        {{on "blur" this.onBlur}}
        {{on "keydown" this.onKeyDown}}
        {{on "pointerup" this.onPointerUp}}
        {{on "paste" this.onPaste}}
        {{on "input" this.onInput}}
      />
      <span
        class="sr-only"
        id={{this.descriptionId}}
      >{{this.description}}</span>
    </div>
  </template>
}
