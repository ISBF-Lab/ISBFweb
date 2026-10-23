import assert from "node:assert/strict";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { Browser, sleep } from "/skill/scripts/lib/cdp.mjs";
import { verifyIconFeedback } from "./check-icons.mjs";

const browser = await Browser.launch({
  extraArgs: [
    "--no-sandbox",
    "--no-zygote",
    "--single-process",
    "--in-process-gpu",
    "--disable-dev-shm-usage",
    "--disable-gpu",
    "--renderer-process-limit=1",
    "--num-raster-threads=1",
  ],
});
for (const target of (await browser.send("Target.getTargets")).targetInfos) {
  if (target.type === "page") {
    await browser.send("Target.closeTarget", { targetId: target.targetId });
  }
}
const page = await browser.newPage();
const externalRequests = [];
await page.send("Network.enable");
browser.on(page.sessionId, "Network.requestWillBeSent", ({ request }) => {
  if (/^https?:/.test(request.url)) {
    externalRequests.push(request.url);
  }
});

async function navigate(name = "example.html", query = "") {
  let timer;
  let off;
  const loaded = new Promise((resolve, reject) => {
    off = browser.on(page.sessionId, "Page.loadEventFired", resolve);
    timer = setTimeout(
      () => reject(new Error("Local preview did not load")),
      10000
    );
  });
  try {
    await page.send("Page.navigate", { url: `file:///review/${name}${query}` });
    await loaded;
    await page.eval(() =>
      document.fonts.ready.then(
        () =>
          new Promise((resolve) =>
            requestAnimationFrame(() => requestAnimationFrame(resolve))
          )
      )
    );
  } finally {
    clearTimeout(timer);
    off();
  }
}

async function metrics() {
  return page.eval(() => {
    const rectangle = (element) => {
      const r = element.getBoundingClientRect();
      return {
        x: r.x,
        y: r.y,
        width: r.width,
        height: r.height,
        bottom: r.bottom,
        right: r.right,
      };
    };
    const grid = document.querySelector(".isbf-v2-workbench__grid");
    const cards = [...grid.children];
    const nav = document.querySelector(".isbf-v2-mobile-nav");
    const mobile = getComputedStyle(nav).display !== "none";
    const panel = rectangle(
      document.querySelector(".isbf-v2-workbench__panel")
    );
    const more = rectangle(document.querySelector(".isbf-v2-workbench__more"));
    const navTop = mobile ? nav.getBoundingClientRect().top : innerHeight;
    return {
      count: cards.length,
      columns: getComputedStyle(grid).gridTemplateColumns.split(" ").length,
      overflow: document.documentElement.scrollWidth > innerWidth,
      pageHeight: document.documentElement.scrollHeight,
      panel,
      more,
      navTop,
      lowerGap: navTop - (mobile ? more.bottom : panel.bottom),
      cardHeight: cards[0].getBoundingClientRect().height,
      cards: cards.map(rectangle),
      destinations: cards
        .filter((card) => card.matches("a"))
        .map((card) => card.dataset.destination),
      placeholderTargets: cards
        .filter((card) => !card.matches("a"))
        .filter(
          (card) =>
            card.hasAttribute("tabindex") || card.querySelector("a,button")
        ).length,
    };
  });
}

const pointer = async (type, x, y) =>
  page.send("Input.dispatchMouseEvent", {
    type,
    x,
    y,
    button: type === "mouseMoved" ? "none" : "left",
    clickCount: type === "mouseMoved" ? 0 : 1,
  });
const key = async (type, name, code, number) =>
  page.send("Input.dispatchKeyEvent", {
    type,
    key: name,
    code,
    windowsVirtualKeyCode: number,
  });
mkdirSync("screenshots", { recursive: true });
const interactionsOnly = process.argv.includes("--interactions-only");
const results = interactionsOnly
  ? JSON.parse(readFileSync("verification.json", "utf8")).results
  : [];
const interactions = {};
let passed = false;
try {
  for (const [width, height, label] of interactionsOnly
    ? []
    : [
        [1440, 900, "desktop"],
        [768, 1024, "tablet"],
        [390, 844, "mobile"],
        [320, 568, "small-mobile"],
      ]) {
    await page.setViewport({ width, height, mobile: width <= 600 });
    for (const [name, baseline] of [
      ["before.html", true],
      ["example.html", false],
    ]) {
      await navigate(name);
      const data = await metrics();
      assert.equal(data.overflow, false);
      assert.equal(data.count, 9);
      assert.equal(
        data.columns,
        baseline && (width >= 1100 || width <= 600) ? 4 : 3
      );
      assert.equal(data.placeholderTargets, 0);
      assert.deepEqual(data.destinations, [
        "/isbf/learning",
        "/isbf/workbench/resume",
        "/isbf/alumni",
        "/isbf/marketplace",
      ]);
      if (!baseline) {
        assert.ok(data.cardHeight >= (width <= 600 ? 112 : 144));
        assert.ok(data.cardHeight <= (width <= 600 ? 160 : 208) + 1);
        if (height >= 800) {
          assert.ok(
            data.panel.bottom < data.navTop,
            "Every entrance fits above the navigation"
          );
          assert.ok(
            data.lowerGap < height * 0.25,
            "The lower canvas is no longer mostly blank"
          );
        }
      }
      for (const theme of ["light", "dark"]) {
        if (theme === "dark") {
          await page.eval((mobile) => {
            const menu = document.querySelector(
              mobile
                ? ".isbf-v2-workbench__more details"
                : ".isbf-v2-side details"
            );
            menu.querySelector("summary").click();
            menu.querySelector("button").click();
          }, width <= 600);
        }
        assert.equal(
          await page.eval("document.documentElement.dataset.theme"),
          theme
        );
        await sleep(240);
        await page.screenshot({
          path: `screenshots/${label}-${baseline ? "before" : "after"}-${theme}.png`,
          format: "png",
        });
      }
      if (!baseline && width === 320) {
        await page.eval("scrollTo(0,document.documentElement.scrollHeight)");
        const bottom = await metrics();
        assert.ok(
          bottom.more.bottom < bottom.navTop,
          "More remains reachable above the fixed navigation after scrolling"
        );
        await page.screenshot({
          path: "screenshots/small-mobile-after-dark-lower.png",
          format: "png",
        });
      }
      results.push({
        width,
        height,
        label,
        baseline,
        ...data,
        themes: ["light", "dark"],
      });
    }
    await navigate("example.html", "?alumni=off");
    assert.equal((await metrics()).count, 8);
    assert.equal((await metrics()).columns, 3);
    assert.equal((await metrics()).overflow, false);
    console.log(
      `Verified ${label}: three columns, 9/8 entries, original comparison, light/dark.`
    );
  }

  Object.assign(
    interactions,
    await verifyIconFeedback({ page, navigate, pointer, key })
  );
  await page.setViewport({ width: 320, height: 568, mobile: true });
  await navigate();
  const longer = await page.eval(() => {
    document.querySelector(".isbf-v2-workbench__name").textContent =
      "学习资源与课程资料汇总入口";
    document.querySelectorAll(".isbf-v2-workbench__name").forEach((name) => {
      name.style.fontSize = "24px";
    });
    const firstName = document.querySelector(".isbf-v2-workbench__name");
    return {
      overflow: document.documentElement.scrollWidth > innerWidth,
      textFits: firstName.scrollWidth <= firstName.clientWidth,
      cardHeight: firstName.parentElement.getBoundingClientRect().height,
    };
  });
  assert.equal(longer.overflow, false);
  assert.equal(longer.textFits, true);
  interactions.longLabelsAndDoubleText = longer;
  assert.deepEqual(page.consoleErrors, []);
  assert.deepEqual(externalRequests, []);
  passed = true;
  console.log(
    "Verified all nine icon motions, dynamic activation, bag bounds, hover/tap, keyboard, rapid clicks, reduced motion, scrolling and long text; no external requests."
  );
} finally {
  await page.close();
  await browser.close();
  writeFileSync(
    "verification.json",
    `${JSON.stringify({ status: passed ? "passed" : "failed", revision: "all-icon-feedback", scope: "Offline HTML preview only; not an application or production regression", results, interactions, externalRequests, consoleErrors: page.consoleErrors }, null, 2)}\n`
  );
}
