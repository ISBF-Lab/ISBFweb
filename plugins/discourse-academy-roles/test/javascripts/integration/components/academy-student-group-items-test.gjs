import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import AcademyStudentGroupItems from "discourse/plugins/discourse-academy-roles/discourse/components/academy-student-group-items";

module("Integration | Component | AcademyStudentGroupItems", function (hooks) {
  setupRenderingTest(hooks);

  test("only ready rows can be selected and exclusions retain accessible labels", async function (assert) {
    this.items = [
      { id: 1, student_number: "000123", status: "ready", selectable: true },
      {
        id: 2,
        student_number: "000124",
        status: "unregistered",
        selectable: false,
      },
    ];
    this.selectedIds = [1];
    this.onSelect = (id, event) => {
      assert.strictEqual(id, 1);
      assert.false(event.target.checked, "the ready row can be excluded");
    };
    await render(
      <template>
        <AcademyStudentGroupItems
          @items={{this.items}}
          @onSelect={{this.onSelect}}
          @preview={{true}}
          @selectedIds={{this.selectedIds}}
        />
      </template>
    );
    assert.dom('input[type="checkbox"]').exists({ count: 1 });
    assert.dom('input[type="checkbox"]').isChecked();
    assert.dom("label").includesText("000123");
    await click('input[type="checkbox"]');
  });
});
