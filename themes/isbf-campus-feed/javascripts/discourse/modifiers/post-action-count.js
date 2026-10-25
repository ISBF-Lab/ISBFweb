import { registerDestructor } from "@ember/destroyable";
import Modifier from "ember-modifier";
import { formatActionCount } from "../lib/post-action-pulse";

const DURATION = 350;

export default class PostActionCount extends Modifier {
  cancel = () => {
    this.#animation?.cancel();
    this.#animation = null;
    if (this.#element) {
      delete this.#element.dataset.isbfCountRolling;
      this.#element
        .querySelector(".isbf-post-action-count__motion")
        ?.replaceChildren();
    }
  };
  #animation;
  #element;
  #motion;

  #previous;

  constructor(owner, args) {
    super(owner, args);
    this.#motion = window.matchMedia("(prefers-reduced-motion: reduce)");
    this.#motion.addEventListener("change", this.cancel);
    registerDestructor(this, () => {
      this.#motion.removeEventListener("change", this.cancel);
      this.cancel();
    });
  }

  modify(element, [pulse, kind, value, format]) {
    this.#element = element;
    const next = Math.max(0, Number(value) || 0);
    const previous = this.#previous;
    this.#previous = next;
    this.cancel();
    if (this.#motion.matches || previous === next) {
      return;
    }
    const transition = pulse?.takeCountTransition(kind, previous, next);
    if (!transition) {
      return;
    }
    const from = formatActionCount(transition.from, format);
    const to = formatActionCount(next, format);
    if (!from || !to || from === to) {
      return;
    }

    const overlay = element.querySelector(".isbf-post-action-count__motion");
    const changed =
      from.length === to.length
        ? [...to].flatMap((char, index) =>
            char !== from[index] ? [index] : []
          )
        : [];
    const up = next > transition.from;
    const top = up ? from : to;
    const bottom = up ? to : from;
    const slot = document.createElement("span");
    slot.className = "isbf-post-action-count__slot";
    const roll = document.createElement("span");
    roll.className = "isbf-post-action-count__roll";
    slot.append(roll);
    if (changed.length === 1) {
      [...to].forEach((char, index) => {
        if (index === changed[0]) {
          overlay.append(slot);
          this.#appendRow(roll, top[index]);
          this.#appendRow(roll, bottom[index]);
        } else {
          this.#appendRow(overlay, char);
        }
      });
    } else {
      overlay.append(slot);
      this.#appendRow(roll, top);
      this.#appendRow(roll, bottom);
    }
    element.dataset.isbfCountRolling = "";
    this.#animation = roll.animate(
      [
        { transform: `translateY(${up ? "0" : "-1em"})` },
        { transform: `translateY(${up ? "-1em" : "0"})` },
      ],
      { duration: DURATION, easing: "cubic-bezier(0.23, 1, 0.32, 1)" }
    );
    const animation = this.#animation;
    animation.finished.then(
      () => {
        if (this.#animation === animation) {
          this.cancel();
        }
      },
      () => {}
    );
  }

  #appendRow(parent, text) {
    const row = document.createElement("span");
    row.textContent = text;
    parent.append(row);
  }
}
