import assert from "node:assert/strict";
import { test } from "node:test";
import {
  declarationKey,
  declarations,
  modalTags,
  protectedDeclaration,
} from "./check-isbf-dialogs.mjs";

test("detects custom modal markup without treating selector strings or ordinary controls as dialogs", () => {
  assert.equal(
    modalTags(
      '<template><DModal @title="Example" /><div role="alert">Error</div></template>'
    ).length,
    0
  );
  assert.equal(
    modalTags(
      '<template><section role="dialog" aria-modal="true">Content</section></template>'
    ).length,
    1
  );
  assert.equal(modalTags('<dialog id="application">Form</dialog>').length, 1);
  assert.equal(
    modalTags(
      "const selector=\"[role='dialog']\"; <template><div /></template>"
    ).length,
    0
  );
  assert.equal(
    modalTags('<template>{{! <div role="dialog"> }}<div /></template>').length,
    0
  );
});

test("finds nested shell and button overrides while preserving unrelated content styling", () => {
  const rules = declarations(`
    // .d-modal__container { border-radius: 0; }
    .example-modal {
      .d-modal__container { border-radius: 0; padding: var(--space-4); }
      @media (width < 600px) { .btn { border-radius: 4px; } }
      input { border-radius: 8px; }
      .heading { color: var(--primary); }
    }
    .unrelated { border-radius: 5px; }
  `).filter((entry) => protectedDeclaration(entry));
  assert.equal(rules.length, 3);
  assert.deepEqual(
    rules.map((entry) => entry.property),
    ["border-radius", "padding", "border-radius"]
  );
  assert.match(rules[2].context, /@media/);
});

test("an exception cannot authorize a different selector, value or source file", () => {
  const declaration = declarations(
    ".example-modal .d-modal__container { border-radius: 4px; }"
  )[0];
  const key = declarationKey("example.scss", declaration);
  assert.notEqual(key, declarationKey("other.scss", declaration));
  assert.notEqual(
    key,
    declarationKey("example.scss", { ...declaration, value: "0" })
  );
  assert.notEqual(
    key,
    declarationKey("example.scss", {
      ...declaration,
      selectors: ".other-modal .d-modal__container",
    })
  );
});

test("tracks button overrides even when the owning modal has an arbitrary class name", () => {
  const declaration = declarations(
    ".task-confirmation .btn { border-radius: 3px; }"
  )[0];
  assert.equal(
    protectedDeclaration(declaration, new Set(["task-confirmation"])),
    true
  );
});
