import { click, find, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import DialogHolder from "discourse/dialog-holder/components/dialog-holder";
import bodyClass from "discourse/helpers/body-class";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { parsePostData, response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import ISBFCalendarEntryEditor from "../../discourse/components/isbf-calendar-entry-editor";
import ISBFResourceDirectoryDialog from "../../discourse/components/isbf-resource-directory-dialog";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
module("ISBF | Integration | Dialog consistency", function (hooks) {
  setupRenderingTest(hooks, {
    stubRouter: true
  });
  test("inline dialogs receive the shared frame and buttons without a page or component whitelist", async function (assert) {
    this.region = null;
    await render(setComponentTemplate(createTemplateFactory(
    /*
      {{bodyClass this.region}}
    <DModal @inline={{true}} @title="Synthetic dialog">
      <:body><p>Content</p></:body>
      <:footer>
        <DButton class="btn-primary" @translatedLabel="Save" />
        <DButton class="btn-default" @translatedLabel="Cancel" />
      </:footer>
    </DModal>
    */
    {
      "id": null,
      "block": "[[[1,[28,[32,0],[[32,1,[\"region\"]]],null]],[1,\"\\n\"],[8,[32,2],null,[[\"@inline\",\"@title\"],[true,\"Synthetic dialog\"]],[[\"body\",\"footer\"],[[[[10,2],[12],[1,\"Content\"],[13]],[]],[[[1,\"\\n    \"],[8,[32,3],[[24,0,\"btn-primary\"]],[[\"@translatedLabel\"],[\"Save\"]],null],[1,\"\\n    \"],[8,[32,3],[[24,0,\"btn-default\"]],[[\"@translatedLabel\"],[\"Cancel\"]],null],[1,\"\\n  \"]],[]]]]]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        bodyClass,
        "this": this,
        DModal,
        DButton
      }),
      "isStrictMode": true
    }), templateOnly()));
    const frame = find(".d-modal__container");
    assert.strictEqual(getComputedStyle(frame).borderTopLeftRadius, "16px", "an unlisted inline dialog gets the shared frame");
    assert.strictEqual(getComputedStyle(find(".btn-primary")).borderRadius, "999px", "the primary action is a pill");
    assert.strictEqual(getComputedStyle(find(".btn-default")).minHeight, "44px", "the secondary action retains a touch target");
    this.region = "admin-interface";
    await settled();
    const appearance = () => {
      const style = getComputedStyle(frame);
      return [style.borderRadius, style.borderTopWidth, style.boxShadow];
    };
    const adminAppearance = appearance();
    find(".d-modal").classList.add("fk-d-menu-modal");
    assert.deepEqual(appearance(), adminAppearance, "admin appearance is independent of foreground task styling");
  });
  test("confirmation frames and actions work outside the previous admitted routes", async function (assert) {
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <DialogHolder />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,null,null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DialogHolder
      }),
      "isStrictMode": true
    }), templateOnly()));
    const dialog = this.owner.lookup("service:dialog");
    const confirmation = dialog.confirm({
      title: "Synthetic confirmation",
      message: "Confirm?"
    });
    await settled();
    assert.strictEqual(getComputedStyle(find(".dialog-content")).borderRadius, "16px", "the confirmation receives the same frame");
    assert.strictEqual(getComputedStyle(find(".dialog-footer .btn-default")).borderRadius, "999px", "cancel has the same shape");
    await click(".dialog-footer .btn-default");
    assert.false(await confirmation, "cancel preserves the native promise result");
    assert.dom(".dialog-content").doesNotExist("the dialog closes normally");
  });
  test("calendar entry errors retain fields and all-day retries preserve the exclusive UTC end", async function (assert) {
    let attempts = 0;
    let payload;
    this.closed = 0;
    this.reloaded = 0;
    this.model = {
      selectedDate: "2026-10-20",
      onSaved: () => this.reloaded++
    };
    this.close = () => this.closed++;
    pretender.post("/isbf/api/entries.json", request => {
      payload = parsePostData(request.requestBody).entry;
      return ++attempts === 1 ? response(503, {
        errors: ["Synthetic failure"]
      }) : response({});
    });
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ModalContainer />
    <ISBFCalendarEntryEditor
      @closeModal={{this.close}}
      @model={{this.model}}
    />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,null,null],[1,\"\\n\"],[8,[32,1],null,[[\"@closeModal\",\"@model\"],[[32,2,[\"close\"]],[32,2,[\"model\"]]]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ModalContainer,
        ISBFCalendarEntryEditor,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    const form = formKit(".isbf-calendar-entry-editor .form-kit");
    await form.field("title").fillIn("  Study session  ");
    await form.field("note").fillIn("Bring notes");
    await form.field("allDay").toggle();
    await click(".isbf-calendar-entry-editor .d-modal__footer .btn-primary");
    assert.dom(".isbf-calendar-entry-editor .form-kit__alert").exists("the failed request displays an error");
    assert.form().field("title").hasValue("  Study session  ", "the user can retry without re-entering the title");
    assert.strictEqual(this.closed, 0, "a failed submission stays open");
    await click(".isbf-calendar-entry-editor .d-modal__footer .btn-primary");
    assert.deepEqual(payload, {
      title: "Study session",
      note: "Bring notes",
      starts_at: "2026-10-20T00:00:00.000Z",
      ends_at: "2026-10-21T00:00:00.000Z",
      all_day: "true"
    }, "the all-day payload retains its exclusive end and original field names");
    assert.strictEqual(this.closed, 1, "a successful save closes once");
    assert.strictEqual(this.reloaded, 1, "the agenda refreshes once");
  });
  test("directory requests preserve their pending result and selected parent", async function (assert) {
    this.grades = [{
      id: "2026",
      label: "2026"
    }];
    this.close = () => {};
    this.submitted = (result, grade) => {
      this.result = result;
      this.grade = grade;
    };
    pretender.post("/isbf/learning/courses", request => {
      const data = parsePostData(request.requestBody);
      assert.strictEqual(data.name, "Economics", "the name is trimmed");
      assert.strictEqual(data.grade, "2026", "the selected parent is retained");
      return response({
        success: true,
        pending: true,
        reviewable_id: 321
      });
    });
    await render(setComponentTemplate(createTemplateFactory(
    /*
      <ModalContainer />
    <ISBFResourceDirectoryDialog
      @grade="2026"
      @grades={{this.grades}}
      @onClose={{this.close}}
      @onSubmitted={{this.submitted}}
      @request={{true}}
    />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,null,null],[1,\"\\n\"],[8,[32,1],null,[[\"@grade\",\"@grades\",\"@onClose\",\"@onSubmitted\",\"@request\"],[\"2026\",[32,2,[\"grades\"]],[32,2,[\"close\"]],[32,2,[\"submitted\"]],true]],null]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ModalContainer,
        ISBFResourceDirectoryDialog,
        "this": this
      }),
      "isStrictMode": true
    }), templateOnly()));
    assert.dom(".isbf-learning-course-dialog .btn-primary").isDisabled("an empty name cannot submit");
    await formKit().field("name").fillIn("  Economics  ");
    await click(".isbf-learning-course-dialog .d-modal__footer .btn-primary");
    assert.strictEqual(this.result.reviewable_id, 321, "the caller receives the pending review ID");
    assert.strictEqual(this.grade, "2026", "the caller receives the selected parent");
  });
});