export function graphics({ compile = true, link = true } = {}) {
  const calls = [];
  const gl = new Proxy(
    {
      getShaderParameter: () => compile,
      getProgramParameter: () => link,
      getAttribLocation: () => 0,
      getUniformLocation: (_, name) => name,
      isContextLost: () => false,
    },
    {
      get(target, name) {
        if (name in target) {
          return target[name];
        }
        if (/^[A-Z_]+$/.test(name)) {
          return name;
        }
        return (...args) => {
          calls.push({ name, args });
          return name.startsWith("create") ? { resource: name } : undefined;
        };
      },
    }
  );
  return {
    canvas: { getContext: () => gl, width: 400, height: 300 },
    calls: (name) => calls.filter((call) => call.name === name),
  };
}
