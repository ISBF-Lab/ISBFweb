import { module, test } from "qunit";
import { errorPreview } from "../../discourse/lib/error-preview";

module("ISBF | Unit | Error preview", function () {
  test("preview parameters are ignored outside development", function (assert) {
    const params = new URLSearchParams("preview_error=403&preview_scheme=dark");
    assert.strictEqual(errorPreview(params, { development: false }), undefined);
  });

  test("only known scenarios and color schemes are accepted", function (assert) {
    assert.strictEqual(
      errorPreview(new URLSearchParams("preview_error=toString"), {
        development: true,
      }),
      undefined
    );
    const preview = errorPreview(
      new URLSearchParams("preview_error=network&preview_scheme=invalid"),
      { development: true }
    );
    assert.strictEqual(preview.error.status, 0);
    assert.strictEqual(preview.error.readyState, 0);
    assert.strictEqual(preview.scheme, null);
  });

  test("HTTP previews keep the selected code and optional color scheme", function (assert) {
    const preview = errorPreview(
      new URLSearchParams("preview_error=503&preview_scheme=light"),
      { development: true }
    );
    assert.strictEqual(preview.error.status, 503);
    assert.strictEqual(preview.scheme, "light");
  });
});
