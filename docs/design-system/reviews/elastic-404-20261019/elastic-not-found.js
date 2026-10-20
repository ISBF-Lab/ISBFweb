const RECORD_KEY = "discourse:404:paddle:v1:best-ms";
const HEIGHT = 2 / 3;
const BALL_RADIUS = 0.018;
const PADDLE_HALF = 0.115;
const PADDLE_TOP = HEIGHT - 0.055;
const SPEED = 0.48;
const mounted = new WeakMap();

export function formatTime(milliseconds) {
  const tenths = Math.floor(Math.max(0, milliseconds) / 100);
  const minutes = Math.floor(tenths / 600);
  const seconds = Math.floor((tenths % 600) / 10);
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}.${tenths % 10}`;
}

export class BestTime {
  value = 0;

  #storage;

  constructor(storage) {
    this.#storage = storage;
    this.value = this.#read();
  }

  save(milliseconds) {
    if (!Number.isFinite(milliseconds) || milliseconds < 0) {
      return this.value;
    }
    this.value = Math.max(this.value, this.#read(), Math.floor(milliseconds));
    try {
      this.#storage?.setItem(RECORD_KEY, String(this.value));
    } catch {
      // Storage can be unavailable even after a successful read.
    }
    return this.value;
  }

  #read() {
    try {
      const value = Number(this.#storage?.getItem(RECORD_KEY));
      return Number.isFinite(value) && value >= 0 ? value : 0;
    } catch {
      return 0;
    }
  }
}

export class PaddleGame {
  ball = { x: 0.5, y: 0.36, vx: 0.22, vy: -Math.sqrt(SPEED ** 2 - 0.22 ** 2) };
  elapsedMs = 0;
  paddle = 0.5;
  state = "ready";

  #lastTime = 0;

  start(now) {
    this.ball = { x: 0.5, y: 0.36, vx: 0.22, vy: -Math.sqrt(SPEED ** 2 - 0.22 ** 2) };
    this.elapsedMs = 0;
    this.paddle = 0.5;
    this.state = "playing";
    this.#lastTime = now;
  }

  move(position) {
    this.paddle = Math.min(1 - PADDLE_HALF, Math.max(PADDLE_HALF, position));
  }

  pause() {
    if (this.state === "playing") {
      this.state = "paused";
    }
  }

  resume(now) {
    if (this.state === "paused") {
      this.#lastTime = now;
      this.state = "playing";
    }
  }

  advance(now, direction = 0) {
    if (this.state !== "playing") {
      return;
    }
    let remaining = Math.max(0, (now - this.#lastTime) / 1000);
    this.#lastTime = now;
    if (remaining > 0.25) {
      this.pause();
      return;
    }
    while (remaining > 0 && this.state === "playing") {
      const delta = Math.min(remaining, 1 / 120);
      remaining -= delta;
      this.move(this.paddle + direction * delta * 0.85);
      this.#step(delta);
      this.elapsedMs += delta * 1000;
    }
  }

  #step(delta) {
    const ball = this.ball;
    const oldY = ball.y;
    ball.x += ball.vx * delta;
    ball.y += ball.vy * delta;
    if (ball.x < BALL_RADIUS || ball.x > 1 - BALL_RADIUS) {
      ball.x = Math.min(1 - BALL_RADIUS, Math.max(BALL_RADIUS, ball.x));
      ball.vx *= -1;
    }
    if (ball.y < BALL_RADIUS) {
      ball.y = BALL_RADIUS;
      ball.vy = Math.abs(ball.vy);
    }
    if (
      ball.vy > 0 &&
      oldY + BALL_RADIUS <= PADDLE_TOP &&
      ball.y + BALL_RADIUS >= PADDLE_TOP &&
      Math.abs(ball.x - this.paddle) <= PADDLE_HALF + BALL_RADIUS
    ) {
      const offset = Math.max(-1, Math.min(1, (ball.x - this.paddle) / PADDLE_HALF));
      const angle = offset * (Math.PI / 3);
      ball.vx = Math.sin(angle) * SPEED;
      if (Math.abs(ball.vx) < 0.1) {
        ball.vx = ball.vx < 0 ? -0.1 : 0.1;
      }
      ball.vy = -Math.sqrt(SPEED ** 2 - ball.vx ** 2);
      ball.y = PADDLE_TOP - BALL_RADIUS;
    }
    if (ball.y - BALL_RADIUS > HEIGHT) {
      this.state = "over";
    }
  }
}

class NotFoundInteraction {
  #announce;
  #canvas;
  #context;
  #current;
  #destroyed = false;
  #drag = null;
  #events = new AbortController();
  #frameId = null;
  #game = null;
  #glyphs = [];
  #glyphKey = "";
  #height = 0;
  #keys = new Set();
  #lastFrame = 0;
  #media;
  #observer;
  #palette;
  #pointer = null;
  #record;
  #revealed = false;
  #root;
  #spring = 0;
  #stage;
  #velocity = 0;
  #width = 0;
  #zero = 0;

  constructor(root, announce) {
    this.#root = root;
    this.#announce = announce;
    this.#stage = root.querySelector("[data-stage]");
    this.#canvas = root.querySelector("[data-canvas]");
    this.#context = this.#canvas.getContext("2d");
    if (!this.#context) {
      throw new Error("Canvas is unavailable");
    }
    this.#current = root.querySelector("[data-current]");
    this.#media = matchMedia("(prefers-reduced-motion: reduce)");
    let storage;
    try {
      storage = window.localStorage;
    } catch {
      storage = null;
    }
    this.#record = new BestTime(storage);
    root.querySelector("[data-best]").textContent = formatTime(this.#record.value);
    this.#listen(this.#stage, "pointermove", (event) => this.#pointerMove(event));
    this.#listen(this.#stage, "pointerleave", () => {
      this.#pointer = null;
      this.#schedule();
    });
    const reveal = root.querySelector("[data-reveal]");
    reveal.hidden = false;
    this.#listen(reveal, "pointerdown", (event) => this.#pointerDown(event));
    this.#listen(reveal, "pointerup", (event) => this.#pointerUp(event));
    this.#listen(reveal, "pointercancel", (event) => this.#pointerUp(event));
    this.#listen(reveal, "lostpointercapture", () => this.#releaseDrag());
    this.#listen(reveal, "click", (event) => {
      if (event.detail === 0) {
        this.#reveal();
      }
    });
    this.#listen(root.querySelector("[data-play]"), "click", () => this.#openGame());
    this.#listen(root.querySelector("[data-start]"), "click", () => this.#start());
    this.#listen(root.querySelector("[data-pause]"), "click", () => {
      if (this.#game?.state === "playing") {
        this.#pause();
      } else {
        this.#start();
      }
    });
    this.#listen(root.querySelector("[data-exit]"), "click", () => this.#exit());
    this.#listen(root, "keydown", (event) => this.#keyDown(event));
    this.#listen(root, "keyup", (event) => this.#keys.delete(event.key));
    this.#listen(document, "visibilitychange", () => {
      if (document.hidden) {
        this.#pause(false);
      }
    });
    this.#listen(window, "blur", () => this.#pause(false));
    this.#listen(window, "pagehide", () => this.#pause(false));
    this.#listen(this.#media, "change", () => this.#schedule());
    this.#listen(matchMedia("(prefers-color-scheme: dark)"), "change", () => this.#resize());
    this.#observer = new ResizeObserver(() => this.#resize());
    this.#observer.observe(this.#stage);
    document.body.classList.add("elastic-not-found-page");
    root.classList.add("--enhanced");
    this.#resize();
    document.fonts?.ready.then(() => {
      if (!this.#destroyed) {
        this.#glyphKey = "";
        this.#schedule();
      }
    });
  }

  destroy() {
    this.#destroyed = true;
    this.#events.abort();
    this.#observer.disconnect();
    cancelAnimationFrame(this.#frameId);
    this.#keys.clear();
    this.#releaseDrag();
    this.#root.classList.remove("--enhanced");
    document.body.classList.remove("elastic-not-found-page");
    mounted.delete(this.#root);
  }

  #listen(target, name, callback) {
    target.addEventListener(name, callback, { signal: this.#events.signal });
  }

  #keyDown(event) {
    if (!this.#game) {
      return;
    }
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      event.preventDefault();
      this.#keys.add(event.key);
    } else if (event.key === "Escape") {
      event.preventDefault();
      this.#pause();
    }
  }

  #pointerDown(event) {
    if (event.button !== 0 || this.#game) {
      return;
    }
    event.preventDefault();
    event.currentTarget.setPointerCapture(event.pointerId);
    this.#drag = { id: event.pointerId, start: event.clientX };
    this.#root.classList.add("--dragging");
  }

  #pointerMove(event) {
    const bounds = this.#stage.getBoundingClientRect();
    const x = event.clientX - bounds.left;
    if (this.#game) {
      this.#game.move(x / this.#width);
      if (this.#game.state !== "playing") {
        this.#draw();
      }
      return;
    }
    if (this.#drag?.id === event.pointerId) {
      this.#zero = Math.max(-this.#width * 0.24, Math.min(this.#width * 0.24, event.clientX - this.#drag.start));
      if (Math.abs(this.#zero) > this.#width * 0.11) {
        this.#reveal(false);
      }
    }
    const previous = this.#pointer?.x ?? x;
    this.#pointer = { x, y: event.clientY - bounds.top };
    this.#velocity += Math.max(-12, Math.min(12, x - previous)) * 0.4;
    this.#schedule();
  }

  #pointerUp(event) {
    if (this.#drag?.id !== event.pointerId) {
      return;
    }
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
    this.#releaseDrag();
  }

  #releaseDrag() {
    this.#drag = null;
    this.#root.classList.remove("--dragging");
    this.#schedule();
  }

  #reveal(focus = true) {
    if (!this.#revealed) {
      this.#revealed = true;
      this.#root.querySelector("[data-play]").hidden = false;
      this.#announce?.(this.#labels().foundLabel);
    }
    if (focus) {
      this.#root.querySelector("[data-play]").focus({ preventScroll: true });
    }
  }

  #labels() {
    return this.#root.querySelector("[data-announcement]").dataset;
  }

  #openGame() {
    this.#game = new PaddleGame();
    this.#root.querySelector("[data-reveal]").hidden = true;
    this.#root.querySelector("[data-play]").hidden = true;
    this.#root.querySelector("[data-game]").hidden = false;
    this.#stage.tabIndex = 0;
    this.#stage.setAttribute("role", "group");
    this.#stage.setAttribute("aria-label", this.#root.querySelector(".elastic-not-found__instructions").textContent);
    this.#update();
    this.#draw();
    this.#root.querySelector("[data-start]").focus({ preventScroll: true });
  }

  #start() {
    if (!this.#game) {
      return;
    }
    if (this.#game.state === "paused") {
      this.#game.resume(performance.now());
    } else {
      this.#game.start(performance.now());
    }
    this.#update();
    this.#stage.focus({ preventScroll: true });
    this.#schedule();
  }

  #pause(focus = true) {
    this.#keys.clear();
    if (this.#game?.state !== "playing") {
      return;
    }
    this.#game.pause();
    this.#update();
    this.#draw();
    if (focus) {
      this.#root.querySelector("[data-start]").focus({ preventScroll: true });
    }
  }

  #exit() {
    if (this.#game?.state === "playing" || this.#game?.state === "paused") {
      this.#saveRecord();
    }
    this.#game = null;
    this.#keys.clear();
    this.#pointer = null;
    this.#zero = this.#spring = this.#velocity = 0;
    this.#root.removeAttribute("data-game-state");
    this.#root.querySelector("[data-game]").hidden = true;
    this.#root.querySelector("[data-overlay]").hidden = true;
    this.#root.querySelector("[data-reveal]").hidden = false;
    this.#root.querySelector("[data-play]").hidden = false;
    this.#stage.removeAttribute("tabindex");
    this.#stage.removeAttribute("role");
    this.#stage.removeAttribute("aria-label");
    this.#root.querySelector("[data-play]").focus({ preventScroll: true });
    this.#schedule();
  }

  #saveRecord() {
    this.#record.save(this.#game.elapsedMs);
    this.#root.querySelector("[data-best]").textContent = formatTime(this.#record.value);
  }

  #update() {
    const state = this.#game.state;
    const start = this.#root.querySelector("[data-start]");
    const pause = this.#root.querySelector("[data-pause]");
    const status = this.#root.querySelector("[data-status]");
    const labels = this.#labels();
    this.#root.dataset.gameState = state;
    this.#root.querySelector("[data-overlay]").hidden = state === "playing";
    this.#current.textContent = formatTime(this.#game.elapsedMs);
    status.textContent = labels[state === "over" ? "overLabel" : state === "paused" ? "pausedLabel" : "readyLabel"];
    start.textContent = start.dataset[state === "over" ? "retryLabel" : state === "paused" ? "resumeLabel" : "startLabel"];
    pause.textContent = pause.dataset[state === "paused" ? "resumeLabel" : "pauseLabel"];
    pause.hidden = !["playing", "paused"].includes(state);
    if (state !== "playing") {
      this.#announce?.(status.textContent);
    }
  }

  #resize() {
    const width = this.#stage.getBoundingClientRect().width;
    if (!width) {
      return;
    }
    if (this.#width && Math.abs(width - this.#width) > 1) {
      this.#pause(false);
    }
    this.#width = width;
    this.#height = width * HEIGHT;
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    this.#canvas.width = Math.round(width * ratio);
    this.#canvas.height = Math.round(this.#height * ratio);
    this.#context.setTransform(ratio, 0, 0, ratio, 0, 0);
    this.#glyphKey = "";
    this.#draw();
  }

  #schedule() {
    if (!this.#destroyed && this.#frameId === null) {
      this.#frameId = requestAnimationFrame((now) => this.#frame(now));
    }
  }

  #frame(now) {
    this.#frameId = null;
    if (this.#destroyed) {
      return;
    }
    if (this.#game) {
      if (this.#game.state === "playing") {
        const direction = Number(this.#keys.has("ArrowRight")) - Number(this.#keys.has("ArrowLeft"));
        this.#game.advance(now, direction);
        this.#current.textContent = formatTime(this.#game.elapsedMs);
        if (this.#game.state !== "playing") {
          if (this.#game.state === "over") {
            this.#saveRecord();
          }
          this.#update();
          this.#root.querySelector("[data-start]").focus({ preventScroll: true });
        }
      }
      this.#draw();
      if (this.#game.state === "playing") {
        this.#schedule();
      }
    } else {
      const factor = Math.min(2, Math.max(0.25, (now - this.#lastFrame) / (1000 / 60)));
      if (this.#media.matches) {
        this.#spring = this.#velocity = 0;
        if (!this.#drag) {
          this.#zero = 0;
        }
      } else {
        this.#velocity = (this.#velocity - this.#spring * 0.12 * factor) * 0.75 ** factor;
        this.#spring += this.#velocity * factor;
        if (!this.#drag) {
          this.#zero *= 0.73 ** factor;
        }
      }
      this.#draw();
      if (Math.abs(this.#spring) + Math.abs(this.#velocity) + (!this.#drag ? Math.abs(this.#zero) : 0) > 0.1) {
        this.#schedule();
      }
    }
    this.#lastFrame = now;
  }

  #draw() {
    if (!this.#width || this.#destroyed) {
      return;
    }
    const style = getComputedStyle(this.#root);
    this.#palette = {
      accent: style.getPropertyValue("--elastic-404-accent").trim(),
      text: style.getPropertyValue("--elastic-404-text").trim(),
      border: style.getPropertyValue("--elastic-404-border").trim(),
      font: style.fontFamily,
    };
    this.#context.clearRect(0, 0, this.#width, this.#height);
    if (this.#game) {
      this.#drawGame();
    } else {
      this.#drawDigits();
    }
  }

  #drawDigits() {
    const width = this.#width;
    const height = this.#height;
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    const key = `${width}:${ratio}:${this.#palette.accent}:${this.#palette.font}`;
    if (key !== this.#glyphKey) {
      this.#glyphKey = key;
      this.#glyphs = ["4", "0", "4"].map((digit) => {
        const canvas = document.createElement("canvas");
        canvas.width = Math.ceil((width / 3) * ratio);
        canvas.height = Math.ceil(height * ratio);
        const context = canvas.getContext("2d");
        context.scale(ratio, ratio);
        context.fillStyle = this.#palette.accent;
        context.font = `750 ${width * 0.52}px ${this.#palette.font}`;
        context.textAlign = "center";
        context.fillText(digit, width / 6, height * 0.76);
        return canvas;
      });
    }
    for (let index = 0; index < 3; index++) {
      const glyph = this.#glyphs[index];
      const offset = index === 1 ? this.#zero : 0;
      for (let row = 0; row < height; row += 3) {
        const distance = this.#pointer ? (row - this.#pointer.y) / (width * 0.17) : 0;
        const horizontal = this.#pointer ? (this.#pointer.x - (index + 0.5) * width / 3) / (width / 3) : 0;
        const influence = this.#pointer ? Math.exp(-distance * distance * 2 - horizontal * horizontal) : 1;
        const shift = this.#media.matches ? 0 : this.#spring * influence;
        const slice = Math.min(3, height - row);
        this.#context.drawImage(glyph, 0, row * ratio, glyph.width, Math.min((slice + 0.5) * ratio, glyph.height - row * ratio), index * width / 3 + offset + shift, row, width / 3, slice + 0.5);
      }
    }
  }

  #drawGame() {
    const context = this.#context;
    const width = this.#width;
    context.fillStyle = this.#palette.text;
    context.beginPath();
    context.roundRect((this.#game.paddle - PADDLE_HALF) * width, PADDLE_TOP * width, PADDLE_HALF * 2 * width, 0.013 * width, 0.0065 * width);
    context.fill();
    context.fillStyle = this.#palette.accent;
    context.font = `750 ${BALL_RADIUS * 2.8 * width}px ${this.#palette.font}`;
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText("0", this.#game.ball.x * width, this.#game.ball.y * width);
    context.textBaseline = "alphabetic";
  }
}

export function mountNotFound(root, { announce } = {}) {
  if (mounted.has(root)) {
    return mounted.get(root);
  }
  let interaction;
  try {
    interaction = new NotFoundInteraction(root, announce);
  } catch {
    return () => {};
  }
  const destroy = () => interaction.destroy();
  mounted.set(root, destroy);
  return destroy;
}

if (typeof document !== "undefined" && document.body?.classList.contains("no-ember")) {
  const root = document.querySelector("[data-elastic-not-found]");
  if (root) {
    mountNotFound(root);
  }
}
