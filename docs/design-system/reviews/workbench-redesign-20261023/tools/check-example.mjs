import assert from "node:assert/strict";
import { mkdirSync, writeFileSync } from "node:fs";
import { Browser } from "/skill/scripts/lib/cdp.mjs";

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

mkdirSync("screenshots", { recursive: true });
const results = [];
try {
  for (const [width, height, label, columns] of [
    [1440, 900, "desktop", 3],
    [768, 1024, "tablet", 2],
    [390, 844, "mobile", 1],
  ]) {
    const page = await browser.newPage({ width, height, mobile: width < 600 });
    try {
      await page.goto("file:///review/example.html", { settleMs: 200 });
      await page.eval("document.fonts.ready.then(() => true)");
      const metrics = await page.eval(() => {
        const services = [
          ...document.querySelectorAll(".isbf-workbench__service"),
        ];
        const cells = services.map((service) =>
          service.getBoundingClientRect(),
        );
        const grid = document
          .querySelector(".isbf-workbench__grid")
          .getBoundingClientRect();
        return {
          total: services.length,
          available: services.filter((service) => service.matches("a[href]"))
            .length,
          planned: services.filter((service) =>
            service.matches(".is-planned:not([href]):not([tabindex])"),
          ).length,
          names: services.map(
            (service) => service.querySelector("h2").textContent,
          ),
          links: services
            .filter((service) => service.matches("a"))
            .map((service) => service.getAttribute("href")),
          columns: cells.filter((rect) => Math.abs(rect.top - cells[0].top) < 1)
            .length,
          overflow: document.documentElement.scrollWidth > innerWidth,
          minTarget: Math.min(
            ...cells.map((rect) => Math.min(rect.height, rect.width)),
          ),
          lastRowFits: Math.abs(cells.at(-1).right - grid.right) < 2,
        };
      });
      assert.equal(metrics.total, 9);
      assert.equal(metrics.available, 4);
      assert.equal(metrics.planned, 5);
      assert.equal(metrics.columns, columns);
      assert.equal(metrics.overflow, false);
      assert.equal(metrics.lastRowFits, true);
      assert.ok(metrics.minTarget >= 44);
      assert.deepEqual(metrics.names.slice(0, 4), [
        "学习资源",
        "简历工具",
        "校友网络",
        "商城",
      ]);
      assert.deepEqual(metrics.links, [
        "https://isbf-one.com/isbf/learning",
        "https://isbf-one.com/isbf/workbench/resume",
        "https://isbf-one.com/isbf/alumni",
        "https://isbf-one.com/isbf/marketplace",
      ]);

      for (const theme of ["light", "dark"]) {
        const selector =
          width < 600
            ? ".isbf-workbench__more details"
            : ".isbf-v2-side details";
        if (theme === "dark") {
          await page.eval((selectorOfMenu) => {
            const menu = document.querySelector(selectorOfMenu);
            menu.querySelector("summary").click();
            menu.querySelector("button").click();
          }, selector);
        }
        assert.equal(
          await page.eval("document.documentElement.dataset.theme"),
          theme,
        );
        await page.screenshot({
          path: `screenshots/${label}-${theme}.png`,
          format: "png",
          fullPage: width < 600,
        });
      }

      const menuResult = await page.eval(
        (selector) => {
          const menu = document.querySelector(selector);
          menu.querySelector("summary").click();
          return menu.open;
        },
        width < 600 ? ".isbf-workbench__more details" : ".isbf-v2-side details",
      );
      assert.equal(menuResult, true);
      await page.send("Input.dispatchKeyEvent", {
        type: "keyDown",
        key: "Escape",
        code: "Escape",
        windowsVirtualKeyCode: 27,
      });
      assert.equal(
        await page.eval("document.querySelectorAll('details[open]').length"),
        0,
      );
      await page.eval(() =>
        document.querySelector(".isbf-workbench__service.is-available").focus(),
      );
      assert.equal(
        await page.eval(
          "document.activeElement.matches('a.isbf-workbench__service')",
        ),
        true,
      );
      await page.send("Emulation.setEmulatedMedia", {
        features: [{ name: "prefers-reduced-motion", value: "reduce" }],
      });
      assert.equal(
        await page.eval(
          "getComputedStyle(document.querySelector('.isbf-workbench__arrow')).transitionDuration",
        ),
        "0s",
      );
      assert.deepEqual(page.consoleErrors, []);
      results.push({
        width,
        height,
        status: "passed",
        ...metrics,
        themes: ["light", "dark"],
        menuEscape: true,
        keyboardFocus: true,
        reducedMotion: true,
        consoleErrors: [],
      });
    } finally {
      await page.close();
    }
  }
} finally {
  await browser.close();
}

writeFileSync(
  "verification.json",
  `${JSON.stringify({ scope: "Offline review fixture only", results }, null, 2)}\n`,
);
console.log(
  `Verified ${results.length} widths, light/dark, links, ordering, menu, keyboard focus and reduced motion.`,
);
