import {
  click,
  focus,
  settled,
  triggerKeyEvent,
  visit,
  waitFor,
} from "@ember/test-helpers";
import { test } from "qunit";
import { USER_OPTION_COMPOSITION_MODES } from "discourse/lib/constants";
import {
  acceptance,
  loggedInUser,
} from "discourse/tests/helpers/qunit-helpers";

const RECENT_USER = { username: "recent_member", name: "Recent Member" };
const MATCHED_USER = { username: "matched_member", name: "Matched Member" };

acceptance("ISBF | Homepage composer mentions", function (needs) {
  needs.user();
  needs.settings({
    default_composer_category: "10",
    enable_mentions: true,
  });

  needs.pretender((server, helper) => {
    server.get("/filter.json", () =>
      helper.response({ users: [], topic_list: { topics: [] } })
    );
    server.post("/isbf/views/impressions", () => helper.response({}));
    server.get("/similar_topics", () =>
      helper.response({ similar_topics: [] })
    );
    server.get("/u/search/users", ({ queryParams }) => {
      const { term, last_seen_users: lastSeenUsers } = queryParams;
      let users = [];
      if (term === "" && lastSeenUsers === "true") {
        users = [RECENT_USER];
      } else if (term === "m" && !lastSeenUsers) {
        users = [MATCHED_USER];
      }
      return helper.response({ users });
    });
    server.get("/composer/mentions", () =>
      helper.response({
        users: [MATCHED_USER.username],
        user_reasons: {},
        groups: {},
        group_reasons: {},
        max_users_notified_per_group_mention: 100,
      })
    );
  });

  for (const [mode, editor] of [
    ["markdown", "textarea.d-editor-input"],
    ["rich", ".ProseMirror.d-editor-input"],
  ]) {
    test(`suggests users before a name is entered in the ${mode} editor`, async function (assert) {
      loggedInUser().set(
        "user_option.composition_mode",
        USER_OPTION_COMPOSITION_MODES[mode]
      );

      await visit("/latest");
      await click(".isbf-v2-compose__button");
      await waitFor(editor);
      await focus(editor);
      document.execCommand("insertText", false, "@");
      await settled();
      await triggerKeyEvent(editor, "keyup", "@");

      assert.dom(".ac-user .username").hasText(RECENT_USER.username);

      document.execCommand("insertText", false, "m");
      await settled();
      await triggerKeyEvent(editor, "keyup", "M");
      assert.dom(".ac-user .username").hasText(MATCHED_USER.username);

      await click(".ac-user li a");
      assert.dom(".ac-user").doesNotExist();
      assert.strictEqual(
        this.owner.lookup("service:composer").model.reply.trim(),
        `@${MATCHED_USER.username}`
      );
    });
  }
});
