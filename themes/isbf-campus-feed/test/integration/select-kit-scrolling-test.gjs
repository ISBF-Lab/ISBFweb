import { hash } from "@ember/helper";
import { find, findAll, render, settled, waitUntil } from "@ember/test-helpers";
import { module, test } from "qunit";
import CategoryChooser from "discourse/select-kit/components/category-chooser";
import ComboBox from "discourse/select-kit/components/combo-box";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import selectKit from "discourse/tests/helpers/select-kit-helper";

const body = ".category-chooser .select-kit-body";
const collection = `${body} .select-kit-collection`;
const filter = `${body} .filter-input`;

async function openChooser(context) {
  context.value = 1;
  context.onChange = (value) => context.set("value", value);
  await render(
    <template>
      <CategoryChooser
        @onChange={{context.onChange}}
        @options={{hash placement="top-start" mobilePlacement="top-start"}}
        @value={{context.value}}
      />
    </template>
  );
  find(".category-chooser").style.cssText =
    "position:fixed;left:100px;bottom:24px;width:220px";
  context.subject = selectKit(".category-chooser");
  await context.subject.expand();
  await waitUntil(() => find(body)?.style.transform);
  await settled();
  await Promise.all(
    find(body)
      .getAnimations()
      .map((animation) => animation.finished)
  );
}

function scrollToEnd() {
  const list = find(collection);
  list.scrollTop =
    getComputedStyle(list).flexDirection === "column-reverse"
      ? -list.scrollHeight
      : list.scrollHeight;
  return list;
}

module("ISBF | Integration | SelectKit scrolling", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(async function () {
    this.fixture = document.getElementById("ember-testing");
    this.fixtureStyle = this.fixture.getAttribute("style");
    // The runner halves this fixture; fixed menu geometry needs CSS pixels.
    Object.assign(this.fixture.style, {
      transform: "none",
      width: "100%",
      height: "100%",
    });
    await waitUntil(
      () =>
        getComputedStyle(document.documentElement)
          .getPropertyValue("--d-menu-panel-radius")
          .trim() === "24px",
      { timeout: 60000 }
    );
    await document.fonts.ready;
  });

  hooks.afterEach(function () {
    if (this.fixtureStyle === null) {
      this.fixture.removeAttribute("style");
    } else {
      this.fixture.setAttribute("style", this.fixtureStyle);
    }
  });

  test("long category lists scroll to their far end while search stays in place", async function (assert) {
    await openChooser(this);
    const inputTop = find(filter).getBoundingClientRect().top;
    const panel = find(body);
    const cursor = find(collection);
    await waitUntil(() =>
      cursor.style.getPropertyValue("--d-menu-highlight-y")
    );
    const beforeHighlight = parseFloat(
      cursor.style.getPropertyValue("--d-menu-highlight-y")
    );
    const list = scrollToEnd();
    await settled();
    await waitUntil(
      () =>
        Math.abs(
          parseFloat(cursor.style.getPropertyValue("--d-menu-highlight-y")) -
            beforeHighlight
        ) < 1
    );
    assert.true(
      Math.abs(
        parseFloat(cursor.style.getPropertyValue("--d-menu-highlight-y")) -
          beforeHighlight
      ) < 1,
      "the visual cursor scrolls in the same coordinate system as the options"
    );
    assert.dom(list).hasClass("d-menu-highlight__viewport");
    assert.strictEqual(panel.dataset.dMenuReady, undefined);
    assert.strictEqual(
      getComputedStyle(panel).overflowY,
      "hidden",
      "the shared surface overrides the outer scroll container"
    );
    assert.true(list.scrollHeight > list.clientHeight);
    assert.true(Math.abs(list.scrollTop) > 10);
    const lastRow = findAll(`${collection} .select-kit-row`).at(-1);
    const rowRect = lastRow.getBoundingClientRect();
    const listRect = list.getBoundingClientRect();
    assert.true(rowRect.bottom > listRect.top);
    assert.true(rowRect.top < listRect.bottom);
    assert.true(
      Math.abs(find(filter).getBoundingClientRect().top - inputTop) < 1
    );
    assert.true(Math.abs(panel.scrollTop) < 1);
    assert.dom(filter).isFocused();
  });

  test("partially scrolled highlights stay clipped outside the stationary search field", async function (assert) {
    this.choices = Array.from({ length: 30 }, (_, index) => ({
      id: index + 1,
      name: `Choice ${index + 1}`,
    }));
    await render(
      <template>
        <ComboBox
          @content={{this.choices}}
          @options={{hash filterable=true placement="top-start"}}
          @value={{1}}
        />
      </template>
    );
    find(".combo-box").style.cssText =
      "position:fixed;left:100px;bottom:24px;width:220px";
    await selectKit(".combo-box").expand();
    const panel = find(".combo-box .select-kit-body");
    const viewport = panel.querySelector(".select-kit-collection");
    const input = panel.querySelector(".filter-input");
    await waitUntil(() => viewport.hasAttribute("data-d-menu-ready"));
    await Promise.all(
      panel.getAnimations().map((animation) => animation.finished)
    );
    const row = viewport.querySelector("[data-d-menu-selected]");
    const above = getComputedStyle(viewport).flexDirection === "column-reverse";
    const start = viewport.getBoundingClientRect();
    const selected = row.getBoundingClientRect();
    viewport.scrollTop += above
      ? -(start.bottom - selected.bottom + selected.height / 2)
      : selected.top - start.top + selected.height / 2;
    await settled();
    await new Promise(requestAnimationFrame);
    const bounds = viewport.getBoundingClientRect();
    const partial = row.getBoundingClientRect();
    assert.true(
      above
        ? partial.top < bounds.bottom && partial.bottom > bounds.bottom
        : partial.top < bounds.top && partial.bottom > bounds.top
    );
    assert.dom(viewport).hasClass("d-menu-highlight__viewport");
    assert.strictEqual(getComputedStyle(viewport).overflowY, "auto");
    assert.strictEqual(
      getComputedStyle(viewport, "::before").position,
      "absolute"
    );
    assert.strictEqual(getComputedStyle(panel, "::before").opacity, "0");
    assert.false(viewport.contains(input));
    const cursorBounds = () => {
      const rect = viewport.getBoundingClientRect();
      const scale = rect.height / viewport.offsetHeight;
      const top =
        rect.top +
        viewport.clientTop * scale +
        (parseFloat(viewport.style.getPropertyValue("--d-menu-highlight-y")) -
          viewport.scrollTop) *
          scale;
      const height =
        parseFloat(
          viewport.style.getPropertyValue("--d-menu-highlight-height")
        ) * scale;
      return { top, bottom: top + height };
    };
    const cursor = cursorBounds();
    assert.true(Math.abs(cursor.top - partial.top) < 1);
    assert.true(
      above
        ? Math.min(cursor.bottom, bounds.bottom) <=
            input.getBoundingClientRect().top
        : Math.max(cursor.top, bounds.top) >=
            input.getBoundingClientRect().bottom
    );
    viewport.scrollTop += (above ? -1 : 1) * selected.height;
    await settled();
    await new Promise(requestAnimationFrame);
    const outside = cursorBounds();
    assert.strictEqual(
      Math.max(
        0,
        Math.min(outside.bottom, bounds.bottom) -
          Math.max(outside.top, bounds.top)
      ),
      0,
      "the fully scrolled cursor has no visible paint in the collection or search"
    );
  });

  test("searching and clearing keep focus, the selected value and the trigger edge", async function (assert) {
    await openChooser(this);
    const input = find(filter);
    const edge = () =>
      input.getBoundingClientRect().bottom -
      find(".category-chooser .select-kit-header").getBoundingClientRect().top;
    const initial = edge();
    for (const query of ["bug", "no-such-category", ""]) {
      await this.subject.emptyFilter();
      if (query) {
        await this.subject.fillInFilter(query);
      }
      await waitUntil(
        () => !find(".category-chooser").classList.contains("is-loading")
      );
      await new Promise((resolve) =>
        requestAnimationFrame(() => requestAnimationFrame(resolve))
      );
      assert.dom(input).isFocused();
      assert.true(
        Math.abs(edge() - initial) < 1,
        `${query || "cleared"}: filter edge ${edge()} / initial ${initial}; above=${find(".category-chooser").classList.contains("is-placed-above")}`
      );
      assert.strictEqual(this.value, 1);
      assert.dom(body).isVisible();
    }
  });

  test("category selection still updates the original callback and closes the list", async function (assert) {
    await openChooser(this);
    scrollToEnd();
    await this.subject.selectRowByValue(2);
    assert.strictEqual(this.value, 2);
    assert.dom(".category-chooser").doesNotHaveClass("is-expanded");
  });
});
