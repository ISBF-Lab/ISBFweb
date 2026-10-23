import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const review = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repository = resolve(review, "../../../..");
const output = resolve(review, "site");
mkdirSync(output, { recursive: true });

const services = [
  {
    key: "learning",
    name: "学习资源",
    description: "查找课程学习资料",
    icon: "book-open",
    tone: "blue",
    href: "/isbf/learning",
  },
  {
    key: "courses",
    name: "课程专区",
    description: "汇集课程相关信息",
    icon: "graduation-cap",
    tone: "violet",
    href: null,
  },
  {
    key: "careers",
    name: "求职实习",
    description: "寻找实习与就业机会",
    icon: "briefcase",
    tone: "amber",
    href: null,
  },
  {
    key: "resume",
    name: "简历工具",
    description: "编辑与预览个人简历",
    icon: "file-lines",
    tone: "mint",
    href: "/isbf/workbench/resume",
  },
  {
    key: "campus",
    name: "校园服务",
    description: "办理校园生活事项",
    icon: "building-columns",
    tone: "blue",
    href: null,
  },
  {
    key: "identity",
    name: "学生认证",
    description: "认证校园学生身份",
    icon: "id-card",
    tone: "amber",
    href: null,
  },
  {
    key: "library",
    name: "资料库",
    description: "查找共享资料",
    icon: "database",
    tone: "violet",
    href: null,
  },
  {
    key: "alumni",
    name: "校友网络",
    description: "查看校友目录与分布",
    icon: "user-group",
    tone: "mint",
    href: "/isbf/alumni",
  },
  {
    key: "marketplace",
    name: "商城",
    description: "浏览校园商品信息",
    icon: "bag-shopping",
    tone: "amber",
    href: "/isbf/marketplace",
  },
];

const navigation = [
  { name: "首页", href: "/latest", icon: "house" },
  { name: "探索", href: "/categories", icon: "magnifying-glass" },
  { name: "通知", href: "/login", icon: "bell" },
  { name: "日历", href: "/isbf/calendar", icon: "calendar-days" },
  {
    name: "工作台",
    href: "/isbf/workbench",
    icon: "table-cells-large",
    active: true,
  },
  { name: "书签", href: "/login", icon: "bookmark" },
  { name: "个人资料", href: "/login", icon: "user" },
];

const iconNames = [
  ...new Set(
    [
      ...services,
      ...navigation,
      { icon: "arrow-right" },
      { icon: "ellipsis" },
      { icon: "moon" },
      { icon: "sun" },
      { icon: "circle-info" },
      { icon: "arrow-right-to-bracket" },
    ].map(({ icon: name }) => name),
  ),
];
const symbols = iconNames
  .map((name) => {
    const file = resolve(
      repository,
      "node_modules/@fortawesome/fontawesome-free/svgs/solid",
      `${name}.svg`,
    );
    const svg = readFileSync(file, "utf8");
    const viewBox = svg.match(/viewBox="([^"]+)"/)[1];
    const paths = [...svg.matchAll(/<path\b[^>]*\bd="([^"]+)"[^>]*\/?\s*>/g)]
      .map((match) => `<path d="${match[1]}"></path>`)
      .join("");
    return `<symbol id="icon-${name}" viewBox="${viewBox}">${paths}</symbol>`;
  })
  .join("\n");

const icon = (name, extra = "") =>
  `<svg class="d-icon ${extra}" aria-hidden="true"><use href="#icon-${name}"></use></svg>`;
const link = ({ name, href, icon: nameOfIcon, active }) =>
  `<a href="https://isbf-one.com${href}"${active ? ' aria-current="page" class="is-active"' : ""} title="${name}">${icon(nameOfIcon)}<span>${name}</span></a>`;

function moreMenu(mobile = false) {
  return `<details class="isbf-v2-more${mobile ? " --mobile" : ""}">
    <summary aria-label="更多">${icon("ellipsis")}<span>更多</span></summary>
    <div class="isbf-v2-more__content">
      <button class="isbf-v2-more__theme" type="button" aria-pressed="false">${icon("moon")}<span>切换深色外观</span></button>
      <a href="https://isbf-one.com/about">${icon("circle-info")}关于我们</a>
      <a href="https://isbf-one.com/join/">${icon("arrow-right-to-bracket")}加入我们</a>
    </div>
  </details>`;
}

function card(service, before) {
  const { key, name, description, icon: nameOfIcon, href, tone } = service;
  const tag = href ? "a" : "div";
  const attributes = href ? ` href="https://isbf-one.com${href}"` : "";
  if (before) {
    return `<li><${tag} class="isbf-before__card"${attributes}><span class="isbf-before__icon --${tone}">${icon(nameOfIcon)}</span><span class="isbf-before__name">${name}</span></${tag}></li>`;
  }
  return `<li class="isbf-workbench__item" data-service="${key}">
    <${tag} class="isbf-workbench__service${href ? " is-available" : " is-planned"}"${attributes}>
      ${icon(nameOfIcon, "isbf-workbench__icon")}
      <div class="isbf-workbench__content">
        <h2 class="isbf-workbench__name">${name}</h2>
        <p class="isbf-workbench__description">${description}</p>
        <span class="isbf-workbench__status">${href ? "已开放" : "筹备中"}</span>
      </div>
      ${href ? icon("arrow-right", "isbf-workbench__arrow") : ""}
    </${tag}>
  </li>`;
}

function document(before) {
  const sorted = before
    ? services
    : [...services].sort(
        (first, second) =>
          Number(Boolean(second.href)) - Number(Boolean(first.href)),
      );
  return `<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light dark">
    <meta name="description" content="ISBF 工作台：学习、成长与校园生活的常用服务。">
    <title>工作台 · 国金综合平台${before ? " · 源码基线" : ""}</title>
    <link rel="stylesheet" href="style.css">
    ${before ? '<link rel="stylesheet" href="before.css">' : ""}
    <script src="preview.js" defer></script>
  </head>
  <body${before ? ' class="is-before"' : ""}>
    <svg class="isbf-icons" aria-hidden="true">${symbols}</svg>
    <a class="isbf-skip" href="#workbench">跳至工作台</a>
    <div class="isbf-v2-shell">
      <aside class="isbf-v2-side" aria-label="主导航">
        <a class="isbf-v2-brand" href="https://isbf-one.com/latest" aria-label="国金综合平台"><span class="isbf-v2-brand__name">国金综合平台</span><span class="isbf-v2-brand__compact" aria-hidden="true">ISBF</span></a>
        <nav class="isbf-v2-side__links" aria-label="站点导航">${navigation.map(link).join("\n")}${moreMenu()}</nav>
        <a class="isbf-v2-side__compose" href="https://isbf-one.com/new-topic"><span>发布</span><span class="isbf-v2-side__plus" aria-hidden="true">+</span></a>
        <a class="isbf-v2-side__login" href="https://isbf-one.com/login">${icon("user")}<span>登录</span></a>
      </aside>
    </div>
    <main class="isbf-workbench" id="workbench" tabindex="-1">
      <header class="isbf-workbench__header">
        <h1>工作台</h1>
        ${before ? "" : '<p class="isbf-workbench__intro">学习、成长与校园生活的常用服务。</p>'}
      </header>
      <div class="isbf-workbench__catalogue${before ? " isbf-before" : ""}">
        <ul class="${before ? "isbf-before__grid" : "isbf-workbench__grid"}" aria-label="校园服务">${sorted.map((service) => card(service, before)).join("\n")}</ul>
      </div>
      <div class="isbf-workbench__more">${moreMenu(true)}</div>
    </main>
    <nav class="isbf-v2-mobile-nav" aria-label="移动导航">${[navigation[0], navigation[1], navigation[3], navigation[4]].map(link).join("\n")}</nav>
  </body>
</html>
`;
}

writeFileSync(resolve(output, "index.html"), document(false));
writeFileSync(resolve(output, "before.html"), document(true));
writeFileSync(
  resolve(review, "fixture.json"),
  `${JSON.stringify({ scenario: "All currently linked services configured; review fixture, not live site state", services }, null, 2)}\n`,
);

const standalone = document(false)
  .replace(
    '<link rel="stylesheet" href="style.css">',
    `<style>\n${readFileSync(resolve(output, "style.css"), "utf8")}\n</style>`
  )
  .replace('<script src="preview.js" defer></script>', "")
  .replace(
    "</body>",
    `<script>\n${readFileSync(resolve(output, "preview.js"), "utf8")}\n</script>\n</body>`
  );
writeFileSync(resolve(review, "example.html"), standalone);

const sources = [
  "AGENTS.md",
  "docs/design-system/resource-policy.md",
  "docs/design-system/references/manifest.json",
  "docs/design-system/references/theme-4/common/common.scss.txt",
  "docs/design-system/references/theme-4/javascripts/discourse/components/isbf-v2-workbench.gjs.txt",
  "themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-workbench.gjs",
  "themes/isbf-campus-feed/javascripts/discourse/components/isbf-v2-side-nav.gjs",
  "themes/isbf-campus-feed/settings.yml",
  "themes/isbf-campus-feed/about.json",
];
writeFileSync(
  resolve(review, "source-manifest.json"),
  `${JSON.stringify(
    {
      status: "Review example; not deployed or visually accepted",
      sources: sources.map((path) => ({
        path,
        sha256: createHash("sha256")
          .update(readFileSync(resolve(repository, path)))
          .digest("hex"),
      })),
    },
    null,
    2,
  )}\n`,
);
console.log(`Built ${output}/index.html and the source-derived before.html`);
