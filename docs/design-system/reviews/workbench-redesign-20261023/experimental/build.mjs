import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const directory = dirname(fileURLToPath(import.meta.url));
const previous = resolve(directory, "..");
const base = readFileSync(resolve(previous, "site/index.html"), "utf8");
const oldMain = base.match(/<main[\s\S]*?<\/main>/)[0];
const more = oldMain.slice(
  oldMain.indexOf('<div class="isbf-workbench__more">'),
  oldMain.lastIndexOf("</main>"),
);
const arrow =
  '<svg class="d-icon wb-atlas__arrow" aria-hidden="true"><use href="#icon-arrow-right"></use></svg>';

const directions = [
  {
    key: "learn",
    verb: "学",
    name: "学习资源",
    description: "按年级与课程查找学习资料",
    href: "/isbf/learning",
    planned: ["课程专区", "资料库"],
  },
  {
    key: "write",
    verb: "写",
    name: "简历工具",
    description: "编辑与预览个人简历",
    href: "/isbf/workbench/resume",
    planned: ["求职实习"],
  },
  {
    key: "connect",
    verb: "联",
    name: "校友网络",
    description: "查看校友目录与分布",
    href: "/isbf/alumni",
    planned: ["学生认证"],
  },
  {
    key: "browse",
    verb: "逛",
    name: "商城",
    description: "浏览校园商品信息",
    href: "/isbf/marketplace",
    planned: ["校园服务"],
  },
];

function zone(item) {
  return `<section class="wb-atlas__zone --${item.key}" aria-labelledby="${item.key}-title">
    <a class="wb-atlas__launch" data-direction="${item.key}" href="https://isbf-one.com${item.href}" aria-labelledby="${item.key}-title">
      <span class="wb-atlas__glyph">${item.verb}</span>
      <div class="wb-atlas__copy">
        <h2 id="${item.key}-title">${item.name}</h2>
        <p>${item.description}</p>
        <span class="wb-atlas__state">已开放 ${arrow}</span>
      </div>
    </a>
    <ul class="wb-atlas__planned" aria-label="${item.name}相关筹备服务">${item.planned.map((name) => `<li><span>${name}</span><span class="wb-atlas__pending">筹备中</span></li>`).join("")}</ul>
  </section>`;
}

const main = `<main class="wb-atlas" id="workbench" data-focus="learn" tabindex="-1">
  <header class="wb-atlas__header">
    <h1>工作台</h1>
    <p>学习、成长、连接与校园生活。</p>
  </header>
  <div class="wb-atlas__canvas">
    <div class="wb-atlas__index">${directions.map(zone).join("\n")}</div>
  </div>
  ${more}
</main>`;

const stylesheet = `${readFileSync(resolve(previous, "site/style.css"), "utf8")}\n${readFileSync(resolve(directory, "atlas.css"), "utf8")}`;
const script = `${readFileSync(resolve(previous, "site/preview.js"), "utf8")}\n${readFileSync(resolve(directory, "atlas.js"), "utf8")}`;
const document = base
  .replace(oldMain, main)
  .replace(
    "<title>工作台 · 国金综合平台</title>",
    "<title>工作台 · 学写联逛 · 国金综合平台</title>",
  )
  .replace(
    '<link rel="stylesheet" href="style.css">',
    `<style>\n${stylesheet}\n</style>`,
  )
  .replace('<script src="preview.js" defer></script>', "")
  .replace("</body>", `<script>\n${script}\n</script>\n</body>`);

mkdirSync(resolve(directory, "screenshots"), { recursive: true });
writeFileSync(resolve(directory, "example.html"), document);
writeFileSync(
  resolve(directory, "fixture.json"),
  `${JSON.stringify({ scope: "Review fixture, not live configuration", directions }, null, 2)}\n`,
);
console.log("Built experimental/example.html: 学、写、联、逛。");
