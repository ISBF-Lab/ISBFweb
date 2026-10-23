const fs = require("node:fs");
const path = require("node:path");
const { createRequire } = require("node:module");
const requireFrontend = createRequire("/workspace/frontend/discourse/package.json");
const babel = requireFrontend("@babel/core");
const { Preprocessor } = requireFrontend("content-tag");
const config = requireFrontend("./babel.config.cjs");
config.plugins = config.plugins.map((entry) => {
  const [plugin, ...options] = Array.isArray(entry) ? entry : [entry];
  const resolved = typeof plugin === "string" ? requireFrontend.resolve(plugin.replace(/^module:/, "")) : plugin;
  if (options[0]?.compilerPath) options[0] = { ...options[0], compilerPath: requireFrontend.resolve(options[0].compilerPath) };
  return [resolved, ...options];
});
const amdDirectory = fs.readdirSync("/workspace/node_modules/.pnpm").find((name) => name.startsWith("@babel+plugin-transform-modules-amd@"));
const amd = require(`/workspace/node_modules/.pnpm/${amdDirectory}/node_modules/@babel/plugin-transform-modules-amd`);
const preprocessor = new Preprocessor();
const prefix = "isbf-workbench-review/";
const paths = JSON.parse(fs.readFileSync("/review/module-list.json", "utf8"));
const ids = paths.map((file) => prefix + file.replace(/\.(?:g?js|js\.es6)$/, ""));
fs.mkdirSync("/review/compiled", { recursive: true });
(async () => {
  for (const version of ["candidate"]) {
    const output = [`
      define("${prefix}theme", [], function () {
        return { themePrefix: (key) => "theme_translations.4." + key,
          get settings() { return window.moduleBroker.lookup("discourse/lib/theme-settings-store").getObjectForTheme(4); } };
      });
      for (const [name, exports] of Object.entries(window.isbfTimelineCachedTheme)) {
        if (!${JSON.stringify(ids)}.includes("${prefix}" + name)) {
          define("${prefix}" + name, [], function () { return exports; });
        }
      }
    `];
    let runtime;
    for (const [index, relative] of paths.entries()) {
      const candidate = `/review/source/live-candidate/javascripts/${relative}`;
      const filename = fs.existsSync(candidate) ? candidate : `/review/source/live-before/javascripts/${relative}`;
      const raw = fs.readFileSync(filename, "utf8");
      const preprocessed = preprocessor.process(raw, { filename }).code;
      let source = (await babel.transformAsync(preprocessed, { ...config, filename, babelrc: false, configFile: false })).code;
      runtime ||= source.match(/from "([^"]*decorator-transforms[^\"]*runtime\.js)"/)?.[1];
      source = source.replaceAll('"virtual:theme"', `"${prefix}theme"`).replace(/"[^\"]*decorator-transforms[^\"]*runtime\.js"/g, `"${prefix}decorators"`);
      output.push(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: ids[index], filename, babelrc: false, configFile: false }).code);
    }
    const visited = new Set();
    function addRuntime(file, id) {
      if (visited.has(id)) return;
      visited.add(id);
      const source = fs.readFileSync(file, "utf8");
      for (const [, relative] of source.matchAll(/from\s+["'](\.[^"']+)["']/g)) addRuntime(path.resolve(path.dirname(file), relative), path.posix.join(path.posix.dirname(id), relative));
      output.unshift(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: id, babelrc: false, configFile: false }).code);
    }
    addRuntime(runtime, prefix + "decorators");
    for (const relative of paths) {
      const name = relative.replace(/\.(?:g?js|js\.es6)$/, "");
      output.push(`window.isbfTimelineCachedTheme[${JSON.stringify(name)}] = window.moduleBroker.lookup(${JSON.stringify(prefix + name)});`);
    }
    output.push(`window.isbfTimelineSourceVersion = ${JSON.stringify(version)};`);
    fs.writeFileSync(`/review/compiled/modules-${version}.js`, output.join("\n"));
  }
  fs.writeFileSync("/review/module-compilation.json", JSON.stringify({passed: true, modules: paths.length}));
  console.log(JSON.stringify({ compiled: true, actual_source_modules_per_version: paths.length, framework: "Existing compiled Ember client; only theme entrypoints replaced" }));
})().catch((error) => { console.error(error); process.exitCode = 1; });
