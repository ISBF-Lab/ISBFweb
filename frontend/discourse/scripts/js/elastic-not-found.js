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

  get speed() {
    return SPEED * Math.min(2, 1 + this.elapsedMs / 60000);
  }

  start(now) {
    this.ball = {
      x: 0.5,
      y: 0.36,
      vx: 0.22,
      vy: -Math.sqrt(SPEED ** 2 - 0.22 ** 2),
    };
    this.elapsedMs = 0;
    this.paddle = 0.5;
    this.state = "playing";
    this.#lastTime = now;
  }

  move(position) {
    this.paddle = Math.min(1 - PADDLE_HALF, Math.max(PADDLE_HALF, position));
  }

  finish() {
    if (this.state === "playing") {
      this.state = "over";
    }
  }

  advance(now, direction = 0) {
    if (this.state !== "playing") {
      return;
    }
    let remaining = Math.max(0, (now - this.#lastTime) / 1000);
    this.#lastTime = now;
    while (remaining > 0 && this.state === "playing") {
      const delta = Math.min(remaining, 1 / 120);
      remaining -= delta;
      this.move(this.paddle + direction * delta * 0.85);
      this.elapsedMs += delta * 1000;
      this.#step(delta);
    }
  }

  #step(delta) {
    const ball = this.ball;
    const speed = this.speed;
    const acceleration = speed / Math.hypot(ball.vx, ball.vy);
    ball.vx *= acceleration;
    ball.vy *= acceleration;
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
      const offset = Math.max(
        -1,
        Math.min(1, (ball.x - this.paddle) / PADDLE_HALF)
      );
      const angle = offset * (Math.PI / 3);
      ball.vx = Math.sin(angle) * speed;
      if (Math.abs(ball.vx) < 0.1) {
        ball.vx = ball.vx < 0 ? -0.1 : 0.1;
      }
      ball.vy = -Math.sqrt(speed ** 2 - ball.vx ** 2);
      ball.y = PADDLE_TOP - BALL_RADIUS;
    }
    if (ball.y - BALL_RADIUS > HEIGHT) {
      this.state = "over";
    }
  }
}

class ElasticField {
  #buffer;
  #bytes;
  #canvas;
  #columns = 56;
  #field;
  #gl;
  #height;
  #image;
  #next;
  #offset;
  #program;
  #reach;
  #rows;
  #sourceKey;
  #uniforms;
  #velocity;
  #width;

  constructor(canvas) {
    this.#canvas = canvas;
    const gl = canvas.getContext("webgl", {
      alpha: true,
      antialias: false,
      premultipliedAlpha: false,
    });
    if (!gl) {
      throw new Error("Canvas deformation is unavailable");
    }
    this.#gl = gl;
    const vertex = this.#shader(
      gl.VERTEX_SHADER,
      `
      attribute vec2 position;
      varying vec2 uv;
      void main() {
        uv = position * 0.5 + 0.5;
        gl_Position = vec4(position, 0.0, 1.0);
      }
    `
    );
    const fragment = this.#shader(
      gl.FRAGMENT_SHADER,
      `
      precision mediump float;
      varying vec2 uv;
      uniform sampler2D image;
      uniform sampler2D field;
      uniform vec2 reach;
      void main() {
        vec2 displacement = (texture2D(field, vec2(uv.x, 1.0 - uv.y)).rg * 255.0 - 128.0) / 127.0;
        vec2 source = uv + vec2(-displacement.x, displacement.y) * reach;
        if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0) {
          gl_FragColor = vec4(0.0);
        } else {
          gl_FragColor = texture2D(image, source);
        }
      }
    `
    );
    this.#program = gl.createProgram();
    gl.attachShader(this.#program, vertex);
    gl.attachShader(this.#program, fragment);
    gl.linkProgram(this.#program);
    gl.deleteShader(vertex);
    gl.deleteShader(fragment);
    if (!gl.getProgramParameter(this.#program, gl.LINK_STATUS)) {
      throw new Error("Canvas deformation could not be linked");
    }
    gl.useProgram(this.#program);
    this.#buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.#buffer);
    gl.bufferData(
      gl.ARRAY_BUFFER,
      new Float32Array([-1, -1, 3, -1, -1, 3]),
      gl.STATIC_DRAW
    );
    const position = gl.getAttribLocation(this.#program, "position");
    gl.enableVertexAttribArray(position);
    gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
    this.#image = this.#texture();
    this.#field = this.#texture();
    this.#uniforms = {
      image: gl.getUniformLocation(this.#program, "image"),
      field: gl.getUniformLocation(this.#program, "field"),
      reach: gl.getUniformLocation(this.#program, "reach"),
    };
  }

  resize(width, height, ratio) {
    this.#width = width;
    this.#height = height;
    this.#canvas.width = Math.round(width * ratio);
    this.#canvas.height = Math.round(height * ratio);
    this.#gl.viewport(0, 0, this.#canvas.width, this.#canvas.height);
    this.#rows = Math.max(8, Math.round((this.#columns * height) / width));
    const cells = this.#columns * this.#rows;
    this.#offset = new Float32Array(cells * 2);
    this.#velocity = new Float32Array(cells * 2);
    this.#next = new Float32Array(cells * 2);
    this.#bytes = new Uint8Array(cells * 4);
    this.#reach = Math.min(130, width * 0.12);
    this.#sourceKey = null;
  }

  impulse(x, y, dx, dy) {
    if (!this.#offset) {
      return;
    }
    const centerX = (x / this.#width) * this.#columns;
    const centerY = (y / this.#height) * this.#rows;
    const radius = this.#columns * 0.15;
    dx = Math.max(-64, Math.min(64, dx));
    dy = Math.max(-64, Math.min(64, dy));
    for (
      let row = Math.max(0, Math.floor(centerY - radius));
      row < Math.min(this.#rows, centerY + radius);
      row++
    ) {
      for (
        let column = Math.max(0, Math.floor(centerX - radius));
        column < Math.min(this.#columns, centerX + radius);
        column++
      ) {
        const distance =
          ((column - centerX) ** 2 + (row - centerY) ** 2) / radius ** 2;
        if (distance < 1) {
          const influence = (1 - distance) ** 2;
          const index = (row * this.#columns + column) * 2;
          this.#velocity[index] += dx * influence * 0.9;
          this.#velocity[index + 1] += dy * influence * 0.9;
        }
      }
    }
  }

  advance(factor) {
    if (!this.#offset) {
      return false;
    }
    let active = false;
    const columns = this.#columns;
    for (let row = 0; row < this.#rows; row++) {
      for (let column = 0; column < columns; column++) {
        const index = (row * columns + column) * 2;
        const left = (row * columns + Math.max(0, column - 1)) * 2;
        const right = (row * columns + Math.min(columns - 1, column + 1)) * 2;
        const above = (Math.max(0, row - 1) * columns + column) * 2;
        const below =
          (Math.min(this.#rows - 1, row + 1) * columns + column) * 2;
        for (let axis = 0; axis < 2; axis++) {
          const current = this.#offset[index + axis];
          const neighbours =
            (this.#offset[left + axis] +
              this.#offset[right + axis] +
              this.#offset[above + axis] +
              this.#offset[below + axis]) /
            4;
          const velocity =
            (this.#velocity[index + axis] -
              current * 0.12 +
              (neighbours - current) * 0.18) *
            0.9 ** factor;
          const offset = Math.max(
            -this.#reach,
            Math.min(this.#reach, current + velocity * factor)
          );
          const moving = Math.abs(offset) + Math.abs(velocity) > 0.04;
          this.#next[index + axis] = moving ? offset : 0;
          this.#velocity[index + axis] = moving ? velocity : 0;
          active ||= moving;
        }
      }
    }
    const previous = this.#offset;
    this.#offset = this.#next;
    this.#next = previous;
    return active;
  }

  draw(source, sourceKey) {
    const gl = this.#gl;
    if (gl.isContextLost()) {
      return false;
    }
    for (let cell = 0; cell < this.#columns * this.#rows; cell++) {
      this.#bytes[cell * 4] = Math.round(
        128 + (127 * this.#offset[cell * 2]) / this.#reach
      );
      this.#bytes[cell * 4 + 1] = Math.round(
        128 + (127 * this.#offset[cell * 2 + 1]) / this.#reach
      );
      this.#bytes[cell * 4 + 3] = 255;
    }
    gl.useProgram(this.#program);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, this.#image);
    if (sourceKey !== this.#sourceKey) {
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
      gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        source
      );
      this.#sourceKey = sourceKey;
    }
    gl.uniform1i(this.#uniforms.image, 0);
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, this.#field);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RGBA,
      this.#columns,
      this.#rows,
      0,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      this.#bytes
    );
    gl.uniform1i(this.#uniforms.field, 1);
    gl.uniform2f(
      this.#uniforms.reach,
      this.#reach / this.#width,
      this.#reach / this.#height
    );
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    return true;
  }

  destroy() {
    const gl = this.#gl;
    gl.deleteTexture(this.#image);
    gl.deleteTexture(this.#field);
    gl.deleteBuffer(this.#buffer);
    gl.deleteProgram(this.#program);
  }

  #shader(type, source) {
    const gl = this.#gl;
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      gl.deleteShader(shader);
      throw new Error("Canvas deformation could not be compiled");
    }
    return shader;
  }

  #texture() {
    const gl = this.#gl;
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    return texture;
  }
}

function rasterizeText(text, width, height, ratio, palette, fit) {
  const characters = Array.from(text);
  const cellWidth = width / characters.length;
  const font = document.createElement("canvas").getContext("2d");
  let fontSize = Math.min(cellWidth * 1.8, height * 1.28);
  if (fit) {
    font.font = `750 ${fontSize}px ${palette.font}`;
    const metrics = characters.map((character) => font.measureText(character));
    const widest = Math.max(...metrics.map((metric) => metric.width));
    const tallest = Math.max(
      ...metrics.map(
        (metric) =>
          metric.actualBoundingBoxAscent + metric.actualBoundingBoxDescent
      )
    );
    fontSize *= Math.min(
      1,
      (cellWidth * 0.92) / widest,
      (height * 0.9) / tallest
    );
  }

  return characters.map((character) => {
    const canvas = document.createElement("canvas");
    canvas.width = Math.ceil(cellWidth * ratio);
    canvas.height = Math.ceil(height * ratio);
    const context = canvas.getContext("2d");
    context.scale(ratio, ratio);
    context.fillStyle = palette.accent;
    context.font = `750 ${fontSize}px ${palette.font}`;
    context.textAlign = "center";
    const metrics = context.measureText(character);
    context.fillText(
      character,
      cellWidth / 2,
      (height +
        metrics.actualBoundingBoxAscent -
        metrics.actualBoundingBoxDescent) /
        2
    );
    return canvas;
  });
}

class NotFoundInteraction {
  #announce;
  #canvas;
  #context;
  #current;
  #destroyed = false;
  #drag = null;
  #events = new AbortController();
  #field;
  #fieldCanvas;
  #frameId = null;
  #game = null;
  #glyphs = [];
  #glyphKey = "";
  #glyphVersion = 0;
  #height = 0;
  #hasGame;
  #text;
  #keys = new Set();
  #lastFrame = 0;
  #media;
  #observer;
  #palette;
  #pixelRatio = 0;
  #pointer = null;
  #record;
  #revealed = false;
  #root;
  #resizeFrameId = null;
  #spring = 0;
  #stage;
  #velocity = 0;
  #width = 0;
  #zero = 0;

  constructor(root, announce, { text = "404", gameEnabled = true } = {}) {
    this.#hasGame = gameEnabled;
    this.#text = text;
    this.#root = root;
    this.#announce = announce;
    this.#stage = gameEnabled ? root.querySelector("[data-stage]") : root;
    this.#canvas = root.querySelector("[data-canvas]");
    this.#fieldCanvas = root.querySelector("[data-elastic-canvas]");
    this.#context = this.#canvas.getContext("2d");
    if (!this.#context) {
      throw new Error("Canvas is unavailable");
    }
    this.#current = root.querySelector("[data-current]");
    this.#media = matchMedia("(prefers-reduced-motion: reduce)");
    try {
      this.#field = new ElasticField(this.#fieldCanvas);
    } catch {
      this.#field = null;
    }
    if (this.#hasGame) {
      let storage;
      try {
        storage = window.localStorage;
      } catch {
        storage = null;
      }
      this.#record = new BestTime(storage);
      root.querySelector("[data-best]").textContent = formatTime(
        this.#record.value
      );
    }
    this.#listen(this.#stage, "pointermove", (event) =>
      this.#pointerMove(event)
    );
    this.#listen(this.#stage, "pointerleave", () => {
      this.#pointer = null;
      this.#schedule();
    });
    if (this.#hasGame) {
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
      this.#listen(root.querySelector("[data-play]"), "click", () =>
        this.#openGame()
      );
      this.#listen(root.querySelector("[data-start]"), "click", () =>
        this.#start()
      );
      this.#listen(root.querySelector("[data-exit]"), "click", () =>
        this.#exit()
      );
      this.#listen(root, "keydown", (event) => this.#keyDown(event));
      this.#listen(root, "keyup", (event) => this.#keys.delete(event.key));
    } else {
      this.#listen(this.#stage, "pointerdown", (event) =>
        this.#pointerMove(event)
      );
    }
    this.#listen(document, "visibilitychange", () => {
      if (document.hidden) {
        this.#finish();
        cancelAnimationFrame(this.#frameId);
        this.#frameId = null;
      } else {
        this.#schedule();
      }
    });
    this.#listen(window, "blur", () => this.#finish());
    this.#listen(window, "pagehide", () => this.#finish());
    this.#listen(this.#media, "change", () => this.#schedule());
    this.#listen(matchMedia("(prefers-color-scheme: dark)"), "change", () =>
      this.#resize()
    );
    // Canvas dimensions affect layout, so observer writes need a separate frame.
    this.#observer = new ResizeObserver(() => this.#requestResize());
    this.#observer.observe(this.#stage);
    if (this.#hasGame) {
      document.body.classList.add("elastic-not-found-page");
    }
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
    if (this.#destroyed) {
      return;
    }
    this.#finish();
    this.#destroyed = true;
    this.#events.abort();
    this.#observer.disconnect();
    this.#field?.destroy();
    cancelAnimationFrame(this.#frameId);
    cancelAnimationFrame(this.#resizeFrameId);
    this.#keys.clear();
    this.#releaseDrag();
    this.#root.classList.remove("--enhanced");
    this.#root.classList.remove("--webgl");
    if (this.#hasGame) {
      document.body.classList.remove("elastic-not-found-page");
    }
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
      this.#exit();
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
      this.#zero = Math.max(
        -this.#width * 0.24,
        Math.min(this.#width * 0.24, event.clientX - this.#drag.start)
      );
      if (Math.abs(this.#zero) > this.#width * 0.11) {
        this.#reveal(false);
      }
    }
    const previous = this.#pointer;
    this.#pointer = { x, y: event.clientY - bounds.top };
    if (!this.#media.matches && previous) {
      this.#field?.impulse(
        x,
        this.#pointer.y,
        x - previous.x,
        this.#pointer.y - previous.y
      );
      this.#velocity += Math.max(-12, Math.min(12, x - previous.x)) * 0.4;
    }
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
    this.#stage.setAttribute(
      "aria-label",
      this.#root.querySelector(".elastic-not-found__instructions").textContent
    );
    this.#update();
    this.#draw();
    this.#root.querySelector("[data-start]").focus({ preventScroll: true });
  }

  #start() {
    if (!this.#game) {
      return;
    }
    this.#game.start(performance.now());
    this.#update();
    this.#stage.focus({ preventScroll: true });
    this.#schedule();
  }

  #finish() {
    this.#keys.clear();
    if (this.#game?.state !== "playing") {
      return;
    }
    this.#game.finish();
    this.#saveRecord();
    this.#update();
    this.#draw();
  }

  #exit() {
    if (this.#game?.state === "playing") {
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
    this.#root.querySelector("[data-best]").textContent = formatTime(
      this.#record.value
    );
  }

  #update() {
    const state = this.#game.state;
    const start = this.#root.querySelector("[data-start]");
    const status = this.#root.querySelector("[data-status]");
    const labels = this.#labels();
    this.#root.dataset.gameState = state;
    this.#root.querySelector("[data-overlay]").hidden = state === "playing";
    this.#current.textContent = formatTime(this.#game.elapsedMs);
    status.textContent = labels[state === "over" ? "overLabel" : "readyLabel"];
    start.textContent =
      start.dataset[state === "over" ? "retryLabel" : "startLabel"];
    if (state !== "playing") {
      this.#announce?.(status.textContent);
    }
  }

  #requestResize() {
    if (this.#destroyed || this.#resizeFrameId !== null) {
      return;
    }
    this.#resizeFrameId = requestAnimationFrame(() => {
      this.#resizeFrameId = null;
      if (!this.#destroyed) {
        this.#resize();
      }
    });
  }

  #resize() {
    const { width, height } = this.#stage.getBoundingClientRect();
    if (!width || !height || this.#destroyed) {
      return;
    }
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    if (
      width === this.#width &&
      height === this.#height &&
      ratio === this.#pixelRatio
    ) {
      this.#draw();
      return;
    }
    this.#width = width;
    this.#height = height;
    this.#pixelRatio = ratio;
    this.#canvas.width = Math.round(width * ratio);
    this.#canvas.height = Math.round(this.#height * ratio);
    this.#context.setTransform(ratio, 0, 0, ratio, 0, 0);
    this.#field?.resize(width, this.#height, ratio);
    this.#glyphKey = "";
    this.#draw();
  }

  #schedule() {
    if (!this.#destroyed && !document.hidden && this.#frameId === null) {
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
        const direction =
          Number(this.#keys.has("ArrowRight")) -
          Number(this.#keys.has("ArrowLeft"));
        this.#game.advance(now, direction);
        this.#current.textContent = formatTime(this.#game.elapsedMs);
        if (this.#game.state !== "playing") {
          if (this.#game.state === "over") {
            this.#saveRecord();
          }
          this.#update();
          this.#root
            .querySelector("[data-start]")
            .focus({ preventScroll: true });
        }
      }
      this.#draw();
      if (this.#game.state === "playing") {
        this.#schedule();
      }
    } else {
      const factor = Math.min(
        2,
        Math.max(0.25, (now - this.#lastFrame) / (1000 / 60))
      );
      if (this.#media.matches) {
        this.#spring = this.#velocity = 0;
        if (!this.#drag) {
          this.#zero = 0;
        }
      } else {
        this.#velocity =
          (this.#velocity - this.#spring * 0.12 * factor) * 0.75 ** factor;
        this.#spring += this.#velocity * factor;
        if (!this.#drag) {
          this.#zero *= 0.73 ** factor;
        }
      }
      const fieldMoving = !this.#media.matches && this.#field?.advance(factor);
      this.#draw();
      if (
        Math.abs(this.#spring) +
          Math.abs(this.#velocity) +
          (!this.#drag ? Math.abs(this.#zero) : 0) >
          0.1 ||
        fieldMoving
      ) {
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
    let useField = false;
    if (this.#game) {
      this.#drawGame();
    } else {
      this.#drawDigits();
      useField =
        !this.#media.matches &&
        this.#field?.draw(this.#canvas, `${this.#glyphVersion}:${this.#zero}`);
    }
    this.#fieldCanvas.hidden = !useField;
    this.#root.classList.toggle("--webgl", Boolean(useField));
  }

  #drawDigits() {
    const width = this.#width;
    const height = this.#height;
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    const key = `${width}:${height}:${ratio}:${this.#palette.accent}:${this.#palette.font}`;
    if (key !== this.#glyphKey) {
      this.#glyphKey = key;
      this.#glyphVersion++;
      this.#glyphs = rasterizeText(
        this.#text,
        width,
        height,
        ratio,
        this.#palette,
        !this.#hasGame
      );
    }
    const count = this.#glyphs.length;
    for (let index = 0; index < count; index++) {
      const glyph = this.#glyphs[index];
      const offset = this.#hasGame && index === 1 ? this.#zero : 0;
      if (this.#field && !this.#media.matches) {
        this.#context.drawImage(
          glyph,
          (index * width) / count + offset,
          0,
          width / count,
          height
        );
        continue;
      }
      for (let row = 0; row < height; row += 3) {
        const distance = this.#pointer
          ? (row - this.#pointer.y) / (width * 0.17)
          : 0;
        const horizontal = this.#pointer
          ? (this.#pointer.x - ((index + 0.5) * width) / count) /
            (width / count)
          : 0;
        const influence = this.#pointer
          ? Math.exp(-distance * distance * 2 - horizontal * horizontal)
          : 1;
        const shift = this.#media.matches ? 0 : this.#spring * influence;
        const slice = Math.min(3, height - row);
        this.#context.drawImage(
          glyph,
          0,
          row * ratio,
          glyph.width,
          Math.min((slice + 0.5) * ratio, glyph.height - row * ratio),
          (index * width) / count + offset + shift,
          row,
          width / count,
          slice + 0.5
        );
      }
    }
  }

  #drawGame() {
    const context = this.#context;
    const width = this.#width;
    context.fillStyle = this.#palette.text;
    context.beginPath();
    context.roundRect(
      (this.#game.paddle - PADDLE_HALF) * width,
      PADDLE_TOP * width,
      PADDLE_HALF * 2 * width,
      0.013 * width,
      0.0065 * width
    );
    context.fill();
    context.fillStyle = this.#palette.accent;
    context.font = `750 ${BALL_RADIUS * 2.8 * width}px ${this.#palette.font}`;
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText("0", this.#game.ball.x * width, this.#game.ball.y * width);
    context.textBaseline = "alphabetic";
  }
}

function mountInteraction(root, options) {
  if (mounted.has(root)) {
    return mounted.get(root);
  }
  let interaction;
  try {
    interaction = new NotFoundInteraction(root, options.announce, options);
  } catch {
    return () => {};
  }
  const destroy = () => interaction.destroy();
  mounted.set(root, destroy);
  return destroy;
}

export function mountNotFound(root, { announce } = {}) {
  return mountInteraction(root, { announce });
}

export function mountElasticStatus(root, { text }) {
  if (!String(text ?? "").trim()) {
    return () => {};
  }
  return mountInteraction(root, { text: String(text), gameEnabled: false });
}

if (
  typeof document !== "undefined" &&
  document.body?.classList.contains("no-ember")
) {
  const root = document.querySelector("[data-elastic-not-found]");
  if (root) {
    mountNotFound(root);
  }
}
