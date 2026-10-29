import { hash } from "@ember/helper";
import { click, find, render, settled, waitUntil } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import ComboBox from "discourse/select-kit/components/combo-box";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import selectKit from "discourse/tests/helpers/select-kit-helper";

const DEFAULT_CONTENT = [
  { id: 1, name: "foo" },
  { id: 2, name: "bar" },
  { id: 3, name: "baz" },
];

const DEFAULT_VALUE = 1;

class MeasuredComboBox extends ComboBox {
  didInsertElement() {
    super.didInsertElement(...arguments);
    this.onReady(this);
  }
}

const setDefaultState = (ctx, options = {}) => {
  const properties = Object.assign(
    {
      content: DEFAULT_CONTENT,
      value: DEFAULT_VALUE,
    },
    options
  );
  ctx.setProperties(properties);
};

module("Integration | Component | SelectKit | ComboBox", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.set("subject", selectKit());
  });

  for (const placement of ["top-start", "bottom-start"]) {
    test(`${placement} search stays anchored between content resize and positioning`, async function (assert) {
      setDefaultState(this);
      this.placement = placement;
      this.onReady = (component) => {
        this.component = component;
      };
      const fixture = document.getElementById("ember-testing");
      const originalStyle = fixture.getAttribute("style");
      Object.assign(fixture.style, {
        transform: "none",
        width: "100%",
        height: "100%",
      });
      let positionStub;

      try {
        await render(
          <template>
            <MeasuredComboBox
              @content={{this.content}}
              @onReady={{this.onReady}}
              @options={{hash
                filterable=true
                placement=this.placement
                mobilePlacement=this.placement
              }}
              @value={{this.value}}
            />
          </template>
        );
        find(".combo-box").style.cssText =
          "position:fixed;left:24px;top:160px;width:220px";
        await this.subject.expand();
        const panel = find(".select-kit-body");
        await waitUntil(() => panel.style.transform);
        await settled();
        const input = find(".filter-input");
        const header = find(".select-kit-header");
        const above = placement.startsWith("top");
        const edge = () => {
          const field = input.getBoundingClientRect();
          const trigger = header.getBoundingClientRect();
          return above
            ? field.bottom - trigger.top
            : field.top - trigger.bottom;
        };
        const before = edge();
        const beforeHeight = panel.getBoundingClientRect().height;
        positionStub = sinon
          .stub(this.component, "updateFloatingUiPosition")
          .resolves();

        await this.subject.fillInFilter("foo");
        assert.true(panel.getBoundingClientRect().height < beforeHeight);
        assert.true(
          Math.abs(edge() - before) < 1,
          "search keeps the same trigger edge before the next position update"
        );
        assert.dom(input).isFocused();
        assert.strictEqual(this.value, DEFAULT_VALUE);
      } finally {
        positionStub?.restore();
        if (find(".combo-box.is-expanded")) {
          await this.subject.collapse();
        }
        if (originalStyle === null) {
          fixture.removeAttribute("style");
        } else {
          fixture.setAttribute("style", originalStyle);
        }
      }
    });
  }

  test("selecting a row with a blank value", async function (assert) {
    setDefaultState(this, {
      content: [{ value: "", name: "default" }, ...DEFAULT_CONTENT],
      value: "latest",
      onChange: (value) => this.set("value", value),
    });

    await render(
      <template>
        <ComboBox
          @content={{this.content}}
          @nameProperty="name"
          @onChange={{this.onChange}}
          @options={{hash castInteger=true}}
          @value={{this.value}}
          @valueProperty="value"
        />
      </template>
    );

    await this.subject.expand();
    await this.subject.selectRowByValue("");

    assert.strictEqual(this.value, "", "onChange receives the blank value");
    assert.strictEqual(
      this.subject.header().name(),
      "default",
      "the blank-value row displays as selected before any save"
    );
  });

  test("options.clearable", async function (assert) {
    setDefaultState(this, {
      clearable: true,
      onChange: (value) => {
        this.set("value", value);
      },
    });

    await render(
      <template>
        <ComboBox
          @content={{this.content}}
          @onChange={{this.onChange}}
          @options={{hash clearable=this.clearable}}
          @value={{this.value}}
        />
      </template>
    );

    const header = this.subject.header();

    assert.dom(".btn-clear", header.el()).exists("shows the clear button");
    assert.strictEqual(header.value(), DEFAULT_VALUE.toString());

    await click(header.el().querySelector(".btn-clear"));

    assert
      .dom(".btn-clear", header.el())
      .doesNotExist("hides the clear button");
    assert.strictEqual(header.value(), null);
  });

  test("options.{caretUpIcon,caretDownIcon}", async function (assert) {
    setDefaultState(this, {
      caretUpIcon: "pencil",
      caretDownIcon: "trash-can",
    });

    await render(
      <template>
        <ComboBox
          @content={{this.content}}
          @options={{hash
            caretUpIcon=this.caretUpIcon
            caretDownIcon=this.caretDownIcon
          }}
          @value={{this.value}}
        />
      </template>
    );

    const header = this.subject.header().el();

    assert
      .dom(`.d-icon-${this.caretDownIcon}`, header)
      .exists("uses the icon provided");

    await this.subject.expand();

    assert
      .dom(`.d-icon-${this.caretUpIcon}`, header)
      .exists("uses the icon provided");
  });
});
