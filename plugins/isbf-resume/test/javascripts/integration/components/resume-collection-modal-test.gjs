import { fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import ResumeCollectionModal from "discourse/plugins/isbf-resume/discourse/components/resume-collection-modal";

module("Integration | Component | ResumeCollectionModal", function (hooks) {
  setupRenderingTest(hooks);

  test("saves only the URL and closes after the server accepts it", async function (assert) {
    let body;
    let saved;
    let closed = false;
    const model = {
      url: "https://f.wps.cn/g/yhH9i8lN/",
      onSaved: (value) => (saved = value),
    };
    const close = () => (closed = true);
    pretender.put("/isbf-resume/collection.json", (request) => {
      body = request.requestBody;
      return response({ collection_url: "https://f.wps.cn/g/replacement/" });
    });
    await render(
      <template>
        <ResumeCollectionModal
          @closeModal={{close}}
          @inline={{true}}
          @model={{model}}
        />
      </template>
    );
    assert.dom('[data-name="url"] input').hasValue(model.url);
    await fillIn('[data-name="url"] input', "https://f.wps.cn/g/replacement/");
    await formKit().submit();
    assert.strictEqual(
      new URLSearchParams(body).get("url"),
      "https://f.wps.cn/g/replacement/"
    );
    assert.strictEqual(saved, "https://f.wps.cn/g/replacement/");
    assert.true(closed);
  });
});
