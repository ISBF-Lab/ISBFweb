import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const directory = dirname(fileURLToPath(import.meta.url));
const repository = resolve(directory, "../../../..");
const previous = resolve(directory, "../workbench-redesign-20261023/site");
const read = (file) => readFileSync(file, "utf8");
const fixture = JSON.parse(read(resolve(directory, "fixture.json")));
const componentPath =
  "themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-workbench.gjs";
const component = read(resolve(repository, componentPath));
const actualCards = [
  ...component.matchAll(/key: "([^"]+)", icon: "([^"]+)", tone: "([^"]+)"/g),
].map(([, key, icon, tone]) => ({ key, icon, tone }));
assert.deepEqual(
  fixture.services.map(({ key, icon, tone }) => ({ key, icon, tone })),
  actualCards
);
const referenceManifest = JSON.parse(
  read(resolve(repository, "docs/design-system/references/manifest.json"))
);
const referenceIntegrity = referenceManifest.files
  .filter(({ archive_path: path }) =>
    [
      "theme-4/common/common.scss.txt",
      "theme-4/javascripts/discourse/components/isbf-v2-workbench.gjs.txt",
    ].includes(path)
  )
  .map(({ archive_path: path, sha256 }) => {
    const actual = createHash("sha256")
      .update(
        readFileSync(resolve(repository, "docs/design-system/references", path))
      )
      .digest("hex");
    assert.equal(actual, sha256);
    return { path, sha256, verified: true };
  });
assert.equal(referenceIntegrity.length, 2);

function shellOnly(css) {
  const rules = [];
  let cursor = 0;
  while (cursor < css.length) {
    const start = css.indexOf("{", cursor);
    if (start === -1) {
      break;
    }
    const head = css.slice(cursor, start).trim();
    let end = start + 1;
    let depth = 1;
    while (depth && end < css.length) {
      if (css[end] === "{") {
        depth++;
      } else if (css[end] === "}") {
        depth--;
      }
      end++;
    }
    assert.equal(
      depth,
      0,
      "The saved shell stylesheet must have balanced blocks"
    );
    const body = css.slice(start + 1, end - 1);
    if (head.startsWith("@")) {
      const children = shellOnly(body);
      if (children.trim()) {
        rules.push(`${head} {\n${children}\n}`);
      }
    } else {
      const selectors = head
        .split(",")
        .filter((selector) => !selector.includes("isbf-workbench"));
      if (selectors.length) {
        rules.push(`${selectors.join(",")} {${body}}`);
      }
    }
    cursor = end;
  }
  return rules.join("\n");
}

const shell = shellOnly(read(resolve(previous, "style.css")));

const markup = read(resolve(previous, "before.html"));
const shellMarkup = markup.match(
  /<div class="isbf-v2-shell">[\s\S]*?<\/aside>\s*<\/div>/
)[0];
const mobileNav = markup.match(
  /<nav class="isbf-v2-mobile-nav"[\s\S]*?<\/nav>/
)[0];
const mobileMore =
  markup.match(
    /<div class="isbf-workbench__more">([\s\S]*?)<\/details><\/div>/
  )[1] + "</details>";
const originalSymbols = markup.match(
  /<svg class="isbf-icons"[\s\S]*?<\/svg>/
)[0];
// The source bag handle extends to y=-32 outside its declared viewBox.
const symbols = originalSymbols.replace(
  /(<symbol id="icon-bag-shopping" viewBox=")[^"]+("\s*>)/,
  "$1-16 -48 480 544$2"
);
assert.notEqual(symbols, originalSymbols);
const icon = (name) =>
  `<svg class="d-icon" aria-hidden="true"><use href="#icon-${name}"></use></svg>`;

function card(service, allIcons = false) {
  const { key, label, icon: glyph, tone, href } = service;
  const tag = href || allIcons ? "a" : "div";
  const navigation =
    href || allIcons
      ? ` href="#preview-${key}"${href ? ` data-destination="${href}"` : ' data-preview-only="true"'}`
      : "";
  return `<${tag} class="isbf-v2-workbench__card" data-service="${key}"${navigation}>
    <span aria-hidden="true" class="isbf-v2-workbench__icon isbf-v2-workbench__icon--${tone}">${icon(glyph)}</span>
    <span class="isbf-v2-workbench__name">${label}</span>
  </${tag}>`;
}

const localLinks = (html) =>
  html.replace(
    /href="https:\/\/isbf-one\.com([^\"]*)"/g,
    (_, path) => `href="#preview-${path.replace(/[^a-z0-9]+/gi, "-")}"`
  );
const styles = `${shell}\n${read(resolve(directory, "workbench.css"))}`;
const script = read(resolve(directory, "preview.js"));

function document(baseline, dark = false, allIcons = false) {
  return `<!doctype html>
<html lang="zh-CN" data-theme="${dark ? "dark" : "light"}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <meta name="description" content="工作台独立交互预览；本地示例数据，点击仅演示反馈，不访问线上服务。">
  <title>工作台 · ${baseline ? "原版布局对照" : allIcons ? "全部入口动效演示" : "三列与图标动效预览"} · 本地示例数据</title>
  <style>${styles}</style>
</head>
<body${baseline ? ' class="is-baseline"' : ""}>
  ${baseline ? originalSymbols : symbols}
  <a class="isbf-skip" href="#workbench">跳至工作台</a>
  ${localLinks(shellMarkup)}
  <main class="isbf-v2-workbench" id="workbench" tabindex="-1">
    <h1>工作台</h1>
    ${allIcons ? '<p class="isbf-v2-workbench__preview-note">仅演示全部图标，未开放入口没有真实功能。</p>' : ""}
    <section class="isbf-v2-workbench__panel" aria-label="工作台">
      <div class="isbf-v2-workbench__grid">${fixture.services.map((service) => card(service, allIcons)).join("\n")}</div>
    </section>
    <div class="isbf-v2-workbench__more"><div class="isbf-v2-workbench__more-control">${localLinks(mobileMore)}</div></div>
  </main>
  ${localLinks(mobileNav)}
  <script>${script}</script>
</body>
</html>
`;
}

const outputs = [
  ["example.html", false, false],
  ["before.html", true, false],
  ["dark.html", false, true],
  ["all-icons.html", false, false, true],
];
for (const [name, baseline, dark, allIcons] of outputs) {
  writeFileSync(resolve(directory, name), document(baseline, dark, allIcons));
}

mkdirSync(resolve(directory, "screenshots"), { recursive: true });
const sources = [
  "AGENTS.md",
  "docs/design-system/resource-policy.md",
  "docs/design-system/references/manifest.json",
  "docs/design-system/references/theme-4/common/common.scss.txt",
  "docs/design-system/references/theme-4/javascripts/discourse/components/isbf-v2-workbench.gjs.txt",
  componentPath,
  "themes/isbf-campus-feed/common/common.scss",
  "themes/isbf-campus-feed/stylesheets/learning-resources.scss",
  "docs/design-system/reviews/workbench-redesign-20261023/site/style.css",
  "docs/design-system/reviews/workbench-redesign-20261023/site/before.html",
  "docs/design-system/reviews/workbench-motion-20261023/build.mjs",
  "docs/design-system/reviews/workbench-motion-20261023/workbench.css",
  "docs/design-system/reviews/workbench-motion-20261023/preview.js",
  "docs/design-system/reviews/workbench-motion-20261023/fixture.json",
];
const hash = (file) =>
  createHash("sha256").update(readFileSync(file)).digest("hex");
writeFileSync(
  resolve(directory, "source-manifest.json"),
  `${JSON.stringify(
    {
      scope:
        "User-authorized preview only; visual acceptance pending; not deployed",
      revision:
        "Nine reserved icon motions, dynamic link activation, corrected bag bounds",
      referenceIntegrity,
      references: {
        shell: "A01",
        workbench: "A08 / C02",
        source:
          "Current workspace workbench component; A01/A08 appearance with user-selected three-column sizing and per-icon mouse hover / touch click feedback",
      },
      sources: sources.map((path) => ({
        path,
        sha256: hash(resolve(repository, path)),
      })),
      outputs: outputs.map(([path]) => ({
        path,
        sha256: hash(resolve(directory, path)),
      })),
    },
    null,
    2
  )}\n`
);
console.log(
  "Built standalone workbench motion previews (light, dark, original comparison)."
);
