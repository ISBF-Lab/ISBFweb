import { clearRender, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import {
  clearRichEditorExtensions,
  resetRichEditorExtensions,
} from "discourse/lib/composer/rich-editor-extensions";
import { withPluginApi } from "discourse/lib/plugin-api";
import ProsemirrorEditor from "discourse/static/prosemirror/components/prosemirror-editor";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

module(
  "Integration | Component | ProsemirrorEditor | Async plugin lifecycle",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(() => clearRichEditorExtensions());
    hooks.afterEach(() => resetRichEditorExtensions());

    for (const removed of [false, true]) {
      test(`resolves a plugin with the editor ${removed ? "removed" : "active"}`, async function (assert) {
        let resolvePlugin;
        let initialized = false;
        let view;
        const pendingPlugin = new Promise((resolve) => {
          resolvePlugin = resolve;
        });
        const handleSetup = (editor) => {
          view = editor.view;
        };
        withPluginApi((api) => {
          api.registerRichEditorExtension({ plugins: () => pendingPlugin });
        });

        await render(
          <template><ProsemirrorEditor @onSetup={{handleSetup}} /></template>
        );
        assert.dom(".ProseMirror").exists();
        if (removed) {
          await clearRender();
        }

        resolvePlugin({
          view() {
            initialized = true;
            return {};
          },
        });
        await settled();

        assert.strictEqual(view.isDestroyed, removed);
        assert.strictEqual(initialized, !removed);
      });
    }
  }
);
