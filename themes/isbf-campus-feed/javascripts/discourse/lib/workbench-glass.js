import { workbenchColors, workbenchInk } from "./workbench-colors";
import { createWorkbenchRenderer } from "./workbench-glass-renderer";

const clamp = (value, min = 0, max = 1) => Math.min(max, Math.max(min, value));
const easeOut = (value) => 1 - (1 - clamp(value)) ** 3;
const smooth = (min, max, value) => {
  const progress = clamp((value - min) / (max - min));
  return progress * progress * (3 - 2 * progress);
};
const SPRINGS = [
  ["entry", 60, 15.5],
  ["hover", 170, 24],
  ["x", 90, 19],
  ["y", 90, 19],
];

export function workbenchLayout(width) {
  let columns = width >= 570 ? 5 : width >= 400 ? 4 : width >= 200 ? 3 : 2;
  const gap = width >= 570 ? 24 : width >= 400 ? 22 : 18;
  const preferred = width >= 570 ? 108 : width >= 400 ? 96 : 86;
  while (columns > 1 && (width - (columns - 1) * gap - 8) / columns < 86) {
    columns--;
  }
  const size = Math.max(
    48,
    Math.min(preferred, Math.floor((width - (columns - 1) * gap - 8) / columns))
  );
  return { columns, gap, size };
}

function visualState(state, size) {
  const entry = clamp(state.entry.value);
  const hover = state.hover.value;
  const x = state.x.value;
  const y = state.y.value;
  const light = [-0.55 + x * 0.35, -0.83 + y * 0.35];
  const length = Math.hypot(...light) || 1;
  const lift = -0.14 * size * hover;
  return {
    lift,
    scale: 0.92 + 0.08 * easeOut(entry),
    faceY: lift + (1 - easeOut((entry - 0.25) / 0.75)) * 0.1 * size,
    faceAlpha: smooth(0.3, 0.85, entry),
    glassAlpha: smooth(0, 0.55, entry),
    plateAlpha: smooth(0, 0.35, entry),
    offset: 0.13 * size * easeOut((entry - 0.18) / 0.82),
    shift: [-x * 0.07 * size, -y * 0.07 * size],
    light: light.map((value) => value / length),
    bend: 1 + 1.2 * (1 - easeOut(entry)),
    glow: 1 + 0.25 * hover,
  };
}

export function mountWorkbenchGlass(stage, settings = {}) {
  if (!stage.querySelectorAll("[data-workbench-key]").length) {
    return;
  }
  const window = stage.ownerDocument.defaultView;
  const scope = new window.AbortController();
  const desktop = window.matchMedia("(width > 600px)");
  const workbench = stage.closest?.(".isbf-v2-workbench");
  let destroy;
  const update = () => {
    destroy?.();
    destroy = undefined;
    const selected =
      settings[
        desktop.matches ? "workbench_layout_desktop" : "workbench_layout_mobile"
      ];
    const layout =
      selected === "glass" || (selected !== "traditional" && desktop.matches)
        ? "glass"
        : "traditional";
    stage.dataset.workbenchLayout = layout;
    if (workbench) {
      workbench.dataset.workbenchLayout = layout;
    }
    if (layout === "glass") {
      destroy = mountGlass(stage, desktop.matches ? settings : {});
    }
  };
  desktop.addEventListener("change", update, { signal: scope.signal });
  update();
  return () => {
    scope.abort();
    destroy?.();
    delete stage.dataset.workbenchLayout;
    if (workbench) {
      delete workbench.dataset.workbenchLayout;
    }
  };
}

function mountGlass(stage, settings) {
  const document = stage.ownerDocument;
  const window = document.defaultView;
  const grid = stage.querySelector(".isbf-workbench-grid__items");
  const canvas = stage.querySelector("canvas");
  const items = [...stage.querySelectorAll("[data-workbench-key]")];
  const panel = stage.closest?.(".isbf-v2-workbench__panel");
  if (!grid || !canvas || !items.length) {
    return;
  }

  const scope = new window.AbortController();
  const motion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const systemPalette = window.matchMedia("(prefers-color-scheme: dark)");
  const reader = document.createElement("canvas").getContext("2d", {
    willReadFrequently: true,
  });
  let renderer = reader ? createWorkbenchRenderer(canvas) : null;
  let destroyed = false;
  let frame = 0;
  let previousTime = 0;
  let introduced = false;
  let layout;
  let palette;
  const states = items.map((item) => ({
    layers: ["plate", "glass", "face", "label"].map((name) =>
      item.querySelector(`.isbf-workbench-grid__${name}`)
    ),
    delay: Infinity,
    ...Object.fromEntries(
      SPRINGS.map(([name]) => [
        name,
        {
          value: name === "entry" && (!renderer || motion.matches) ? 1 : 0,
          velocity: 0,
          target: name === "entry" && (!renderer || motion.matches) ? 1 : 0,
        },
      ])
    ),
  }));

  const on = (target, name, callback, options = {}) =>
    target.addEventListener(name, callback, {
      ...options,
      signal: scope.signal,
    });
  const setProperty = (element, name, value) => {
    if (element.style.getPropertyValue(name) !== value) {
      element.style.setProperty(name, value);
    }
  };
  const readColor = (color) => {
    reader.clearRect(0, 0, 1, 1);
    reader.fillStyle = "transparent";
    reader.fillStyle = color;
    reader.fillRect(0, 0, 1, 1);
    return [...reader.getImageData(0, 0, 1, 1).data];
  };
  const readPalette = () => {
    const styles = window.getComputedStyle(stage);
    const background = reader
      ? readColor(styles.getPropertyValue("--isbf-v2-surface"))
      : [255, 255, 255];
    const brightness =
      (background[0] * 0.2126 +
        background[1] * 0.7152 +
        background[2] * 0.0722) /
      255;
    const scheme = styles.getPropertyValue("--scheme-type").trim();
    const dark = scheme === "dark" || (scheme !== "light" && brightness < 0.5);
    const colors = workbenchColors(
      settings,
      dark ? "dark" : "light",
      items.map((item) => item.dataset.workbenchKey)
    );
    const customColor = (element, name, value) => {
      if (!element) {
        return;
      }
      if (value) {
        setProperty(element, name, value);
      } else {
        element.style.removeProperty(name);
      }
    };
    customColor(panel, "--isbf-workbench-custom-panel", colors.panel);
    const rgba = (color) =>
      color.match(/../g).map((channel) => parseInt(channel, 16));
    const cards = items.map((item, index) => {
      customColor(item, "--isbf-workbench-custom-plate", colors.plates[index]);
      const plate = colors.plates[index]
        ? [...rgba(colors.plates[index].slice(1)), 255]
        : reader
          ? readColor(
              window.getComputedStyle(states[index].layers[0]).backgroundColor
            )
          : background;
      customColor(item, "--isbf-workbench-card-ink", workbenchInk(plate));
      return { plate, tint: plate.slice(0, 3).map((channel) => channel / 255) };
    });
    palette = { cards, shade: dark ? 0.35 : 0.22 };
  };
  const render = () => {
    if (destroyed || !layout) {
      return;
    }
    const visuals = states.map((state) => visualState(state, layout.size));
    visuals.forEach((visual, index) => {
      const [plate, glass, face, label] = states[index].layers;
      plate.style.transform = `translate(${visual.shift[0]}px, ${visual.shift[1]}px) translate(${visual.offset}px, ${-visual.offset}px)`;
      plate.style.opacity = visual.plateAlpha;
      glass.style.transform = `translateY(${visual.lift}px) scale(${visual.scale})`;
      glass.style.opacity = visual.glassAlpha;
      face.style.transform = `translateY(${visual.faceY}px)`;
      face.style.opacity = visual.faceAlpha;
      label.style.opacity = 1;
    });
    renderer?.draw(layout, visuals, palette);
    stage.classList.toggle("has-webgl", !!renderer);
  };
  const stopFrame = () => {
    window.cancelAnimationFrame(frame);
    frame = 0;
    previousTime = 0;
  };
  const finishMotion = () => {
    stopFrame();
    introduced = true;
    for (const state of states) {
      for (const [name] of SPRINGS) {
        state[name].value = state[name].target = name === "entry" ? 1 : 0;
        state[name].velocity = 0;
      }
    }
    render();
  };
  const tick = (milliseconds) => {
    frame = 0;
    if (destroyed) {
      return;
    }
    if (motion.matches) {
      finishMotion();
      return;
    }
    const time = milliseconds / 1000;
    const elapsed = previousTime
      ? Math.min(1 / 30, time - previousTime)
      : 1 / 60;
    previousTime = time;
    const steps = Math.max(1, Math.ceil(elapsed * 240));
    const delta = elapsed / steps;
    let pending = false;
    for (const state of states) {
      if (introduced && time >= state.delay) {
        state.entry.target = 1;
      }
      pending ||= introduced && state.entry.target === 0;
      for (const [name, stiffness, damping] of SPRINGS) {
        const spring = state[name];
        for (let step = 0; step < steps; step++) {
          spring.velocity +=
            (stiffness * (spring.target - spring.value) -
              damping * spring.velocity) *
            delta;
          spring.value += spring.velocity * delta;
        }
        if (
          Math.abs(spring.target - spring.value) < 0.0005 &&
          Math.abs(spring.velocity) < 0.001
        ) {
          spring.value = spring.target;
          spring.velocity = 0;
        } else {
          pending = true;
        }
      }
    }
    render();
    if (pending) {
      schedule();
    } else {
      previousTime = 0;
    }
  };
  const schedule = () => {
    if (
      !destroyed &&
      !frame &&
      !document.hidden &&
      renderer &&
      !motion.matches
    ) {
      frame = window.requestAnimationFrame(tick);
    }
  };
  const resize = () => {
    if (destroyed) {
      return;
    }
    const dimensions = workbenchLayout(stage.clientWidth);
    const { size, gap, columns } = dimensions;
    setProperty(grid, "--isbf-workbench-size", `${size}px`);
    setProperty(grid, "--isbf-workbench-gap", `${gap}px`);
    setProperty(grid, "--isbf-workbench-columns", `${columns}`);
    const margin = Math.ceil(size * 0.7);
    const width = Math.max(1, grid.clientWidth + margin * 2);
    const height = Math.max(1, grid.clientHeight + margin * 2);
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    layout = {
      ...dimensions,
      width,
      height,
      dpr,
      centers: items.map((item) => [
        item.offsetLeft + item.offsetWidth / 2 + margin,
        item.offsetTop + item.offsetHeight / 2 + margin,
      ]),
    };
    canvas.style.left = `${-margin}px`;
    canvas.style.top = `${-margin}px`;
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    if (canvas.width !== Math.round(width * dpr)) {
      canvas.width = Math.round(width * dpr);
    }
    if (canvas.height !== Math.round(height * dpr)) {
      canvas.height = Math.round(height * dpr);
    }
    readPalette();
    render();
  };
  const startIntro = () => {
    if (introduced) {
      return;
    }
    introduced = true;
    const time = window.performance.now() / 1000;
    states.forEach((state, index) => (state.delay = time + index * 0.07));
    schedule();
  };
  const clearHover = (state) => {
    state.hover.target = state.x.target = state.y.target = 0;
    schedule();
  };

  items.forEach((item, index) => {
    if (!item.hasAttribute("href")) {
      return;
    }
    const state = states[index];
    const hover = () => {
      if (!renderer) {
        return;
      }
      if (motion.matches) {
        finishMotion();
        return;
      }
      startIntro();
      state.entry.value = state.entry.target = 1;
      state.hover.target = 1;
      schedule();
    };
    on(item, "pointerenter", (event) => {
      if (event.pointerType !== "touch") {
        hover();
      }
    });
    on(item, "pointermove", (event) => {
      if (!renderer || motion.matches || event.pointerType === "touch") {
        return;
      }
      const bounds = item.getBoundingClientRect();
      state.x.target = clamp(
        ((event.clientX - bounds.left) / bounds.width) * 2 - 1,
        -1,
        1
      );
      state.y.target = clamp(
        ((event.clientY - bounds.top) / bounds.height) * 2 - 1,
        -1,
        1
      );
      schedule();
    });
    on(item, "pointerleave", () => clearHover(state));
    on(item, "pointercancel", () => clearHover(state));
    on(item, "focus", () => {
      if (item.matches(":focus-visible")) {
        hover();
      }
    });
    on(item, "blur", () => clearHover(state));
  });

  on(canvas, "webglcontextlost", (event) => {
    event.preventDefault();
    renderer?.destroy();
    renderer = null;
    finishMotion();
  });
  on(canvas, "webglcontextrestored", () => {
    if (reader) {
      renderer = createWorkbenchRenderer(canvas);
      resize();
    }
  });
  on(motion, "change", finishMotion);
  on(systemPalette, "change", resize);
  on(
    document,
    "load",
    (event) => {
      if (event.target.tagName === "LINK") {
        resize();
      }
    },
    { capture: true }
  );
  on(document, "visibilitychange", () => {
    if (document.hidden) {
      stopFrame();
    } else {
      schedule();
    }
  });
  if (document.fonts) {
    document.fonts.ready.then(resize);
    on(document.fonts, "loadingdone", resize);
  }

  const sizeObserver = new window.ResizeObserver(resize);
  sizeObserver.observe(stage);
  sizeObserver.observe(grid);
  const paletteObserver = new window.MutationObserver(resize);
  paletteObserver.observe(document.documentElement, { attributes: true });
  paletteObserver.observe(document.head, {
    attributes: true,
    childList: true,
    subtree: true,
    attributeFilter: ["href", "media", "disabled"],
  });
  let visibilityObserver;
  if (renderer && !motion.matches && window.IntersectionObserver) {
    visibilityObserver = new window.IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          startIntro();
          visibilityObserver.disconnect();
        }
      },
      { threshold: 0.15 }
    );
    visibilityObserver.observe(stage);
  } else {
    finishMotion();
  }
  resize();

  return () => {
    destroyed = true;
    stopFrame();
    scope.abort();
    sizeObserver.disconnect();
    paletteObserver.disconnect();
    visibilityObserver?.disconnect();
    renderer?.destroy();
    canvas.width = canvas.height = 1;
    stage.classList.remove("has-webgl");
    panel?.style.removeProperty("--isbf-workbench-custom-panel");
    for (const item of items) {
      item.style.removeProperty("--isbf-workbench-custom-plate");
      item.style.removeProperty("--isbf-workbench-card-ink");
    }
    for (const name of ["width", "height", "left", "top"]) {
      canvas.style.removeProperty(name);
    }
    for (const state of states) {
      for (const layer of state.layers) {
        layer.style.removeProperty("opacity");
        layer.style.removeProperty("transform");
      }
    }
  };
}
