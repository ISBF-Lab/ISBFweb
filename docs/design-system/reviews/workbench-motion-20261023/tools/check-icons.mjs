import assert from "node:assert/strict";
import { writeFileSync } from "node:fs";
import { sleep } from "/skill/scripts/lib/cdp.mjs";

export async function verifyIconFeedback({ page, navigate, pointer, key }) {
  const result = { profiles: [] };
  const point = (service = "learning_resources") =>
    page.eval((id) => {
      const r = document
        .querySelector(`[data-service="${id}"]`)
        .getBoundingClientRect();
      return { x: r.x + 12, y: r.y + 16 };
    }, service);
  const state = (service = "learning_resources") =>
    page.eval((id) => {
      const card = document.querySelector(`[data-service="${id}"]`);
      const icon = card.querySelector(".isbf-v2-workbench__icon .d-icon");
      const rectangle = (element) => {
        const r = element.getBoundingClientRect();
        return [r.x, r.y, r.width, r.height];
      };
      const matrix = new DOMMatrixReadOnly(getComputedStyle(icon).transform);
      return {
        card: rectangle(card),
        tile: rectangle(icon.parentElement),
        label: rectangle(card.querySelector(".isbf-v2-workbench__name")),
        background: getComputedStyle(card).backgroundColor,
        cardTransform: getComputedStyle(card).transform,
        iconTransform: getComputedStyle(icon).transform,
        matrix: [
          matrix.a,
          matrix.b,
          matrix.c,
          matrix.d,
          matrix.m41,
          matrix.m42,
        ],
        active: icon.getAnimations().length,
        starts:
          window.previewIconCalls?.filter((call) => call.service === id)
            .length || 0,
      };
    }, service);
  const observe = () =>
    page.eval(() => {
      window.previewIconCalls = [];
      const original = Element.prototype.animate;
      Element.prototype.animate = function (frames, options) {
        if (this.matches(".isbf-v2-workbench__icon .d-icon")) {
          window.previewIconCalls.push({
            service: this.closest("[data-service]").dataset.service,
            duration: options.duration,
          });
        }
        return original.call(this, frames, options);
      };
    });
  const freeze = (service, offset = 0.4) =>
    page.eval(
      ({ service: id, offset: progress }) => {
        const icon = document.querySelector(
          `[data-service="${id}"] .isbf-v2-workbench__icon .d-icon`
        );
        const animation = icon.getAnimations()[0];
        if (!animation) {
          return null;
        }
        animation.pause();
        animation.currentTime =
          animation.effect.getTiming().duration * progress;
        return {
          duration: animation.effect.getTiming().duration,
          iterations: animation.effect.getTiming().iterations,
        };
      },
      { service, offset }
    );
  const finish = (service) =>
    page.eval(async (id) => {
      const icon = document.querySelector(
        `[data-service="${id}"] .isbf-v2-workbench__icon .d-icon`
      );
      await Promise.all(
        icon.getAnimations().map((animation) => {
          animation.play();
          return animation.finished.catch(() => {});
        })
      );
    }, service);

  await page.setViewport({ width: 1440, height: 900 });
  await navigate();
  await observe();
  assert.equal(await page.eval("document.getAnimations().length"), 0);
  for (const [service, duration] of [
    ["learning_resources", 360],
    ["resume", 320],
    ["alumni", 320],
    ["marketplace", 400],
  ]) {
    const before = await state(service);
    const target = await point(service);
    await pointer("mouseMoved", target.x, target.y);
    const timing = await freeze(
      service,
      service === "marketplace" ? 0.25 : 0.4
    );
    assert.deepEqual(timing, { duration, iterations: 1 });
    const peak = await state(service);
    assert.deepEqual(peak.card, before.card);
    assert.deepEqual(peak.tile, before.tile);
    assert.deepEqual(peak.label, before.label);
    assert.equal(peak.background, before.background);
    assert.equal(peak.cardTransform, "none");
    assert.equal(peak.active, 1);
    assert.notEqual(peak.iconTransform, "none");
    const [a, b, , , , y] = peak.matrix;
    if (service === "learning_resources") {
      assert.ok(a > 1.05 && b < -0.05, "The book rotates and grows");
      const inside = await page.eval(() => {
        const r = document
          .querySelector('[data-service="learning_resources"] .d-icon')
          .getBoundingClientRect();
        return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
      });
      await pointer("mouseMoved", inside.x, inside.y);
      assert.equal(
        (await state(service)).starts,
        peak.starts,
        "Moving between card children must not replay delegated hover"
      );
      await pointer("mousePressed", target.x, target.y);
      await pointer("mouseReleased", target.x, target.y);
      assert.equal(
        (await state(service)).starts,
        peak.starts,
        "A mouse click must not replay the hover animation"
      );
      assert.equal(
        await page.eval("location.hash"),
        "#preview-learning_resources"
      );
    } else if (service === "resume") {
      assert.ok(y < -3 && b < 0, "The resume lifts with a small rotation");
    } else if (service === "alumni") {
      assert.ok(
        a > 1.1 && Math.abs(b) < 0.001,
        "The people grow without rotation"
      );
    } else {
      assert.ok(b < -0.12, "The bag swings around its top");
    }
    await page.screenshot({
      path: `screenshots/desktop-icon-${service}.png`,
      format: "png",
    });
    await finish(service);
    await sleep(60);
    const after = await state(service);
    assert.equal(after.active, 0);
    assert.equal(after.iconTransform, "none");
    assert.equal(
      after.starts,
      peak.starts,
      "Staying over a card must not loop"
    );
    result.profiles.push({
      service,
      timing,
      peak: peak.matrix,
      stableCardTileAndLabel: true,
      noLoop: true,
    });
  }

  await pointer("mouseMoved", 2, 2);
  let target = await point();
  await pointer("mouseMoved", target.x, target.y);
  assert.ok(await freeze("learning_resources"));
  await pointer("mouseMoved", 2, 2);
  const restoring = await page.eval(
    () =>
      document
        .querySelector('[data-service="learning_resources"] .d-icon')
        .getAnimations()[0]
        ?.effect.getTiming().duration
  );
  assert.equal(restoring, 120);
  await finish("learning_resources");
  assert.equal((await state()).iconTransform, "none");
  result.leaveAndReenter = { restoredIn: restoring, replayed: true };

  target = await point("courses");
  await pointer("mouseMoved", target.x, target.y);
  assert.equal((await state("courses")).active, 0);
  result.placeholderStatic = true;

  await pointer("mouseMoved", 2, 2);
  await page.eval(() =>
    document.querySelector('a[data-service="learning_resources"]').focus()
  );
  await key("keyDown", "Tab", "Tab", 9);
  await key("keyUp", "Tab", "Tab", 9);
  const keyboard = await page.eval(() => ({
    service: document.activeElement.dataset.service,
    focusVisible: document.activeElement.matches(":focus-visible"),
    outline: getComputedStyle(document.activeElement).outlineWidth,
  }));
  assert.deepEqual(keyboard, {
    service: "resume",
    focusVisible: true,
    outline: "2px",
  });
  await key("keyDown", "Enter", "Enter", 13);
  assert.ok(await freeze("resume"));
  await key("keyUp", "Enter", "Enter", 13);
  assert.equal(await page.eval("location.hash"), "#preview-resume");
  await finish("resume");
  result.keyboard = keyboard;

  const rapid = await page.eval(() => {
    const card = document.querySelector('a[data-service="resume"]');
    for (let i = 0; i < 12; i++) {
      card.dispatchEvent(
        new PointerEvent("click", {
          bubbles: true,
          pointerType: "touch",
          detail: 1,
        })
      );
    }
    return card.querySelector(".d-icon").getAnimations().length;
  });
  assert.equal(rapid, 1);
  result.rapidClicks = { activeAnimations: rapid };
  await page.send("Emulation.setEmulatedMedia", {
    features: [{ name: "prefers-reduced-motion", value: "reduce" }],
  });
  await page.eval(
    () => new Promise((resolve) => requestAnimationFrame(resolve))
  );
  assert.equal(await page.eval("document.getAnimations().length"), 0);
  target = await point();
  await pointer("mouseMoved", target.x, target.y);
  await page.eval(() =>
    document.querySelector('a[data-service="learning_resources"]').click()
  );
  assert.equal((await state()).iconTransform, "none");
  assert.equal(await page.eval("document.getAnimations().length"), 0);
  result.reducedMotion = true;
  await page.send("Emulation.setEmulatedMedia", { features: [] });

  await page.setViewport({ width: 390, height: 844, mobile: true });
  await navigate();
  await observe();
  target = await point();
  await page.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ ...target, id: 1 }],
  });
  await sleep(150);
  assert.equal(
    (await state()).starts,
    0,
    "Touch hold must not animate before a click"
  );
  await page.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  assert.deepEqual(await freeze("learning_resources"), {
    duration: 360,
    iterations: 1,
  });
  assert.equal(
    (await state()).starts,
    1,
    "One completed tap plays once, even after touch pointerleave"
  );
  await page.screenshot({
    path: "screenshots/mobile-icon-tap.png",
    format: "png",
  });
  await finish("learning_resources");
  assert.equal((await state()).iconTransform, "none");
  result.touchClick = {
    noAnimationBeforeClick: true,
    playsOnceAfterClick: true,
    restores: true,
  };

  await page.setViewport({ width: 320, height: 568, mobile: true });
  await navigate();
  await observe();
  await page.eval(() => {
    window.previewPointerCancels = 0;
    document.addEventListener("pointercancel", (event) => {
      if (event.isTrusted) {
        window.previewPointerCancels++;
      }
    });
  });
  target = await point();
  await page.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ ...target, id: 1 }],
  });
  await page.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [{ x: target.x, y: target.y - 60, id: 1 }],
  });
  await page.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [{ x: target.x, y: Math.max(1, target.y - 110), id: 1 }],
  });
  await page.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  await sleep(100);
  const scroll = await page.eval(() => ({
    cancels: window.previewPointerCancels,
    calls: window.previewIconCalls.length,
    active: document.getAnimations().length,
    hash: location.hash,
    scrollY,
  }));
  assert.ok(scroll.cancels > 0);
  assert.equal(scroll.calls, 0);
  assert.equal(scroll.active, 0);
  assert.equal(scroll.hash, "");
  assert.ok(scroll.scrollY > 0);
  result.touchScroll = scroll;

  await page.setViewport({ width: 768, height: 1024, mobile: false });
  target = await point();
  await pointer("mouseMoved", target.x, target.y);
  assert.ok(
    await freeze("learning_resources"),
    "Mouse hover works on the same document after touch input"
  );
  await finish("learning_resources");
  result.mixedInput = true;
  assert.equal(
    await page.eval(
      "document.querySelectorAll('.isbf-v2-workbench__ripple-layer,.is-pressed').length"
    ),
    0
  );

  await pointer("mouseMoved", 2, 2);
  await navigate();
  await observe();
  await page.eval(() => {
    const old = document.querySelector('[data-service="courses"]');
    const link = document.createElement("a");
    for (const attribute of old.attributes) {
      link.setAttribute(attribute.name, attribute.value);
    }
    link.setAttribute("href", "#preview-courses");
    while (old.firstChild) {
      link.appendChild(old.firstChild);
    }
    old.replaceWith(link);
  });
  target = await point("courses");
  await pointer("mouseMoved", target.x, target.y);
  assert.deepEqual(await freeze("courses"), { duration: 380, iterations: 1 });
  await finish("courses");
  result.dynamicActivation = {
    replacedPlaceholderAfterStartup: true,
    playedWithoutRebinding: true,
  };

  await pointer("mouseMoved", 2, 2);
  await navigate("all-icons.html");
  await observe();
  assert.equal(
    await page.eval(
      "document.querySelectorAll('a.isbf-v2-workbench__card').length"
    ),
    9
  );
  assert.equal(
    await page.eval("document.querySelectorAll('[data-preview-only]').length"),
    5
  );
  assert.ok(
    await page.eval(
      "document.querySelector('.isbf-v2-workbench__preview-note').textContent.includes('未开放')"
    )
  );
  result.reservedProfiles = [];
  for (const [service, duration] of [
    ["courses", 380],
    ["careers", 380],
    ["campus_services", 360],
    ["student_identity", 340],
    ["library", 360],
  ]) {
    const before = await state(service);
    target = await point(service);
    await pointer("mouseMoved", target.x, target.y);
    const timing = await freeze(service);
    assert.deepEqual(timing, { duration, iterations: 1 });
    const peak = await state(service);
    assert.notEqual(peak.iconTransform, "none");
    assert.deepEqual(peak.card, before.card);
    assert.deepEqual(peak.tile, before.tile);
    assert.deepEqual(peak.label, before.label);
    await page.screenshot({
      path: `screenshots/reserved-icon-${service}.png`,
      format: "png",
    });
    await finish(service);
    assert.equal((await state(service)).active, 0);
    result.reservedProfiles.push({ service, duration, peak: peak.matrix });
  }
  assert.equal(
    new Set(
      result.reservedProfiles.map((profile) => JSON.stringify(profile.peak))
    ).size,
    5
  );

  await pointer("mouseMoved", 2, 2);
  await page.eval(
    () =>
      (document.querySelector('[data-service="library"]').dataset.service =
        "future_tool")
  );
  target = await point("future_tool");
  await pointer("mouseMoved", target.x, target.y);
  assert.deepEqual(await freeze("future_tool"), {
    duration: 320,
    iterations: 1,
  });
  assert.ok((await state("future_tool")).matrix[0] > 1.05);
  await finish("future_tool");
  result.unknownServiceFallback = true;

  await page.setViewport({ width: 390, height: 844, mobile: true });
  await navigate("all-icons.html");
  await observe();
  target = await point("student_identity");
  await page.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ ...target, id: 1 }],
  });
  assert.equal((await state("student_identity")).starts, 0);
  await page.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  assert.deepEqual(await freeze("student_identity"), {
    duration: 340,
    iterations: 1,
  });
  await page.screenshot({
    path: "screenshots/mobile-reserved-identity.png",
    format: "png",
  });
  await finish("student_identity");
  result.reservedTouchClick = true;

  const bagBounds = await page.eval(() => {
    const symbol = document.getElementById("icon-bag-shopping");
    const v = symbol.viewBox.baseVal;
    const probe = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    probe.setAttribute("width", "1");
    probe.setAttribute("height", "1");
    probe.style.position = "absolute";
    probe.style.left = "-1000px";
    const path = symbol.querySelector("path").cloneNode(true);
    probe.appendChild(path);
    document.body.appendChild(probe);
    const b = path.getBBox();
    const result = {
      viewBox: [v.x, v.y, v.width, v.height],
      ink: [b.x, b.y, b.width, b.height],
      padding: [
        b.x - v.x,
        b.y - v.y,
        v.x + v.width - b.x - b.width,
        v.y + v.height - b.y - b.height,
      ],
    };
    probe.remove();
    return result;
  });
  assert.ok(
    bagBounds.ink[1] < 0,
    "The source handle really extends above the original y=0 viewBox"
  );
  assert.ok(
    bagBounds.padding.every((padding) => padding >= 15.9),
    "The complete bag has padding on all four sides"
  );
  result.bagBounds = bagBounds;
  for (const [width, height, label] of [
    [1440, 900, "desktop"],
    [390, 844, "mobile"],
  ]) {
    await page.setViewport({ width, height, mobile: width < 600 });
    await navigate();
    target = await point("marketplace");
    if (width < 600) {
      await page.send("Input.dispatchTouchEvent", {
        type: "touchStart",
        touchPoints: [{ ...target, id: 1 }],
      });
      await page.send("Input.dispatchTouchEvent", {
        type: "touchEnd",
        touchPoints: [],
      });
    } else {
      await pointer("mouseMoved", target.x, target.y);
    }
    assert.ok(await freeze("marketplace", 0.25));
    const clip = await page.eval(() => {
      const r = document
        .querySelector('[data-service="marketplace"] .isbf-v2-workbench__icon')
        .getBoundingClientRect();
      return {
        x: r.x - 8,
        y: r.y - 8,
        width: r.width + 16,
        height: r.height + 16,
        scale: 4,
      };
    });
    const { data } = await page.send("Page.captureScreenshot", {
      format: "png",
      clip,
    });
    writeFileSync(
      `screenshots/${label}-bag-detail.png`,
      Buffer.from(data, "base64")
    );
    await finish("marketplace");
  }
  return result;
}
