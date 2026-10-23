const fs = require("node:fs");
const path = require("node:path");
const { createRequire } = require("node:module");
const requireFrontend = createRequire("/workspace/frontend/discourse/package.json");
const babel = requireFrontend("@babel/core");
const amdDirectory = fs.readdirSync("/workspace/node_modules/.pnpm").find((name) => name.startsWith("@babel+plugin-transform-modules-amd@"));
const amd = require(`/workspace/node_modules/.pnpm/${amdDirectory}/node_modules/@babel/plugin-transform-modules-amd`);
const corePrefix = "password-setup-review/core/";
const pluginPath = "plugins/discourse-academy-roles/assets/javascripts/";
const corePath = "frontend/discourse/app/";
const files = JSON.parse(fs.readFileSync("/review/changed-files.json", "utf8"));
const modules = new Map();
const replacements = new Map();
for (const file of files) {
  if (file.startsWith(pluginPath)) {
    modules.set("discourse/plugins/discourse-academy-roles/" + file.slice(pluginPath.length).replace(/\.(gjs|js)$/, ""), file);
  } else if (file.startsWith(corePath)) {
    const name = file.slice(corePath.length).replace(/\.(gjs|js)$/, "");
    modules.set(corePrefix + name, file);
    replacements.set("discourse/" + name, corePrefix + name);
  }
}
const output = [];
let runtime;
for (const [id, file] of modules) {
  let source = fs.readFileSync(`/review/compiled/${file.replaceAll("/", "__")}.js`, "utf8");
  runtime ||= source.match(/from "([^"]*decorator-transforms[^\"]*runtime\.js)"/)?.[1];
  source = source.replace(/"[^\"]*decorator-transforms[^\"]*runtime\.js"/g, '"password-setup-review/decorators"');
  for (const [native, reviewed] of replacements) source = source.replaceAll(JSON.stringify(native), JSON.stringify(reviewed));
  output.push(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: id, filename: file, babelrc: false, configFile: false }).code);
}
const runtimes = new Set();
function addRuntime(file, id) {
  if (runtimes.has(id)) return;
  runtimes.add(id);
  const source = fs.readFileSync(file, "utf8");
  for (const [, relative] of source.matchAll(/from\s+["'](\.[^"']+)["']/g)) addRuntime(path.resolve(path.dirname(file), relative), path.posix.join(path.posix.dirname(id), relative));
  output.unshift(babel.transformSync(source, { plugins: [[amd, { noInterop: true }]], moduleId: id, babelrc: false, configFile: false }).code);
}
addRuntime(runtime, "password-setup-review/decorators");
output.push(`
window.passwordSetupReview = {
  modal: window.moduleBroker.lookup("discourse/plugins/discourse-academy-roles/discourse/components/modal/academy-password-setup").default,
  prompt: window.moduleBroker.lookup("discourse/plugins/discourse-academy-roles/discourse/components/academy-password-setup-prompt").default
};
window.isbfUnreadCachedTheme["discourse/initializers/academy-password-setup"] = window.moduleBroker.lookup("discourse/plugins/discourse-academy-roles/discourse/initializers/academy-password-setup");
`);
fs.writeFileSync("/review/compiled/browser-modules.js", output.join("\n"));
console.log(JSON.stringify({ actual_source_modules: modules.size, cached_framework: true, current_form_and_password_control: true }));
