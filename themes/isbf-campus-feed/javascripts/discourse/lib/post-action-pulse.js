const DURATION = 560;
const OUT = 0.4;
const DOT = 0.3;
const OVERSHOOT = 1.7;
const BEAT = 0.03;

export function formatActionCount(value, format = "compact") {
  const count = Math.max(0, Number(value) || 0);
  if (!count) {
    return "";
  }
  return format === "integer"
    ? String(count)
    : new Intl.NumberFormat(undefined, { notation: "compact" }).format(count);
}

export function actionSwell(t) {
  if (t <= 0) {
    return 0;
  }
  if (t < OUT) {
    return 1 - (1 - t / OUT) ** 3;
  }
  const u = (t - OUT) / (1 - OUT) - 1;
  return -((OVERSHOOT + 1) * u ** 3 + OVERSHOOT * u ** 2);
}

export default class PostActionPulse {
  #active = new Map();
  #frames = new Set();
  #pending = new Map();
  #pointer;
  #root;

  mount(root) {
    this.#root = root;
    const listeners = new AbortController();
    const options = { capture: true, signal: listeners.signal };
    const motion = window.matchMedia("(prefers-reduced-motion: reduce)");
    const stop = () => this.#stop();
    const down = (event) => {
      const target = this.#target(event);
      if (!target || event.button !== 0 || event.isPrimary === false) {
        return;
      }
      this.#pointer = target.button;
      if (!motion.matches) {
        this.#cancel(target.button);
        target.button.dataset.isbfPulsePressed = "";
        target.button.style.transform = "scale(0.97)";
      }
    };
    const up = () => this.#release();
    const cancel = () => {
      this.#release();
      this.#pointer = null;
    };
    const click = (event) => {
      const target = this.#target(event);
      if (!target) {
        return;
      }
      const pointer =
        this.#pointer === target.button &&
        event.detail !== 0 &&
        !motion.matches;
      cancel();
      this.#pending.set(target.kind, {
        from: Number(target.action.dataset.isbfActionCount) || 0,
        pointer,
        consumed: false,
      });
      this.#cancel(target.button);
      if (pointer) {
        this.#run(target.button);
      }
    };

    root.addEventListener("pointerdown", down, options);
    root.addEventListener("pointerup", up, options);
    root.addEventListener("pointercancel", cancel, options);
    root.addEventListener("pointerleave", up, options);
    root.addEventListener("keydown", cancel, options);
    root.addEventListener("click", click, options);
    window.addEventListener("pointerup", up, { signal: listeners.signal });
    window.addEventListener("blur", cancel, { signal: listeners.signal });
    motion.addEventListener("change", stop);

    return () => {
      listeners.abort();
      motion.removeEventListener("change", stop);
      this.#stop();
      this.#root = null;
    };
  }

  settle(kind) {
    const pending = this.#pending.get(kind);
    if (!pending) {
      return;
    }
    // Let the model's render finish before ending the local count transition.
    const frame = requestAnimationFrame(() => {
      this.#frames.delete(frame);
      if (this.#pending.get(kind) === pending) {
        this.#pending.delete(kind);
      }
    });
    this.#frames.add(frame);
  }

  takeCountTransition(kind, previous, next) {
    const pending = this.#pending.get(kind);
    const from = previous ?? pending?.from;
    if (!pending?.pointer || pending.consumed || from === next) {
      return null;
    }
    pending.consumed = true;
    return { from, to: next };
  }

  #cancel(button) {
    const running = this.#active.get(button);
    if (running) {
      cancelAnimationFrame(running.frame);
      running.icon.style.transform = "";
      this.#active.delete(button);
    }
    button.style.transform = "";
    delete button.dataset.isbfPulseRunning;
    delete button.dataset.isbfPulsePressed;
  }

  #release() {
    if (this.#pointer) {
      delete this.#pointer.dataset.isbfPulsePressed;
      if (!this.#active.has(this.#pointer)) {
        this.#pointer.style.transform = "";
      }
    }
  }

  #run(button) {
    const icon = button.querySelector(".d-icon");
    if (!icon) {
      return;
    }
    const running = { icon, frame: 0 };
    const started = performance.now();
    button.dataset.isbfPulseRunning = "";
    this.#active.set(button, running);
    const tick = (now) => {
      const currentIcon = button.querySelector(".d-icon");
      if (currentIcon && currentIcon !== running.icon) {
        running.icon.style.transform = "";
        running.icon = currentIcon;
      }
      const t = Math.min(1, (now - started) / DURATION);
      const swell = actionSwell(t);
      running.icon.style.transform = `scale(${1 - (1 - DOT) * swell})`;
      button.style.transform = `scale(${1 - BEAT * swell})`;
      if (t < 1) {
        running.frame = requestAnimationFrame(tick);
      } else {
        this.#cancel(button);
      }
    };
    running.frame = requestAnimationFrame(tick);
  }

  #stop() {
    this.#release();
    this.#pointer = null;
    for (const button of this.#active.keys()) {
      this.#cancel(button);
    }
    for (const frame of this.#frames) {
      cancelAnimationFrame(frame);
    }
    this.#frames.clear();
    this.#pending.clear();
  }

  #target(event) {
    const button = event.target.closest?.("button");
    const action = button?.closest("[data-isbf-post-action]");
    if (
      !button ||
      !action ||
      !this.#root.contains(button) ||
      button.disabled ||
      button.getAttribute("aria-disabled") === "true" ||
      button.classList.contains("like-count")
    ) {
      return null;
    }
    return { button, action, kind: action.dataset.isbfPostAction };
  }
}
