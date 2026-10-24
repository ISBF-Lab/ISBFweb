import { graphics } from "./workbench-graphics";

function target() {
  const listeners = new Map();
  return {
    addEventListener(name, callback, { signal } = {}) {
      if (!listeners.has(name)) {
        listeners.set(name, new Set());
      }
      listeners.get(name).add(callback);
      signal?.cleanup.push(() => listeners.get(name).delete(callback));
    },
    dispatch(name, event = {}) {
      for (const callback of listeners.get(name) || []) {
        callback(event);
      }
    },
    listenerCount() {
      return [...listeners.values()].reduce((sum, set) => sum + set.size, 0);
    },
  };
}

function style() {
  return new Proxy(
    {
      getPropertyValue(name) {
        return this[name] || "";
      },
      setProperty(name, value) {
        this[name] = value;
      },
      removeProperty(name) {
        delete this[name];
      },
    },
    {
      set(object, key, value) {
        object[key] = String(value);
        return true;
      },
    }
  );
}

export function workbenchStage({
  reduced = false,
  gpu = true,
  empty = false,
  desktop = true,
} = {}) {
  const gpuFixture = graphics();
  const frames = new Map();
  const observers = [];
  const targets = [];
  const makeTarget = () => {
    const result = target();
    targets.push(result);
    return result;
  };
  const motion = { ...makeTarget(), matches: reduced };
  const systemPalette = { ...makeTarget(), matches: true };
  const viewport = { ...makeTarget(), matches: desktop };
  let time = 1000;
  let nextFrame = 0;
  class Observer {
    constructor(callback) {
      this.callback = callback;
      this.disconnected = false;
      observers.push(this);
    }

    observe() {}
    disconnect() {
      this.disconnected = true;
    }
  }
  class VisibilityObserver extends Observer {}
  const window = {
    AbortController: class {
      signal = { cleanup: [] };

      abort() {
        this.signal.cleanup.forEach((cleanup) => cleanup());
      }
    },
    matchMedia: (query) =>
      query.includes("reduced-motion")
        ? motion
        : query.includes("600px")
          ? viewport
          : systemPalette,
    requestAnimationFrame(callback) {
      const id = ++nextFrame;
      frames.set(id, callback);
      return id;
    },
    cancelAnimationFrame: (id) => frames.delete(id),
    performance: { now: () => time },
    devicePixelRatio: 1,
    ResizeObserver: Observer,
    MutationObserver: Observer,
    IntersectionObserver: VisibilityObserver,
    getComputedStyle: () => ({
      backgroundColor: "rgb(105, 181, 230)",
      getPropertyValue: (name) =>
        name.includes("surface") ? "rgb(16, 20, 19)" : "rgb(114, 197, 250)",
    }),
  };
  const reader = {
    clearRect() {},
    fillRect() {},
    getImageData() {
      return { data: [...this.fillStyle.match(/\d+/g).map(Number), 255] };
    },
  };
  const document = {
    ...makeTarget(),
    defaultView: window,
    hidden: false,
    documentElement: {},
    head: {},
    createElement: () => ({ getContext: () => reader }),
  };
  const items = (empty ? [] : [true, false]).map((link, index) => {
    const layers = Object.fromEntries(
      ["plate", "glass", "face", "label"].map((name) => [
        `.isbf-workbench-grid__${name}`,
        { style: style(), offsetHeight: 16 },
      ])
    );
    return {
      ...makeTarget(),
      style: style(),
      dataset: { workbenchKey: index ? "courses" : "learning_resources" },
      layers,
      querySelector: (selector) => layers[selector],
      hasAttribute: (name) => name === "href" && link,
      matches: () => true,
      offsetLeft: index * 130,
      offsetTop: 0,
      offsetWidth: 108,
      offsetHeight: 108,
      getBoundingClientRect: () => ({
        left: 0,
        top: 0,
        width: 108,
        height: 108,
      }),
    };
  });
  const classes = new Set();
  const grid = { style: style(), clientWidth: 636, clientHeight: 108 };
  const canvas = {
    ...makeTarget(),
    ...gpuFixture.canvas,
    style: style(),
    getContext: () => (gpu ? gpuFixture.canvas.getContext() : null),
  };
  const stage = {
    dataset: {},
    ownerDocument: document,
    clientWidth: 640,
    classList: {
      toggle(name, enabled) {
        enabled ? classes.add(name) : classes.delete(name);
      },
      remove: (name) => classes.delete(name),
    },
    querySelector: (selector) => (selector === "canvas" ? canvas : grid),
    querySelectorAll: () => items,
  };
  return {
    stage,
    items,
    canvas,
    classes,
    motion,
    viewport,
    document,
    observers,
    calls: gpuFixture.calls,
    frames: () => frames.size,
    listeners: () =>
      targets.reduce((sum, entry) => sum + entry.listenerCount(), 0),
    show() {
      observers
        .find((observer) => observer instanceof VisibilityObserver)
        ?.callback([{ isIntersecting: true }]);
    },
    step() {
      time += 1000 / 60;
      const pending = [...frames.values()];
      frames.clear();
      pending.forEach((callback) => callback(time));
    },
    settle() {
      let steps = 0;
      while (frames.size && steps++ < 360) {
        this.step();
      }
      return steps;
    },
  };
}
