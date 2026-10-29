import { registerDestructor } from "@ember/destroyable";
import type Owner from "@ember/owner";
import { waitForPromise } from "@ember/test-waiters";
import { autoUpdate } from "@floating-ui/dom";
import Modifier, { type ArgsFor } from "ember-modifier";
import type { FloatKitTrigger } from "discourse/float-kit/lib/constants";
import type FloatKitInstance from "discourse/float-kit/lib/float-kit-instance";
import {
  type PositioningOptions,
  updatePosition,
} from "discourse/float-kit/lib/update-position";
import { bind } from "discourse/lib/decorators";

interface FloatKitApplyFloatingUiSignature {
  Element: HTMLElement;
  Args: {
    Positional: [
      /** The reference the float is anchored to. */
      trigger: FloatKitTrigger,

      /** The positioning options, or `undefined` to use the defaults. */
      options: PositioningOptions | undefined,

      /** The float instance being positioned. */
      instance: FloatKitInstance,
    ];
  };
}

export default class FloatKitApplyFloatingUi extends Modifier<FloatKitApplyFloatingUiSignature> {
  declare instance: FloatKitInstance;
  declare options: PositioningOptions;
  declare cleanup?: () => void;

  #reference: FloatKitTrigger | null = null;

  constructor(owner: Owner, args: ArgsFor<FloatKitApplyFloatingUiSignature>) {
    super(owner, args);
    registerDestructor(this, (instance) => instance.teardown());
  }

  modify(
    element: HTMLElement,
    [
      trigger,
      options,
      instance,
    ]: FloatKitApplyFloatingUiSignature["Args"]["Positional"]
  ) {
    this.teardown();
    instance.content = element;
    this.instance = instance;
    this.options = options ?? {};
    this.#reference = this.#resolveReference(trigger);

    if (this.options.autoUpdate) {
      this.#observeReference();
    } else {
      this.update();
    }
  }

  @bind
  async update() {
    if (
      this.instance.triggerElement?.isConnected === false ||
      !this.instance.content?.isConnected
    ) {
      return;
    }

    const reference = this.#resolveReference();
    if (reference !== this.#reference) {
      this.teardown();
      this.#reference = reference;
      if (this.options.autoUpdate) {
        this.#observeReference();
        return;
      }
    }

    // Positioning is what finally gives a float its size, and it resolves off a promise the
    // test runtime cannot see. Without this, `settled()` returns while the float is still
    // unpositioned, so a test reads it at zero size — and anything that measures the float to
    // decide what to render, such as a virtualized list, computes an empty window from it.
    await waitForPromise(
      updatePosition(reference, this.instance.content, this.options)
    );
  }

  teardown() {
    this.cleanup?.();
    this.cleanup = undefined;
  }

  #observeReference() {
    if (!this.#reference || !this.instance.content) {
      return;
    }

    this.cleanup = autoUpdate(
      this.#reference,
      this.instance.content,
      this.update,
      typeof this.options.autoUpdate === "object" ? this.options.autoUpdate : {}
    );
  }

  #resolveReference(
    trigger: FloatKitTrigger = this.instance.trigger
  ): FloatKitTrigger {
    const anchor = this.options.anchorElement?.();
    return anchor?.isConnected ? anchor : trigger;
  }
}
