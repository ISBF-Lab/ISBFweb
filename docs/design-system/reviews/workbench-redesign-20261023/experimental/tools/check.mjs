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
  if (target.type === "page")
    await browser.send("Target.closeTarget", { targetId: target.targetId });
}

mkdirSync("screenshots", { recursive: true });
const results = [];
try {
  for (const [width, height, label] of [
    [1440, 900, "desktop"],
    [768, 1024, "tablet"],
    [390, 844, "mobile"],
  ]) {
    const page = await browser.newPage({ width, height, mobile: width < 600 });
    try {
      await page.goto("file:///review/example.html", { settleMs: 250 });
      await page.eval("document.fonts.ready.then(() => true)");
      const metrics = await page.eval(() => {
        const links = [...document.querySelectorAll(".wb-atlas__launch")];
        const rectangle = (selector) => {
          const r = document.querySelector(selector).getBoundingClientRect();
          return {
            x: r.x,
            y: r.y,
            width: r.width,
            height: r.height,
            bottom: r.bottom,
            right: r.right,
          };
        };
        return {
          links: links.map((link) => link.getAttribute("href")),
          labels: links.map(
            (link) =>
              document.getElementById(link.getAttribute("aria-labelledby"))
                .textContent,
          ),
          planned: [...document.querySelectorAll(".wb-atlas__planned li")].map(
            (item) => item.textContent,
          ),
          plannedLinks: document.querySelectorAll(
            ".wb-atlas__planned a, .wb-atlas__planned button",
          ).length,
          minimumTarget: Math.min(
            ...links.map((link) =>
              Math.min(
                link.getBoundingClientRect().width,
                link.getBoundingClientRect().height,
              ),
            ),
          ),
          overflow: document.documentElement.scrollWidth > innerWidth,
          learn: rectangle(".wb-atlas__zone.--learn"),
          write: rectangle(".wb-atlas__zone.--write"),
          connect: rectangle(".wb-atlas__zone.--connect"),
          browse: rectangle(".wb-atlas__zone.--browse"),
        };
      });
      assert.equal(metrics.overflow, false);
      assert.ok(metrics.minimumTarget >= 44);
      assert.equal(metrics.planned.length, 5);
      assert.equal(metrics.plannedLinks, 0);
      assert.deepEqual(metrics.labels, [
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
      if (width === 1440) {
        assert.ok(Math.abs(metrics.learn.y - metrics.write.y) < 2);
        assert.ok(metrics.learn.height > metrics.write.height * 1.8);
        assert.ok(metrics.connect.y > metrics.write.y);
        assert.ok(metrics.browse.bottom < height);
      } else {
        assert.ok(metrics.learn.width > metrics.write.width * 1.8);
        assert.ok(Math.abs(metrics.write.y - metrics.connect.y) < 2);
        assert.ok(metrics.browse.y >= metrics.write.bottom);
      }

      for (const theme of ["light", "dark"]) {
        if (theme === "dark") {
          await page.eval((mobile) => {
            const menu = document.querySelector(
              mobile
                ? ".isbf-workbench__more details"
                : ".isbf-v2-side details",
            );
            menu.querySelector("summary").click();
            menu.querySelector("button").click();
          }, width < 600);
        }
        assert.equal(
          await page.eval("document.documentElement.dataset.theme"),
          theme,
        );
        await page.eval("window.scrollTo(0,0)");
        await page.screenshot({
          path: `screenshots/${label}-${theme}.png`,
          format: "png",
        });
        if (width < 600) {
          await page.eval("window.scrollTo(0,document.body.scrollHeight)");
          await page.screenshot({
            path: `screenshots/${label}-${theme}-lower.png`,
            format: "png",
          });
        }
      }
      await page.eval(() =>
        document.querySelector('[data-direction="write"]').focus(),
      );
      assert.equal(
        await page.eval("document.querySelector('.wb-atlas').dataset.focus"),
        "write",
      );
      assert.equal(
        await page.eval(
          "document.activeElement.matches('[data-direction=write]')",
        ),
        true,
      );
      await page.eval(
        (mobile) =>
          document
            .querySelector(
              mobile
                ? ".isbf-workbench__more summary"
                : ".isbf-v2-side details summary",
            )
            .click(),
        width < 600,
      );
      assert.equal(
        await page.eval("document.querySelectorAll('details[open]').length"),
        1,
      );
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
      await page.send("Emulation.setEmulatedMedia", {
        features: [{ name: "prefers-reduced-motion", value: "reduce" }],
      });
      assert.equal(
        await page.eval(
          "getComputedStyle(document.querySelector('.wb-atlas__glyph')).transitionDuration",
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
        focusFeedback: true,
        menuEscape: true,
        reducedMotion: true,
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
  `${JSON.stringify({ scope: "Offline experimental candidate", results }, null, 2)}\n`,
);
console.log(
  "Verified the experimental layout at 1440/768/390px, in light/dark, including navigation, focus feedback and menus.",
);
