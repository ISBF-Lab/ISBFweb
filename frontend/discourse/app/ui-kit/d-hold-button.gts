import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import type { TOC } from "@ember/component/template-only";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { guidFor } from "@ember/object/internals";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import type RouterService from "@ember/routing/router-service";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import type A11yService from "discourse/services/a11y";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

type Phase = "idle" | "holding" | "pending" | "done";
type InputKind = "pointer" | "key";
type HoldResult = boolean | void;

export interface DHoldButtonSignature {
  Args: {
    /** Runs once after a complete hold. Return false to reset without success. */
    action: () => HoldResult | Promise<HoldResult>;
    /** Translation key for the idle label and accessible name. */
    label: string;
    /** Translation key announced and displayed only after the action succeeds. */
    doneLabel: string;
    /** Translation key displayed while waiting for the action's result. */
    pendingLabel: string;
    /** Translation key describing the required hold duration. */
    hint: string;
    /** Required hold duration in milliseconds; defaults to 2000. */
    holdTime?: number;
    /** Fill return duration in milliseconds; defaults to 200. */
    releaseTime?: number;
    /** Success display duration in milliseconds; 0 keeps it done. Defaults to 1200. */
    resetAfter?: number;
    /** Prevents input and cancels an unfinished hold. */
    disabled?: boolean;
    /** Handles a rejected action after the button resets. */
    onError?: (error: unknown) => void;
  };
  Element: HTMLElement;
  Blocks: {
    /** Optional idle content, including alternate responsive labels. */
    default: [];
  };
}

const Labels: TOC<{
  Args: { label: string; doneLabel: string; pendingLabel: string };
  Blocks: { default: [] };
}> = <template>
  <span class="d-hold-button__idle">
    {{#if (has-block)}}{{yield}}{{else}}{{i18n @label}}{{/if}}
  </span>
  <span class="d-hold-button__pending">{{i18n @pendingLabel}}</span>
  <span class="d-hold-button__done">{{dIcon "check"}}{{i18n @doneLabel}}</span>
</template>;

export default class DHoldButton extends Component<DHoldButtonSignature> {
  @service declare a11y: A11yService;
  @service declare router: RouterService;

  @tracked phase: Phase = "idle";
  @tracked input: InputKind | null = null;

  hintId = `${guidFor(this)}-hold-hint`;

  #element?: HTMLButtonElement;
  #observer?: ResizeObserver;
  #frame = 0;
  #completeTimer?: number;
  #resetTimer?: number;
  #pointerId: number | null = null;
  #pressedKey: string | null = null;
  #start = 0;
  #progress = 0;

  willDestroy() {
    super.willDestroy();
    this.#clearTimers();
    cancelAnimationFrame(this.#frame);
    this.#releaseCapture();
    this.#observer?.disconnect();
    window.removeEventListener("blur", this.cancelHold);
    document.removeEventListener("visibilitychange", this.onVisibilityChange);
    this.router.off("routeWillChange", this.cancelHold);
  }

  get accessibleLabel() {
    if (this.phase === "done") {
      return this.args.doneLabel;
    }
    return this.phase === "pending" ? this.args.pendingLabel : this.args.label;
  }

  get busy() {
    return this.phase === "pending" || this.phase === "done";
  }

  get holdTime() {
    return Math.max(0, this.args.holdTime ?? 2000);
  }

  get releaseTime() {
    return Math.max(0, this.args.releaseTime ?? 200);
  }

  get resetAfter() {
    return Math.max(0, this.args.resetAfter ?? 1200);
  }

  @action
  setup(element: HTMLElement) {
    if (!(element instanceof HTMLButtonElement)) {
      return;
    }
    this.#element = element;
    const measure = () => {
      element.style.setProperty("--d-hold-width", `${element.offsetWidth}px`);
      element.style.setProperty("--d-hold-height", `${element.offsetHeight}px`);
    };
    measure();
    this.#observer = new ResizeObserver(measure);
    this.#observer.observe(element);
    this.syncDisabled();
    window.addEventListener("blur", this.cancelHold);
    document.addEventListener("visibilitychange", this.onVisibilityChange);
    this.router.on("routeWillChange", this.cancelHold);
  }

  @action
  syncDisabled() {
    this.#element?.style.setProperty("--d-hold-time", `${this.holdTime}ms`);
    this.#element?.style.setProperty(
      "--d-hold-release",
      `${this.releaseTime}ms`
    );
    this.#element?.style.setProperty(
      "--d-hold-cycles",
      `${this.holdTime / 1100}`
    );
    if (this.args.disabled) {
      this.cancelHold();
    }
  }

  @action
  cancelHold() {
    if (this.phase === "holding") {
      this.#reset();
    }
    this.#pressedKey = null;
    this.#releaseCapture();
  }

  @action
  onVisibilityChange() {
    if (document.hidden) {
      this.cancelHold();
    }
  }

  @action
  onClick(event: MouseEvent) {
    event.preventDefault();
    if (this.phase === "idle") {
      this.a11y.announce(i18n(this.args.hint));
    }
  }

  @action
  onContextMenu(event: MouseEvent) {
    event.preventDefault();
  }

  @action
  onKeyDown(event: KeyboardEvent) {
    if (event.key === "Escape") {
      this.cancelHold();
    } else if (event.key === " " || event.key === "Enter") {
      event.preventDefault();
      if (!event.repeat && this.#begin("key")) {
        this.#pressedKey = event.key;
      }
    }
  }

  @action
  onKeyUp(event: KeyboardEvent) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault();
      if (this.input === "key" && this.#pressedKey === event.key) {
        this.#pressedKey = null;
        this.#release(false);
      }
    }
  }

  @action
  onPointerDown(event: PointerEvent) {
    if (
      event.button !== 0 ||
      !event.isPrimary ||
      this.#pointerId !== null ||
      !this.#begin("pointer")
    ) {
      return;
    }
    this.#pointerId = event.pointerId;
    try {
      this.#element?.setPointerCapture(event.pointerId);
    } catch {}
  }

  @action
  onPointerMove(event: PointerEvent) {
    if (event.pointerId !== this.#pointerId || !this.#element) {
      return;
    }
    const rect = this.#element.getBoundingClientRect();
    if (
      event.clientX < rect.left - 10 ||
      event.clientX > rect.right + 10 ||
      event.clientY < rect.top - 10 ||
      event.clientY > rect.bottom + 10
    ) {
      this.#endPointer(event, true);
    }
  }

  @action
  onPointerUp(event: PointerEvent) {
    this.#endPointer(event, false);
  }

  @action
  onPointerCancel(event: PointerEvent) {
    this.#endPointer(event, true);
  }

  @action
  onPointerLeave(event: PointerEvent) {
    if (event.pointerType !== "touch") {
      this.#endPointer(event, true);
    }
  }

  #begin(input: InputKind) {
    if (this.args.disabled || this.phase !== "idle" || !this.#element) {
      return false;
    }
    this.#clearTimers();
    this.#setProgress(0);
    this.#start = performance.now();
    this.phase = "holding";
    this.input = input;
    this.#drive(1, this.holdTime);
    this.#completeTimer = window.setTimeout(
      () => this.#complete(),
      this.holdTime
    );
    return true;
  }

  #endPointer(event: PointerEvent, cancelled: boolean) {
    if (event.pointerId !== this.#pointerId) {
      return;
    }
    this.#releaseCapture();
    this.#release(cancelled);
  }

  #release(cancelled: boolean) {
    if (this.phase !== "holding") {
      return;
    }
    if (!cancelled && performance.now() - this.#start >= this.holdTime) {
      this.#complete();
    } else {
      this.#reset();
    }
  }

  #releaseCapture() {
    const id = this.#pointerId;
    this.#pointerId = null;
    if (id !== null && this.#element?.hasPointerCapture(id)) {
      this.#element.releasePointerCapture(id);
    }
  }

  #clearTimers() {
    window.clearTimeout(this.#completeTimer);
    window.clearTimeout(this.#resetTimer);
  }

  async #complete() {
    if (
      this.isDestroying ||
      this.phase !== "holding" ||
      this.args.disabled ||
      performance.now() - this.#start < this.holdTime
    ) {
      return;
    }
    this.#clearTimers();
    cancelAnimationFrame(this.#frame);
    this.#setProgress(1);
    this.phase = "pending";
    const restoreFocus = document.activeElement === this.#element;
    try {
      const result = await this.args.action();
      if (this.isDestroying) {
        return;
      }
      if (result === false) {
        this.#reset();
        return;
      }
      this.phase = "done";
      this.a11y.announce(i18n(this.args.doneLabel));
      if (this.resetAfter > 0) {
        this.#resetTimer = window.setTimeout(
          () => this.#reset(),
          this.resetAfter
        );
      }
    } catch (error: unknown) {
      if (!this.isDestroying) {
        this.#reset();
        this.args.onError?.(error);
      }
    } finally {
      if (restoreFocus && !this.isDestroying) {
        schedule("afterRender", () => {
          if (
            !this.isDestroying &&
            document.activeElement === document.body &&
            !this.#element?.disabled
          ) {
            this.#element?.focus();
          }
        });
      }
    }
  }

  #reset() {
    this.#clearTimers();
    this.phase = "idle";
    this.input = null;
    this.#drive(0, this.releaseTime);
  }

  #setProgress(progress: number) {
    this.#progress = progress;
    this.#element?.style.setProperty("--d-hold-progress", progress.toFixed(4));
    this.#element?.toggleAttribute("data-fill-visible", progress > 0);
  }

  #drive(target: number, duration: number) {
    cancelAnimationFrame(this.#frame);
    const from = this.#progress;
    const start = performance.now();
    const step = (now: number) => {
      if (this.isDestroying) {
        return;
      }
      const t = duration > 0 ? Math.min(1, (now - start) / duration) : 1;
      const eased = target === 1 ? t : 1 - Math.pow(1 - t, 3);
      this.#setProgress(from + (target - from) * eased);
      if (t < 1) {
        this.#frame = requestAnimationFrame(step);
      } else if (target === 1) {
        this.#complete();
      }
    };
    this.#frame = requestAnimationFrame(step);
  }

  <template>
    {{! eslint-disable ember/template-no-pointer-down-event-binding -- Timed confirmation begins when the press starts. }}
    <DButton
      class="btn-default d-hold-button"
      ...attributes
      aria-busy={{if (eq this.phase "pending") "true"}}
      aria-describedby={{this.hintId}}
      aria-disabled={{if this.busy "true"}}
      data-input={{this.input}}
      data-phase={{this.phase}}
      @ariaLabel={{this.accessibleLabel}}
      @disabled={{@disabled}}
      @onKeyDown={{this.onKeyDown}}
      @title={{@hint}}
      {{didInsert this.setup}}
      {{didUpdate this.syncDisabled @disabled @holdTime @releaseTime}}
      {{on "blur" this.cancelHold}}
      {{on "click" this.onClick}}
      {{on "contextmenu" this.onContextMenu}}
      {{on "keyup" this.onKeyUp}}
      {{on "pointerdown" this.onPointerDown}}
      {{on "pointermove" this.onPointerMove}}
      {{on "pointerup" this.onPointerUp}}
      {{on "pointercancel" this.onPointerCancel}}
      {{on "lostpointercapture" this.onPointerCancel}}
      {{on "pointerleave" this.onPointerLeave}}
    >
      <span aria-hidden="true" class="d-hold-button__pulse" />
      <span aria-hidden="true" class="d-hold-button__label">
        <Labels
          @doneLabel={{@doneLabel}}
          @label={{@label}}
          @pendingLabel={{@pendingLabel}}
        >
          {{#if (has-block)}}{{yield}}{{else}}{{i18n @label}}{{/if}}
        </Labels>
      </span>
      <span aria-hidden="true" class="d-hold-button__clip">
        <span class="d-hold-button__fill">
          <span class="d-hold-button__label">
            <Labels
              @doneLabel={{@doneLabel}}
              @label={{@label}}
              @pendingLabel={{@pendingLabel}}
            >
              {{#if (has-block)}}{{yield}}{{else}}{{i18n @label}}{{/if}}
            </Labels>
          </span>
        </span>
        <span class="d-hold-button__crest">
          <span class="d-hold-button__label">
            <Labels
              @doneLabel={{@doneLabel}}
              @label={{@label}}
              @pendingLabel={{@pendingLabel}}
            >
              {{#if (has-block)}}{{yield}}{{else}}{{i18n @label}}{{/if}}
            </Labels>
          </span>
        </span>
      </span>
      <span class="sr-only" id={{this.hintId}}>{{i18n @hint}}</span>
    </DButton>
  </template>
}
