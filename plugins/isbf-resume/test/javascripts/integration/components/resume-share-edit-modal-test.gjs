import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";
import ResumeShareEditModal from "discourse/plugins/isbf-resume/discourse/components/resume-share-edit-modal";

module("Integration | Component | ResumeShareEditModal", function (hooks) {
  setupRenderingTest(hooks);

  test("prefills all upload fields and saves through the versioned native review endpoint", async function (assert) {
    const payload = {
      title: "Original title",
      industry: "Finance",
      position: "Analyst",
      salary: "20k",
      experience: "3 years",
      description: "Original summary",
    };
    const reviewable = this.owner
      .lookup("service:store")
      .createRecord("reviewable", {
        id: 42,
        version: 3,
        payload,
        shared_resume: { status: "approved" },
      });
    const model = { reviewable };
    let saved;
    let closed = false;
    const close = () => {
      closed = true;
    };
    pretender.put("/review/42", (request) => {
      saved = JSON.parse(request.requestBody);
      return response({
        payload: { ...payload, title: "Reviewed title" },
        version: 4,
      });
    });
    await render(
      <template>
        <ResumeShareEditModal
          @closeModal={{close}}
          @inline={{true}}
          @model={{model}}
        />
      </template>
    );

    for (const name of Object.keys(payload)) {
      assert
        .form()
        .field(name)
        .hasValue(payload[name], `${name} starts with the submitted value`);
      assert
        .dom(`.form-kit__field[data-name="${name}"]`)
        .includesText(
          i18n(`isbf_resume.sharing.fields.${name}.title`),
          `${name} has a visible label`
        );
    }
    await formKit().field("description").fillIn("");
    await formKit().submit();
    assert.false(
      closed,
      "an approved resume stays open when its description is empty"
    );
    assert.strictEqual(
      saved,
      undefined,
      "an empty published description is blocked before requesting a save"
    );
    await formKit().field("description").fillIn(payload.description);
    await formKit().field("title").fillIn("Reviewed title");
    await formKit().submit();
    assert.strictEqual(
      saved.reviewable.payload.title,
      "Reviewed title",
      "saves the edited title"
    );
    assert.strictEqual(
      reviewable.version,
      4,
      "uses the native conflict version after saving"
    );
    assert.true(closed, "closes after the save succeeds");
  });
});
