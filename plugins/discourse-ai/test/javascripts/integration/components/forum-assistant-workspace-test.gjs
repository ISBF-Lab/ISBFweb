import { getOwner } from "@ember/owner";
import {
  click,
  fillIn,
  render,
  triggerKeyEvent,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { i18n } from "discourse-i18n";
import ForumAssistantWorkspace from "discourse/plugins/discourse-ai/discourse/components/forum-assistant-workspace";

const BASE = "/discourse-ai/ai-bot/forum-assistant/conversations";

module("Integration | Component | forum-assistant-workspace", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.status = {
      enabled: true,
      configured: true,
      can_ask: true,
      remaining_today: 19,
      daily_limit: 20,
    };
    getOwner(this)
      .lookup("service:current-user")
      .set("forum_assistant", this.status);
    this.detail = {
      conversation: {
        id: 7,
        title: "Where is the forum guide?",
        read_only: false,
      },
      messages: [
        {
          id: 70,
          post_number: 1,
          role: "user",
          raw: "Where is the forum guide?",
        },
        {
          id: 71,
          post_number: 2,
          role: "assistant",
          cooked: '<p>Read the <a href="/guides">forum guide</a>.</p>',
        },
      ],
      request: { status: "completed" },
    };
    pretender.get("/discourse-ai/ai-bot/forum-assistant/status.json", () =>
      response(this.status)
    );
    pretender.get(`${BASE}.json`, () =>
      response({ conversations: [this.detail.conversation], has_more: false })
    );
    pretender.get(`${BASE}/7.json`, () => response(this.detail));
    getOwner(this).lookup("service:router").replaceWith = () => {};
  });

  test("renders questions, answers and sources without topic-page controls", async function (assert) {
    await render(
      <template><ForumAssistantWorkspace @conversationId={{7}} /></template>
    );
    assert
      .dom(".forum-assistant-message.--user")
      .includesText("Where is the forum guide?");
    assert
      .dom(".forum-assistant-message.--assistant a")
      .hasAttribute("href", "/guides");
    assert
      .dom(".forum-assistant-workspace__history-item a")
      .hasAttribute(
        "href",
        "/discourse-ai/ai-bot/conversations?conversation=7"
      );
    assert
      .dom(".forum-assistant-workspace__back")
      .hasAttribute("href", "/isbf/workbench");
    assert
      .dom(".forum-assistant-workspace__header > :first-child")
      .hasAttribute(
        "aria-label",
        i18n("discourse_ai.forum_assistant.workspace.back")
      );
    assert.dom(".forum-assistant-workspace h1").exists({ count: 1 });
    assert
      .dom(".forum-assistant-workspace__header h1")
      .hasText(i18n("discourse_ai.forum_assistant.workspace.title"));
    assert
      .dom(".forum-assistant-workspace__conversation-title")
      .hasText(this.detail.conversation.title);
    assert
      .dom(".topic-area, .topic-map, .topic-timeline, input[type=file]")
      .doesNotExist();
    assert
      .dom(".forum-assistant-composer textarea")
      .hasAttribute(
        "aria-describedby",
        "forum-assistant-scope forum-assistant-allowance"
      );
  });

  test("makes bare forum paths clickable while preserving code, existing links and external text", async function (assert) {
    this.detail.messages[1].cooked =
      '<p>Source: /t/topic/41/1（forum source） Also /t/42/1，<code>/t/code/3</code> <a href="/guides">guide</a> https://elsewhere.invalid/t/topic/9</p>';
    await render(
      <template><ForumAssistantWorkspace @conversationId={{7}} /></template>
    );
    assert
      .dom('.forum-assistant-message__answer a[href="/t/topic/41/1"]')
      .exists();
    assert.dom('.forum-assistant-message__answer a[href="/t/42/1"]').exists();
    assert.dom('.forum-assistant-message__answer a[href="/guides"]').exists();
    assert.dom(".forum-assistant-message__answer code a").doesNotExist();
    assert
      .dom('.forum-assistant-message__answer a[href="/t/topic/9"]')
      .doesNotExist();
  });

  test("sends a follow-up in place using Enter and clears only the accepted draft", async function (assert) {
    let submitted;
    getOwner(this)
      .lookup("service:current-user")
      .set("user_option.send_shortcut", "enter");
    pretender.post(`${BASE}/7/messages.json`, (request) => {
      submitted = new URLSearchParams(request.requestBody).get("raw");
      const message = { id: 72, post_number: 3, role: "user", raw: submitted };
      this.detail.messages.push(message);
      return response({
        conversation_id: 7,
        message,
        request: { status: "queued" },
      });
    });
    await render(
      <template><ForumAssistantWorkspace @conversationId={{7}} /></template>
    );
    await fillIn(
      ".forum-assistant-composer textarea",
      "How do I use that guide?"
    );
    await triggerKeyEvent(
      ".forum-assistant-composer textarea",
      "keydown",
      "Enter"
    );
    assert.strictEqual(submitted, "How do I use that guide?");
    assert.dom(".forum-assistant-composer textarea").hasValue("");
    assert.dom(".forum-assistant-message.--user").exists({ count: 2 });
  });

  test("preserves Shift+Enter and input-method composition without submitting", async function (assert) {
    let submissions = 0;
    pretender.post(`${BASE}.json`, () => {
      submissions++;
      return response(500);
    });
    await render(<template><ForumAssistantWorkspace /></template>);
    await fillIn(
      ".forum-assistant-composer textarea",
      "An unfinished question"
    );
    await triggerKeyEvent(
      ".forum-assistant-composer textarea",
      "keydown",
      "Enter",
      { shiftKey: true }
    );
    await triggerKeyEvent(
      ".forum-assistant-composer textarea",
      "keydown",
      "Enter",
      { isComposing: true }
    );
    assert.strictEqual(submissions, 0);
  });

  test("switches the mobile history view and disables input when quota is unavailable", async function (assert) {
    this.status.can_ask = false;
    this.status.remaining_today = 0;
    await render(<template><ForumAssistantWorkspace /></template>);
    assert.dom(".forum-assistant-composer textarea").isDisabled();
    assert
      .dom(".forum-assistant-workspace__conversation-heading")
      .doesNotExist();
    assert
      .dom(
        ".forum-assistant-workspace__header .forum-assistant-workspace__open-history"
      )
      .hasText(i18n("discourse_ai.forum_assistant.workspace.history"))
      .hasAttribute("aria-controls", "forum-assistant-history")
      .hasAttribute("aria-expanded", "false");
    await click(".forum-assistant-workspace__open-history");
    assert.dom(".forum-assistant-workspace").hasClass("--history-open");
    assert
      .dom(".forum-assistant-workspace__open-history")
      .hasAttribute("aria-expanded", "true");
    assert.dom(".forum-assistant-workspace__back").exists();
    await click(".forum-assistant-workspace__close-history");

    assert.dom(".forum-assistant-workspace").doesNotHaveClass("--history-open");
    await waitUntil(() =>
      document.activeElement?.matches(
        ".forum-assistant-workspace__open-history"
      )
    );
    assert
      .dom(".forum-assistant-workspace__open-history")
      .hasAttribute("aria-expanded", "false")
      .isFocused();
    await click(".forum-assistant-workspace__open-history");
    await triggerKeyEvent(
      ".forum-assistant-workspace__new",
      "keydown",
      "Escape"
    );
    await waitUntil(() =>
      document.activeElement?.matches(
        ".forum-assistant-workspace__open-history"
      )
    );
    assert.dom(".forum-assistant-workspace").doesNotHaveClass("--history-open");
    assert.dom(".forum-assistant-workspace__open-history").isFocused();
  });
});
