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
(async () => {
const prefix = "isbf-unread-review/";
const themePath = "themes/isbf-campus-feed/javascripts/";
const files = JSON.parse(fs.readFileSync("/review/changed-files.json", "utf8")).filter((file) => file.startsWith(themePath) && /\.(gjs|js)$/.test(file));
const modules = new Map(files.map((file) => [prefix + file.slice(themePath.length).replace(/\.(gjs|js)$/, ""), file]));
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
const wrapper = new Preprocessor().process(`import Shell from "${prefix}discourse/components/isbf-v2-shell"; <template><Shell /></template>`, { filename: "review-wrapper.gjs" }).code;
const compiledWrapper = (await babel.transformAsync(wrapper, { ...config, filename: "/workspace/review-wrapper.gjs", babelrc: false, configFile: false })).code;
output.push(babel.transformSync(compiledWrapper, { plugins: [[amd, { noInterop: true }]], moduleId: prefix + "wrapper", babelrc: false, configFile: false }).code);
const translations = JSON.parse(fs.readFileSync("/review/compiled/translations.json", "utf8"));
output.push(`
const unreadLookup = (name) => window.moduleBroker.lookup(name);
const { getComponentTemplate, setComponentTemplate } = unreadLookup("@ember/component");
setComponentTemplate(getComponentTemplate(unreadLookup("${prefix}wrapper").default), window.isbfUnreadCachedTheme["discourse/components/isbf-v2-shell"].default);
window.isbfUnreadCachedTheme["discourse/initializers/isbf-notifications"] = unreadLookup("${prefix}discourse/initializers/isbf-notifications");
for (const [lang, messages] of Object.entries(${JSON.stringify(translations)})) {
  const data = window._discourse_locale_data;
  data.theme ??= {}; data.theme[4] ??= {}; data.theme[4][lang] ??= {};
  data.theme[4][lang].isbf_v2 = { ...data.theme[4][lang].isbf_v2, ...messages };
  const existing = unreadLookup("discourse-i18n").default.translations?.[lang]?.js?.theme_translations?.[4];
  if (existing) existing.isbf_v2 = { ...existing.isbf_v2, ...messages };
}
window.isbfUnreadSourceInstalled = true;
`);
fs.writeFileSync("/review/compiled/browser-modules.js", output.join("\n"));
console.log(JSON.stringify({ actual_source_modules: modules.size, cached_framework: true, adapter: "Delegate the existing outlet to the complete current shell and components" }));
})().catch((error) => { console.error(error); process.exitCode = 1; });
