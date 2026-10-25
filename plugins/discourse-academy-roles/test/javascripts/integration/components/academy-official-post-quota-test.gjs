import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { run } from "@ember/runloop";
import {
  clearRender,
  click,
  render,
  settled,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";
import AcademyOfficialPostQuota from "discourse/plugins/discourse-academy-roles/discourse/components/academy-official-post-quota";
import AcademyOfficialPostQuotaConnector from "discourse/plugins/discourse-academy-roles/discourse/connectors/admin-user-below-names/academy-official-post-quota";

const endpoint = "/academy-roles/admin/users/12/official-post-quota";
const scope = ".academy-official-post-quota";
const input = `${scope} input[name="limit"]`;
const submitButton = `${scope} button[type="submit"]`;

function quotaResponse(overrides = {}) {
  return response({
    official_post_quota: {
      limit: 0,
      used: 2,
      remaining: null,
      week_starts_at: "2026-10-19T00:00:00+08:00",
      resets_at: "2026-10-26T00:00:00+08:00",
      timezone: "Asia/Shanghai",
      exempt: false,
      official: true,
      ...overrides,
    },
  });
}

module("Integration | Component | Official post quota", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.currentUser.set("admin", true);
    this.siteSettings.academy_roles_enabled = true;
    this.user = { id: 12 };
    this.gets = 0;
    this.puts = [];
    pretender.get(endpoint, () => {
      this.gets++;
      return quotaResponse();
    });
    pretender.put(endpoint, (request) => {
      const data = JSON.parse(request.requestBody);
      this.puts.push(data);
      return quotaResponse({ limit: data.limit });
    });
  });

  test("loads the unlimited default with usage, reset timezone and account status", async function (assert) {
    pretender.get(endpoint, () => {
      this.gets++;
      return quotaResponse({ exempt: true, official: false });
    });
    await render(
      <template><AcademyOfficialPostQuota @user={{this.user}} /></template>
    );

    assert.strictEqual(this.gets, 1);
    assert.dom(input).hasValue("0");
    assert.dom(input).hasAttribute("type", "number");
    assert
      .dom(input)
      .hasAccessibleName(
        new RegExp(i18n("academy_roles.official_post_quota.limit"))
      );
    assert.dom(scope).includesText(
      i18n("academy_roles.official_post_quota.usage", {
        used: 2,
        remaining: i18n("academy_roles.official_post_quota.unlimited"),
      })
    );
    assert.dom(scope).includesText("Asia/Shanghai");
    assert
      .dom(scope)
      .includesText(i18n("academy_roles.official_post_quota.exempt"));
    assert
      .dom(scope)
      .includesText(i18n("academy_roles.official_post_quota.not_official"));
    assert
      .dom(submitButton)
      .isEnabled("exempt accounts can still be configured");
    assert.strictEqual(
      this.puts.length,
      0,
      "loading does not change the quota"
    );
  });

  test("sends only a numeric limit, disables pending controls and commits on success", async function (assert) {
    let pending;
    pretender.put(
      endpoint,
      (request) => {
        pending = request;
        this.puts.push(JSON.parse(request.requestBody));
        return quotaResponse({ limit: 6, remaining: 4 });
      },
      true
    );
    await render(
      <template><AcademyOfficialPostQuota @user={{this.user}} /></template>
    );
    await formKit().field("limit").fillIn("6");
    const saving = formKit().submit();
    await waitUntil(() => pending && document.querySelector(input)?.disabled);

    assert.deepEqual(
      this.puts,
      [{ limit: 6 }],
      "no counters or nested parameters are submitted"
    );
    assert.dom(input).isDisabled();
    assert.dom(submitButton).isDisabled();
    pretender.resolve(pending);
    await saving;

    assert.dom(input).isEnabled().hasValue("6");
    assert
      .dom(`${scope} .alert-success`)
      .hasText(
        i18n("academy_roles.official_post_quota.saved"),
        "success commits the FormKit draft"
      );
    assert.dom(scope).includesText(
      i18n("academy_roles.official_post_quota.usage", {
        used: 2,
        remaining: 4,
      })
    );
    await formKit().field("limit").fillIn("7");
    assert
      .dom(`${scope} .alert-success`)
      .doesNotExist("a new unsaved edit clears the saved indication");
  });

  test("rejects negative, fractional, empty and overflowing limits before sending a request", async function (assert) {
    await render(
      <template><AcademyOfficialPostQuota @user={{this.user}} /></template>
    );
    for (const invalid of ["-1", "1.5", "", "2147483648"]) {
      await formKit().field("limit").fillIn(invalid);
      await formKit().submit();
      assert
        .dom('[data-name="limit"]')
        .hasClass("has-error", `rejects ${invalid || "an empty field"}`);
      assert
        .dom('[data-name="limit"]')
        .includesText(i18n("academy_roles.official_post_quota.invalid_limit"));
    }
    assert.strictEqual(this.puts.length, 0);
    await formKit().field("limit").fillIn("2147483647");
    await formKit().submit();
    assert.deepEqual(
      this.puts,
      [{ limit: 2147483647 }],
      "the largest supported integer is accepted"
    );
  });

  test("retains the draft after a failed save and retries the same limit", async function (assert) {
    let reject = true;
    pretender.put(endpoint, (request) => {
      this.puts.push(JSON.parse(request.requestBody));
      return reject
        ? response(422, { errors: ["Quota update rejected"] })
        : quotaResponse({ limit: 8, remaining: 6 });
    });
    await render(
      <template><AcademyOfficialPostQuota @user={{this.user}} /></template>
    );
    await formKit().field("limit").fillIn("8");
    await formKit().submit();

    assert.dom(`${scope} [role="alert"]`).includesText("Quota update rejected");
    assert.dom(input).isEnabled().hasValue("8");
    assert.dom(`${scope} .alert-success`).doesNotExist();
    reject = false;
    await formKit().submit();

    assert.deepEqual(this.puts, [{ limit: 8 }, { limit: 8 }]);
    assert.dom(`${scope} .alert-error`).doesNotExist();
    assert.dom(`${scope} .alert-success`).exists();
    assert.dom(input).hasValue("8");
  });

  test("offers a load retry without showing an editable quota until loading succeeds", async function (assert) {
    let reject = true;
    pretender.get(endpoint, () => {
      this.gets++;
      return reject
        ? response(503, { errors: ["Quota unavailable"] })
        : quotaResponse({ limit: 3, remaining: 1 });
    });
    await render(
      <template><AcademyOfficialPostQuota @user={{this.user}} /></template>
    );

    assert.dom(`${scope} [role="alert"]`).includesText("Quota unavailable");
    assert.dom(input).doesNotExist();
    reject = false;
    await click(`${scope} button`);

    assert.strictEqual(this.gets, 2);
    assert.dom(`${scope} .alert-error`).doesNotExist();
    assert.dom(input).hasValue("3");
  });

  test("guards hidden accounts and isolates a new account from a delayed old response", async function (assert) {
    for (const [admin, enabled, id] of [
      [false, true, 12],
      [true, false, 12],
      [true, true, -1],
    ]) {
      this.currentUser.setProperties({ admin, moderator: !admin });
      this.siteSettings.academy_roles_enabled = enabled;
      this.user = { id };
      await render(
        <template><AcademyOfficialPostQuota @user={{this.user}} /></template>
      );
      assert.dom(scope).doesNotExist();
      await clearRender();
    }
    assert.strictEqual(
      this.gets,
      0,
      "moderators, disabled features and system users do not request quota data"
    );
    this.currentUser.set("admin", true);
    this.siteSettings.academy_roles_enabled = true;
    class AccountState {
      @tracked user = { id: 12 };
    }
    const state = new AccountState();
    let oldRequest;
    pretender.get(
      endpoint,
      (request) => {
        oldRequest = request;
        return quotaResponse({ limit: 99 });
      },
      true
    );
    pretender.get("/academy-roles/admin/users/14/official-post-quota", () =>
      quotaResponse({ limit: 5, remaining: 3 })
    );
    const rendering = render(
      <template>
        <AcademyOfficialPostQuotaConnector
          @outletArgs={{hash user=state.user}}
        />
      </template>
    );
    await waitUntil(() => oldRequest);
    run(() => {
      state.user = { id: 14 };
    });
    await waitUntil(() => document.querySelector(input)?.value === "5");
    assert.dom(input).hasValue("5", "the new account loads independently");
    pretender.resolve(oldRequest);
    await rendering;
    await settled();
    assert
      .dom(input)
      .hasValue("5", "the old response cannot overwrite the new account");
    assert.dom(scope).exists({ count: 1 });

    await formKit().field("limit").fillIn("7");
    pretender.get(endpoint, () => quotaResponse());
    run(() => {
      state.user = { id: 12 };
    });
    await settled();
    assert
      .dom(input)
      .hasValue(
        "0",
        "switching accounts discards the previous account's unsaved draft"
      );
  });
});
