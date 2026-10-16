const fs = require("node:fs");
const path = require("node:path");
const { createRequire } = require("node:module");
const requireFrontend = createRequire("/workspace/frontend/discourse/package.json");
const babel = requireFrontend("@babel/core");
const packageDirectory = fs.readdirSync("/workspace/node_modules/.pnpm").find((name) => name.startsWith("@babel+plugin-transform-modules-amd@"));
const amd = require(`/workspace/node_modules/.pnpm/${packageDirectory}/node_modules/@babel/plugin-transform-modules-amd`);
const compiled = "/review/compiled";
const modules = [
  ["more-topics.gjs.js", "isbf-review/core/more-topics"],
  ["browse-more.gjs.js", "isbf-review/core/browse-more"],
  ["isbf-continue-reading.gjs.js", "isbf-review/components/isbf-continue-reading"],
  ["isbf-continue-reading-item.gjs.js", "isbf-review/components/isbf-continue-reading-item"],
  ["isbf-continue-reading-footer.gjs.js", "isbf-review/components/isbf-continue-reading-footer"],
];
const output = ['define("isbf-review/theme", [], function () { return { themePrefix: (key) => "theme_translations.4." + key }; });'];
const translations = JSON.parse(fs.readFileSync(`${compiled}/translations.json`, "utf8"));
let runtime;
for (const [file, id] of modules) {
  let source = fs.readFileSync(`${compiled}/${file}`, "utf8");
  runtime ||= source.match(/from "([^"]*decorator-transforms[^\"]*runtime\.js)"/)?.[1];
  source = source.replaceAll('"virtual:theme"', '"isbf-review/theme"').replaceAll('"discourse/components/more-topics/browse-more"', '"isbf-review/core/browse-more"').replace(/"[^\"]*decorator-transforms[^\"]*runtime\.js"/g, '"isbf-review/decorators"');
  output.push(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: id, filename: file, babelrc: false, configFile: false }).code);
}
const runtimeModules = new Set();
function addRuntime(file, id) {
  if (runtimeModules.has(id)) return;
  runtimeModules.add(id);
  const source = fs.readFileSync(file, "utf8");
  for (const [, relative] of source.matchAll(/from\s+["'](\.[^"']+)["']/g)) {
    addRuntime(path.resolve(path.dirname(file), relative), path.posix.join(path.posix.dirname(id), relative));
  }
  output.unshift(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: id, babelrc: false, configFile: false }).code);
}
addRuntime(runtime, "isbf-review/decorators");
output.push(`
const reviewLookup = (name) => window.moduleBroker.lookup(name);
const { getComponentTemplate, setComponentTemplate } = reviewLookup("@ember/component");
setComponentTemplate(getComponentTemplate(reviewLookup("isbf-review/core/more-topics").default), reviewLookup("discourse/components/more-topics").default);
const { withPluginApi } = reviewLookup("discourse/lib/plugin-api");
withPluginApi((api) => {
  api.renderInOutlet("more-topics-content", reviewLookup("isbf-review/components/isbf-continue-reading").default);
});
for (const [lang, messages] of Object.entries(${JSON.stringify(translations)})) {
  const localeData = window._discourse_locale_data;
  localeData.theme ??= {};
  localeData.theme[4] ??= {};
  localeData.theme[4][lang] ??= {};
  localeData.theme[4][lang].isbf_v2 ??= {};
  localeData.theme[4][lang].isbf_v2.continue_reading = messages;
  const existing = reviewLookup("discourse-i18n").default.translations?.[lang]?.js?.theme_translations?.[4]?.isbf_v2;
  if (existing) existing.continue_reading = messages;
}
window.isbfReviewSourceInstalled = true;
`);
fs.writeFileSync("/review/compiled/browser-modules.js", output.join("\n"));
console.log(JSON.stringify({ actual_component_modules_prepared: modules.length, adapter: "Cached Ember app; install actual compiled core template before boot and use native topic-list handlers" }));
