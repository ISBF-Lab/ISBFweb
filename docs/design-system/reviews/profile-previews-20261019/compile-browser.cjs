const fs = require("node:fs");
const path = require("node:path");
const { createRequire } = require("node:module");
const requireFrontend = createRequire("/workspace/frontend/discourse/package.json");
const babel = requireFrontend("@babel/core");
const amdDirectory = fs.readdirSync("/workspace/node_modules/.pnpm").find((name) => name.startsWith("@babel+plugin-transform-modules-amd@"));
const amd = require(`/workspace/node_modules/.pnpm/${amdDirectory}/node_modules/@babel/plugin-transform-modules-amd`);
const prefix = "profile-preview-review/";
const themePath = "themes/isbf-campus-feed/javascripts/";
const corePath = "frontend/discourse/app/";
const files = JSON.parse(fs.readFileSync("/review/changed-files.json", "utf8"));
const modules = new Map();
for (const file of files) {
  if (file.startsWith(themePath) && /\.(gjs|js)$/.test(file)) modules.set(prefix + file.slice(themePath.length).replace(/\.(gjs|js)$/, ""), file);
  if (file.startsWith(corePath) && file.endsWith(".gjs")) modules.set(prefix + "core/" + file.slice(corePath.length).replace(/\.gjs$/, ""), file);
}
const output = [`
define("${prefix}theme", [], function () {
  return { themePrefix: (key) => "theme_translations.4." + key,
    get settings() { return window.moduleBroker.lookup("discourse/lib/theme-settings-store").getObjectForTheme(4); } };
});
for (const [name, exports] of Object.entries(window.isbfUnreadCachedTheme)) {
  if (!${JSON.stringify([...modules.keys()])}.includes("${prefix}" + name)) {
    define("${prefix}" + name, [], function () { return exports; });
  }
}
`];
let runtime;
for (const [id, file] of modules) {
  let source = fs.readFileSync(`/review/compiled/${file.replaceAll("/", "__")}.js`, "utf8");
  runtime ||= source.match(/from "([^"]*decorator-transforms[^\"]*runtime\.js)"/)?.[1];
  source = source.replaceAll('"virtual:theme"', `"${prefix}theme"`).replace(/"[^\"]*decorator-transforms[^\"]*runtime\.js"/g, `"${prefix}decorators"`);
  output.push(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: id, filename: file, babelrc: false, configFile: false }).code);
}
const runtimeModules = new Set();
function addRuntime(file, id) {
  if (runtimeModules.has(id)) return;
  runtimeModules.add(id);
  const source = fs.readFileSync(file, "utf8");
  for (const [, relative] of source.matchAll(/from\s+["'](\.[^"']+)["']/g)) addRuntime(path.resolve(path.dirname(file), relative), path.posix.join(path.posix.dirname(id), relative));
  output.unshift(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: id, babelrc: false, configFile: false }).code);
}
addRuntime(runtime, prefix + "decorators");
output.push(`
const profileLookup = (name) => window.moduleBroker.lookup(name);
const { getComponentTemplate, setComponentTemplate } = profileLookup("@ember/component");
for (const name of ["components/user-summary-topic", "templates/user/summary"]) {
  const candidate = profileLookup("${prefix}core/" + name).default;
  const original = profileLookup("discourse/" + name).default;
  setComponentTemplate(getComponentTemplate(candidate), original);
}
window.isbfUnreadCachedTheme["discourse/api-initializers/isbf-campus-feed"] = profileLookup("${prefix}discourse/api-initializers/isbf-campus-feed");
window.profilePreviewSourceInstalled = true;
`);
fs.writeFileSync("/review/compiled/browser-modules.js", output.join("\n"));
console.log(JSON.stringify({ current_source_modules: modules.size, cached_framework: true, patched_core_templates: 2 }));
