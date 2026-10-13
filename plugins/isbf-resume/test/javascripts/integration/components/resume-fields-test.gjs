import { find, findAll, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import Form from "discourse/components/form";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ResumeFields from "discourse/plugins/isbf-resume/discourse/components/resume-fields";
import { emptyResume } from "discourse/plugins/isbf-resume/discourse/lib/resume-data";
import { RESUME_FIELDS } from "discourse/plugins/isbf-resume/discourse/lib/resume-fields";

module("Integration | Component | ResumeFields", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  test("every resume control has persistent help associated with its input", async function (assert) {
    this.resume = emptyResume();
    this.sections = Object.values(RESUME_FIELDS);
    let formAPI;
    const registerForm = (api) => {
      formAPI = api;
    };

    await render(
      <template>
        <Form @data={{this.resume}} @onRegisterApi={{registerForm}} as |form|>
          {{#each this.sections key="id" as |section|}}
            <form.Object @name={{section.id}} as |object|>
              <ResumeFields @fields={{section.fields}} @scope={{object}} />
            </form.Object>
          {{/each}}
        </Form>
      </template>
    );

    assert.strictEqual(
      findAll(".isbf-resume__field").length,
      58,
      "renders all 58 requested controls"
    );

    for (const section of this.sections) {
      for (const definition of section.fields) {
        const selector = `[data-name="${section.id}.${definition.id}"]`;
        const help = find(`${selector} .form-kit__container-help-text`);
        const control = find(`${selector} input, ${selector} textarea`);

        assert
          .dom(help)
          .isVisible(`${section.id}.${definition.id} help remains visible`);
        assert
          .dom(help)
          .hasText(
            i18n(definition.helpKey),
            "uses the field-specific instructions"
          );
        assert.true(
          control
            .getAttribute("aria-describedby")
            ?.split(" ")
            .includes(help.id),
          `${section.id}.${definition.id} exposes its help to assistive technology`
        );
      }
    }

    formAPI.addError("basic.photo", {
      title: i18n("isbf_resume.fields.basic.photo.label"),
      message: i18n("isbf_resume.photo_invalid"),
    });
    await settled();

    assert
      .dom('[data-name="basic.photo"] input')
      .hasAttribute(
        "aria-invalid",
        "true",
        "also identifies a server-side photo error on the custom input"
      );
  });
});
