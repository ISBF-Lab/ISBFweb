import {
  click,
  find,
  render,
  settled,
  triggerEvent,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ResumePhoto from "discourse/plugins/isbf-resume/discourse/components/resume-photo";

const png =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC";
const existingPhoto = `data:image/png;base64,${png}`;

module("Integration | Component | ResumePhoto", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    this.sandbox = sinon.createSandbox();
  });

  hooks.afterEach(function () {
    this.sandbox.restore();
  });

  test("a valid PNG is decoded and read into the draft before generation resumes", async function (assert) {
    this.photo = "";
    const busyStates = [];
    let resolveRead;
    const readFinished = new Promise((resolve) => (resolveRead = resolve));
    const onBusy = (value) => {
      busyStates.push(value);
      if (!value) {
        resolveRead();
      }
    };
    const onChange = (value) => this.set("photo", value);
    await render(
      <template>
        <ResumePhoto
          @onBusy={{onBusy}}
          @onChange={{onChange}}
          @value={{this.photo}}
        />
      </template>
    );
    const input = find('input[type="file"]');
    const files = new DataTransfer();
    const bytes = Uint8Array.from(atob(png), (character) =>
      character.charCodeAt(0)
    );
    files.items.add(new File([bytes], "photo.png", { type: "image/png" }));
    input.files = files.files;
    await triggerEvent(input, "change");
    await readFinished;
    await settled();

    assert.strictEqual(
      this.photo,
      existingPhoto,
      "preserves the selected image bytes in the generated payload"
    );
    assert.deepEqual(
      busyStates,
      [true, false],
      "unblocks generation after decoding and reading complete"
    );
    assert
      .dom(".isbf-resume__photo img")
      .hasAttribute("src", existingPhoto, "shows the uploaded photo");
    assert
      .dom(".isbf-resume__error")
      .doesNotExist("does not report an error for a valid image");
  });

  test("an unsupported file is explained without replacing the existing photo", async function (assert) {
    const changes = [];
    const onChange = (value) => changes.push(value);
    await render(
      <template>
        <ResumePhoto @onChange={{onChange}} @value={{existingPhoto}} />
      </template>
    );
    const input = find('input[type="file"]');
    const files = new DataTransfer();
    files.items.add(
      new File(["not an image"], "resume.txt", { type: "text/plain" })
    );
    input.files = files.files;
    await triggerEvent(input, "change");

    assert
      .dom(".isbf-resume__error")
      .hasText(
        i18n("isbf_resume.photo_invalid"),
        "explains the accepted photo constraints"
      );
    assert
      .dom("img")
      .hasAttribute("src", existingPhoto, "keeps the previous photo");
    assert.deepEqual(
      changes,
      [],
      "does not write the unsupported file into the draft"
    );
  });

  test("removal clears the photo value and its occupied preview", async function (assert) {
    this.photo = existingPhoto;
    const onChange = (value) => this.set("photo", value);
    await render(
      <template>
        <ResumePhoto @onChange={{onChange}} @value={{this.photo}} />
      </template>
    );
    await click(".isbf-resume__photo button");

    assert.strictEqual(this.photo, "", "clears the photo in the draft");
    assert
      .dom(".isbf-resume__photo img")
      .doesNotExist("does not leave an empty photo preview");
    assert
      .dom('input[type="file"]')
      .exists("retains an accessible selection control");
  });

  test("an invalid replacement releases an earlier pending photo read", async function (assert) {
    let rejectRead;
    this.sandbox
      .stub(window, "createImageBitmap")
      .returns(new Promise((_resolve, reject) => (rejectRead = reject)));
    const busyStates = [];
    const changes = [];
    const onBusy = (value) => busyStates.push(value);
    const onChange = (value) => changes.push(value);
    await render(
      <template>
        <ResumePhoto @onBusy={{onBusy}} @onChange={{onChange}} />
      </template>
    );
    const input = find('input[type="file"]');
    const first = new DataTransfer();
    first.items.add(new File(["pending"], "photo.png", { type: "image/png" }));
    input.files = first.files;
    await triggerEvent(input, "change");
    assert.deepEqual(busyStates, [true], "marks the decoder as pending");

    const replacement = new DataTransfer();
    replacement.items.add(
      new File(["invalid"], "photo.txt", { type: "text/plain" })
    );
    input.files = replacement.files;
    await triggerEvent(input, "change");
    rejectRead(new Error("decoder no longer needed"));
    await settled();

    assert.false(
      busyStates.at(-1),
      "the invalid replacement does not leave generation blocked"
    );
    assert
      .dom(".isbf-resume__photo")
      .doesNotIncludeText(
        i18n("isbf_resume.photo_reading"),
        "clears the obsolete reading state"
      );
    assert.deepEqual(changes, [], "ignores the obsolete selection result");
  });

  test("leaving the photo stage releases its pending read state", async function (assert) {
    let rejectRead;
    this.sandbox
      .stub(window, "createImageBitmap")
      .returns(new Promise((_resolve, reject) => (rejectRead = reject)));
    this.showPhoto = true;
    const busyStates = [];
    const onBusy = (value) => busyStates.push(value);
    await render(
      <template>
        {{#if this.showPhoto}}<ResumePhoto @onBusy={{onBusy}} />{{/if}}
      </template>
    );
    const input = find('input[type="file"]');
    const files = new DataTransfer();
    files.items.add(new File(["pending"], "photo.png", { type: "image/png" }));
    input.files = files.files;
    await triggerEvent(input, "change");
    this.set("showPhoto", false);
    await settled();
    rejectRead(new Error("decoder no longer needed"));
    await settled();

    assert.deepEqual(
      busyStates,
      [true, false],
      "component teardown releases the parent's generation guard"
    );
    assert
      .dom('input[type="file"]')
      .doesNotExist("the previous stage's control is removed");
  });
});
