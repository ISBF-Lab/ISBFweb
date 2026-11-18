import { getOwner } from "@ember/owner";
import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ForumAssistantStatus from "discourse/plugins/discourse-ai/discourse/components/forum-assistant-status";

module("Integration | Component | forum-assistant-status", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    getOwner(this)
      .lookup("service:current-user")
      .set("forum_assistant", { restricted: true });
  });

  test("shows quota state and lets the owner stop question checking", async function (assert) {
    let busy = true;
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response({
        enabled: true,
        configured: true,
        restricted: true,
        can_ask: !busy,
        busy,
        remaining_today: 19,
        daily_limit: 20,
        resets_at: "2026-11-18T00:00:00+08:00",
      })
    );
    pretender.post("/discourse-ai/ai-bot/forum-assistant/cancel.json", () => {
      busy = false;
      return response(204);
    });
    await render(<template><ForumAssistantStatus /></template>);
    assert.dom(".forum-assistant-status [role='status']").exists();
    assert.dom(".forum-assistant-status .d-icon-pause").exists();
    await click(".forum-assistant-status button:has(.d-icon-pause)");
    assert.dom(".forum-assistant-status .d-icon-pause").doesNotExist();
    assert.dom(".forum-assistant-status [role='status']").includesText("19");
  });

  test("offers a fresh conversation for an old read-only conversation", async function (assert) {
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response({ enabled: true, configured: true, restricted: true })
    );
    await render(
      <template><ForumAssistantStatus @readOnly={{true}} /></template>
    );
    assert
      .dom(".forum-assistant-status a")
      .hasAttribute("href", "/discourse-ai/ai-bot/conversations");
    assert.dom(".forum-assistant-status .d-icon-pause").doesNotExist();
  });
});
