import { click, currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  registerUniversalDeprecationHandler,
  unregisterUniversalDeprecationHandler,
} from "discourse/lib/deprecated";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("ISBF account switch admin links", function (needs) {
  needs.user({ admin: true });
  needs.settings({ isbf_account_switch_enabled: true });

  let resolverDeprecations;
  const captureDeprecation = (message, options) => {
    if (options.id === "discourse.deprecated-resolver-normalization") {
      resolverDeprecations.push(message);
    }
  };

  needs.hooks.beforeEach(() => {
    resolverDeprecations = [];
    registerUniversalDeprecationHandler(captureDeprecation);
  });

  needs.hooks.afterEach(() => {
    unregisterUniversalDeprecationHandler(captureDeprecation);
  });

  needs.pretender((server, helper) => {
    server.get("/admin/config/site_settings.json", () =>
      helper.response({ site_settings: [] })
    );

    server.get("/admin/plugins/isbf-account-switch.json", () =>
      helper.response({
        id: "isbf-account-switch",
        name: "isbf-account-switch",
        enabled: true,
        has_settings: true,
        humanized_name: "ISBF account switch",
        is_discourse_owned: false,
        admin_route: {
          label: "isbf_account_switch.admin.title",
          location: "isbf-account-switch",
          use_new_show_route: true,
        },
      })
    );

    server.get("/isbf/account-switch/admin/links", () =>
      helper.response({
        links: [
          {
            id: 1,
            user_a: { username: "alice" },
            user_b: { username: "bob" },
            requester: "alice",
            status: "pending_admin",
          },
          {
            id: 2,
            user_a: { username: "alice" },
            user_b: { username: "charlie" },
            requester: "charlie",
            status: "pending_target",
          },
          {
            id: 3,
            user_a: { username: "bob" },
            user_b: { username: "charlie" },
            requester: "bob",
            status: "approved",
          },
          {
            id: 4,
            user_a: { id: 4, username: null, name: null },
            user_b: { username: "bob" },
            requester: null,
            status: "pending_admin",
          },
          {
            id: 5,
            user_a: { username: "alice" },
            user_b: { id: 5, username: null, name: null },
            requester: "alice",
            status: "pending_admin",
          },
        ],
        audit_events: [
          {
            created_at: "2026-10-01T10:00:00Z",
            actor: "admin",
            action: "approved",
            account_link_id: 3,
          },
        ],
      })
    );
  });

  test("opens the links page directly without deprecated resolver normalization", async function (assert) {
    await visit("/admin/plugins/isbf-account-switch/links");

    const table = ".isbf-account-switch-admin table:first-of-type";
    assert
      .dom(`${table} tbody tr`)
      .exists({ count: 5 }, "live and historical account links are rendered");
    assert
      .dom(`${table} tbody tr:first-child td:first-child`)
      .hasText("@alice ↔ @bob", "the account pair is shown");
    assert
      .dom(`${table} tbody tr:first-child button:first-of-type`)
      .hasText(
        i18n("isbf_account_switch.admin.approve"),
        "pending administrator approval retains its approval action"
      );
    assert
      .dom(`${table} tbody tr:nth-child(2) button`)
      .hasText(
        i18n("isbf_account_switch.admin.reject"),
        "pending target verification retains its rejection action"
      );
    assert
      .dom(`${table} tbody tr:nth-child(3) button`)
      .hasText(
        i18n("isbf_account_switch.admin.revoke"),
        "approved links retain their revocation action"
      );
    assert
      .dom(".isbf-account-switch-admin table:nth-of-type(2) tbody")
      .includesText("approved", "the audit log is rendered");
    assert.deepEqual(
      resolverDeprecations,
      [],
      "the route and template resolve without deprecated normalization"
    );
  });

  test("opens the links page from the plugin navigation without deprecated resolver normalization", async function (assert) {
    await visit("/admin/plugins/isbf-account-switch/settings");
    await click('a[href="/admin/plugins/isbf-account-switch/links"]');

    assert.strictEqual(
      currentURL(),
      "/admin/plugins/isbf-account-switch/links",
      "the plugin navigation opens the existing links URL"
    );
    assert
      .dom(".isbf-account-switch-admin")
      .exists("the links page is rendered after navigation");
    assert.deepEqual(
      resolverDeprecations,
      [],
      "navigation resolves the route and template without deprecated normalization"
    );
  });

  test("marks deleted accounts and prevents approving their historical links", async function (assert) {
    await visit("/admin/plugins/isbf-account-switch/links");

    const rows = ".isbf-account-switch-admin table:first-of-type tbody";
    const deletedAccount = i18n("isbf_account_switch.admin.deleted_account");
    assert
      .dom(`${rows} tr:nth-child(4) td:first-child`)
      .hasText(
        `${deletedAccount} ↔ @bob`,
        "the missing first account is marked"
      );
    assert
      .dom(`${rows} tr:nth-child(5) td:first-child`)
      .hasText(
        `@alice ↔ ${deletedAccount}`,
        "the missing second account is marked"
      );
    assert
      .dom(`${rows} tr:nth-child(4) td:nth-child(2)`)
      .hasText(deletedAccount, "a deleted requester is marked");
    for (const rowNumber of [4, 5]) {
      assert
        .dom(`${rows} tr:nth-child(${rowNumber}) button:first-of-type`)
        .isDisabled("links to deleted accounts cannot be approved");
      assert
        .dom(`${rows} tr:nth-child(${rowNumber}) button:nth-of-type(2)`)
        .isEnabled("historical pending links can still be rejected");
    }
    assert
      .dom(`${rows} tr:first-child button:first-of-type`)
      .isEnabled("a live account link can still be approved");
  });
});
