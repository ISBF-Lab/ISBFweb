import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import formKit from "discourse/tests/helpers/form-kit-helper";
import AcademyStudentGroupForm from "discourse/plugins/discourse-academy-roles/discourse/components/academy-student-group-form";

module("Integration | Component | AcademyStudentGroupForm", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.options = {
      groups: [{ id: 12, name: "alumni" }],
      alumni_group_id: 12,
      max_rows: 1500,
      max_bytes: 1048576,
    };
    this.previews = [];
    this.invalidations = 0;
    this.preview = (data) => this.previews.push(data);
    this.invalidate = () => this.invalidations++;
  });

  test("keeps leading zeroes and invalidates a preview when conditions change", async function (assert) {
    await render(
      <template>
        <AcademyStudentGroupForm
          @onInvalidate={{this.invalidate}}
          @onPreview={{this.preview}}
          @options={{this.options}}
        />
      </template>
    );
    await formKit().field("student_numbers").fillIn("000123\n000124");
    await formKit().submit();
    assert.strictEqual(this.previews.length, 1);
    assert.strictEqual(
      this.previews[0].get("student_numbers"),
      "000123\n000124"
    );
    assert.strictEqual(this.previews[0].get("mode"), "graduation");
    assert.true(this.invalidations > 0);
    assert
      .dom("textarea")
      .hasValue("000123\n000124", "the form draft is retained");
  });

  test("rejects an oversized list before requesting a preview", async function (assert) {
    await render(
      <template>
        <AcademyStudentGroupForm
          @onInvalidate={{this.invalidate}}
          @onPreview={{this.preview}}
          @options={{this.options}}
        />
      </template>
    );
    await formKit()
      .field("student_numbers")
      .fillIn(
        Array.from({ length: 1501 }, (_, index) => String(index)).join("\n")
      );
    await formKit().submit();
    assert.strictEqual(this.previews.length, 0);
    assert.dom('[role="alert"]').exists();
  });

  test("blocks graduation when the alumni group is unavailable", async function (assert) {
    this.options.alumni_group_id = null;
    await render(
      <template>
        <AcademyStudentGroupForm
          @onInvalidate={{this.invalidate}}
          @onPreview={{this.preview}}
          @options={{this.options}}
        />
      </template>
    );
    await formKit().field("student_numbers").fillIn("000123");
    await formKit().submit();
    assert.strictEqual(this.previews.length, 0);
    assert.dom('[role="alert"]').exists();
  });
});
