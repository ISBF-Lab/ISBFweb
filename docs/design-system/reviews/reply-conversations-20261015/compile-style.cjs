const fs = require("node:fs");
const { createRequire } = require("node:module");
const frontend = createRequire("/workspace/frontend/discourse/package.json");
let sass;
for (const name of ["sass", "sass-embedded"]) {
  try { sass = frontend(name); break; } catch {}
}
if (!sass) {
  const directory = fs.readdirSync("/workspace/node_modules/.pnpm").find((name) => /^sass@/.test(name));
  if (directory) sass = require(`/workspace/node_modules/.pnpm/${directory}/node_modules/sass`);
}
if (!sass) throw new Error("No local Sass compiler");
const common = fs.readFileSync("/workspace/themes/isbf-campus-feed/common/common.scss", "utf8");
function block(marker) {
  const start = common.indexOf(marker);
  if (start < 0) throw new Error(`Missing source block: ${marker}`);
  const brace = common.indexOf("{", start);
  let depth = 1;
  let end = brace + 1;
  while (depth && end < common.length) {
    if (common[end] === "{") depth++;
    if (common[end] === "}") depth--;
    end++;
  }
  return common.slice(start, end);
}
const loadPaths = ["/workspace/app/assets/stylesheets", "/workspace/themes/isbf-campus-feed/stylesheets"];
const source = [
  '@use "lib/viewport";',
  '@import "common/foundation/variables";',
  '@import "common/foundation/mixins";',
  block(":root {"),
  block("@mixin isbf-card-content"),
  block("@mixin isbf-card-actions"),
  '@import "common/nested-view";',
  '@import "common/topic-timeline";',
  `body:has(.isbf-v2-shell--topic-feed-style) { ${block("  .isbf-post-card-header {")} }`,
  '@import "topic-reading";',
  '@import "reply-conversations";',
].join("\n");
const options = { loadPaths, logger: { warn() {}, debug() {} } };
const result = sass.compileString(source, options);
fs.mkdirSync("/review/compiled", { recursive: true });
fs.writeFileSync("/review/compiled/conversations.css", result.css);
const schemes = JSON.parse(fs.readFileSync("/workspace/themes/isbf-campus-feed/about.json", "utf8")).color_schemes;
for (const [name, colors] of Object.entries(schemes)) {
  const mode = name.includes("Dark") ? "dark" : "light";
  const vars = Object.entries(colors).map(([key, value]) => `$${key}: #${value.replace(/^#/, "")};`).join("\n");
  const palette = sass.compileString(`${vars}\n@import "common/foundation/variables";\n@import "color_definitions";`, options);
  fs.writeFileSync(`/review/compiled/colors-${mode}.css`, palette.css);
}
const report = { scss_compiled: true, bytes: result.css.length, scope: "Actual native nested/timeline styles plus approved header, tokens, action mixins and conversation stylesheet" };
fs.writeFileSync("/review/style-compilation.json", JSON.stringify(report, null, 2) + "\n");
console.log(JSON.stringify(report));
