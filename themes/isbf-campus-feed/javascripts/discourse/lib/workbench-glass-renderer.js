import {
  WORKBENCH_FRAGMENT_SHADER,
  WORKBENCH_VERTEX_SHADER,
} from "./workbench-glass-shaders";

function compileShader(gl, type, source) {
  const shader = gl.createShader(type);
  if (!shader) {
    return null;
  }
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    return shader;
  }
  gl.deleteShader(shader);
  return null;
}

export function createWorkbenchRenderer(canvas) {
  let gl;
  try {
    gl = canvas.getContext("webgl2", {
      alpha: true,
      premultipliedAlpha: true,
      antialias: false,
    });
  } catch {
    return null;
  }
  if (!gl) {
    return null;
  }

  const vertex = compileShader(gl, gl.VERTEX_SHADER, WORKBENCH_VERTEX_SHADER);
  const fragment = compileShader(
    gl,
    gl.FRAGMENT_SHADER,
    WORKBENCH_FRAGMENT_SHADER
  );
  const program = gl.createProgram();
  let buffer;
  let texture;
  let disposed = false;

  const destroy = () => {
    if (disposed) {
      return;
    }
    disposed = true;
    gl.useProgram(null);
    if (texture) {
      gl.deleteTexture(texture);
    }
    if (buffer) {
      gl.deleteBuffer(buffer);
    }
    if (program) {
      gl.deleteProgram(program);
    }
    if (vertex) {
      gl.deleteShader(vertex);
    }
    if (fragment) {
      gl.deleteShader(fragment);
    }
  };

  if (!vertex || !fragment || !program) {
    destroy();
    return null;
  }
  gl.attachShader(program, vertex);
  gl.attachShader(program, fragment);
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    destroy();
    return null;
  }

  buffer = gl.createBuffer();
  texture = gl.createTexture();
  if (!buffer || !texture) {
    destroy();
    return null;
  }
  gl.useProgram(program);
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]),
    gl.STATIC_DRAW
  );
  const corner = gl.getAttribLocation(program, "aCorner");
  gl.enableVertexAttribArray(corner);
  gl.vertexAttribPointer(corner, 2, gl.FLOAT, false, 0, 0);

  const uniforms = Object.fromEntries(
    [
      ...(WORKBENCH_VERTEX_SHADER + WORKBENCH_FRAGMENT_SHADER).matchAll(
        /uniform\s+\w+\s+(\w+)/g
      ),
    ].map((match) => [match[1], gl.getUniformLocation(program, match[1])])
  );
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, texture);
  for (const filter of [gl.TEXTURE_MIN_FILTER, gl.TEXTURE_MAG_FILTER]) {
    gl.texParameteri(gl.TEXTURE_2D, filter, gl.LINEAR);
  }
  for (const wrap of [gl.TEXTURE_WRAP_S, gl.TEXTURE_WRAP_T]) {
    gl.texParameteri(gl.TEXTURE_2D, wrap, gl.CLAMP_TO_EDGE);
  }
  gl.uniform1i(uniforms.uGradients, 0);
  gl.enable(gl.BLEND);
  gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
  let paletteColor;

  return {
    destroy,

    draw(layout, visuals, palette) {
      if (disposed || gl.isContextLost()) {
        return;
      }
      gl.useProgram(program);
      const { size, width, height, dpr } = layout;
      gl.viewport(0, 0, canvas.width, canvas.height);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.uniform2f(uniforms.uCanvas, width, height);
      gl.uniform1f(uniforms.uExtent, size * 1.08);
      gl.uniform1f(uniforms.uSize, size);
      gl.uniform1f(uniforms.uRadius, Math.round(size * 0.3));
      gl.uniform1f(uniforms.uBevel, Math.max(2, Math.round(size * 0.156)));
      gl.uniform1f(uniforms.uSplit, 0);
      gl.uniform1f(uniforms.uSoft, 1);
      gl.uniform1f(uniforms.uShade, palette.shade);
      gl.uniform1i(uniforms.uPlate, 2);
      gl.uniform1f(uniforms.uDisc, size * 0.41);
      gl.uniform1f(uniforms.uPixel, 1 / dpr);
      gl.uniform2f(uniforms.uOrigin, 0, 0);
      gl.uniformMatrix2fv(uniforms.uTurn, false, [1, 0, 0, 1]);
      gl.uniform1f(uniforms.uScale, 1);
      gl.uniform2f(uniforms.uDirection, 0, 1);
      gl.uniform1f(uniforms.uSpan, size);

      const colorKey = palette.cards
        .map((card) => card.plate.join(","))
        .join(";");
      if (colorKey !== paletteColor) {
        paletteColor = colorKey;
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(
          gl.TEXTURE_2D,
          0,
          gl.RGBA,
          1,
          palette.cards.length,
          0,
          gl.RGBA,
          gl.UNSIGNED_BYTE,
          new Uint8Array(palette.cards.flatMap((card) => card.plate))
        );
      }

      visuals.forEach((visual, index) => {
        const card = palette.cards[index];
        gl.uniform4f(uniforms.uTint, ...card.tint, 0.24);
        gl.uniform1f(uniforms.uRow, (index + 0.5) / palette.cards.length);
        gl.uniform2f(uniforms.uCenter, ...layout.centers[index]);
        gl.uniform1f(uniforms.uStrength, size * 0.24 * visual.bend);
        gl.uniform1f(uniforms.uShine, 0.65 * visual.glow);
        gl.uniform2f(uniforms.uLight, ...visual.light);
        gl.uniform2f(uniforms.uShift, ...visual.shift);
        gl.uniform2f(uniforms.uOffset, visual.offset, -visual.offset);
        gl.uniform2f(uniforms.uLift, 0, visual.lift);
        gl.uniform1f(uniforms.uGlassScale, visual.scale);
        gl.uniform1f(uniforms.uGlassAlpha, visual.glassAlpha);
        gl.uniform1f(uniforms.uPlateAlpha, visual.plateAlpha);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      });
    },
  };
}
