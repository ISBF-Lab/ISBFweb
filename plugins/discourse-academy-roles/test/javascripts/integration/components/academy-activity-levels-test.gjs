import { click, findAll, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import select from "discourse/tests/helpers/d-select";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";
import AcademyActivityLevels from "discourse/plugins/discourse-academy-roles/discourse/components/academy-activity-levels";

const ENDPOINT = "/academy-roles/admin/activity-levels";
const CATALOG = [
  {
    key: "topics_entered",
    group: "basic",
    periods: ["all_time", "recent"],
    percentage: false,
    maximum: false,
    months: false,
  },
  {
    key: "posts_read",
    group: "basic",
    periods: ["all_time", "recent"],
    percentage: false,
    maximum: false,
    months: false,
  },
  {
    key: "posts_read_percent",
    group: "advanced",
    periods: ["recent"],
    percentage: true,
    maximum: false,
    months: false,
  },
];

function level(id, value = 5) {
  return {
    id,
    name: "",
    period_days: 100,
    continuous_days: 0,
    max_check_gap_hours: 36,
    demotion_buffer_percent: 0,
    assigned_users: 3,
    conditions:
      id === "legacy-0"
        ? []
        : [{ metric: "topics_entered", period: "all_time", value }],
  };
}

function completedRun() {
  return {
    id: "run-1",
    revision: 1,
    status: "completed",
    processed: 3,
    total: 3,
    upgraded: 1,
    downgraded: 0,
    unchanged: 2,
    failed: 0,
  };
}

function button(label, root = document) {
  return [...root.querySelectorAll("button")].find(
    (element) => element.textContent.trim() === i18n(label)
  );
}

module("Integration | Component | Academy activity levels", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.currentUser.setProperties({ admin: true, moderator: false });
    this.model = {
      revision: 1,
      allow_demotion: true,
      initialized: true,
      catalog: CATALOG,
      levels: [level("legacy-0"), level("silver"), level("gold", 30)],
      recalculation: completedRun(),
      badge_options: [{ id: 51, name: "Contributor" }],
    };
    this.requests = [];
    pretender.get(`${ENDPOINT}/recalculation`, () =>
      response({ recalculation: completedRun() })
    );
    pretender.put(ENDPOINT, (request) => {
      const body = JSON.parse(request.requestBody);
      this.requests.push(body);
      return response({
        ...this.model,
        ...body,
        revision: body.revision + 1,
        recalculation: completedRun(),
      });
    });
  });

  test("only developers see the management form", async function (assert) {
    this.currentUser.setProperties({ admin: false, moderator: true });
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    assert.dom("form").doesNotExist();
  });

  test("renders custom levels, protects the base and keeps advanced fields collapsed", async function (assert) {
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    assert.dom(".academy-activity-levels__level").exists({ count: 3 });
    const cards = findAll(".academy-activity-levels__level");
    assert.strictEqual(
      button("academy_roles.activity_levels.delete_level", cards[0]),
      undefined
    );
    assert.true(
      Boolean(button("academy_roles.activity_levels.delete_level", cards[1]))
    );
    assert.dom('input[name="levels.1.continuous_days"]').doesNotExist();
    await click(
      cards[1].querySelector(".admin-config-area-card__toggle-button")
    );
    assert.dom('input[name="levels.1.continuous_days"]').hasValue("0");
    assert
      .dom(".academy-activity-levels")
      .includesText(i18n("academy_roles.activity_levels.participants"));
  });

  test("saves independent rules and stable identities without display-only metadata", async function (assert) {
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await formKit().field("levels.1.name").fillIn("Contributor");
    await formKit().field("allow_demotion").toggle();
    await formKit().submit();
    assert.strictEqual(this.requests.length, 1);
    assert.false(this.requests[0].allow_demotion);
    assert.strictEqual(this.requests[0].levels[1].name, "Contributor");
    assert.deepEqual(
      this.requests[0].levels.map((entry) => entry.id),
      ["legacy-0", "silver", "gold"]
    );
    assert.false("assigned_users" in this.requests[0].levels[1]);
    assert.false("number" in this.requests[0].levels[1]);
    assert.deepEqual(this.requests[0].confirmed_deleted_ids, []);
    assert
      .dom(".academy-activity-levels")
      .includesText(i18n("academy_roles.activity_levels.saved"));
  });

  test("adds a level and conditions through FormKit, resetting metric-specific values", async function (assert) {
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await click(button("academy_roles.activity_levels.add_level"));
    const cards = findAll(".academy-activity-levels__level");
    assert.strictEqual(cards.length, 4);
    await click(
      button("academy_roles.activity_levels.add_condition", cards[3])
    );
    await select('[name="levels.3.basic_conditions.0.metric"]', "posts_read");
    await formKit().field("levels.3.basic_conditions.0.value").fillIn("60");
    await formKit().submit();
    assert.strictEqual(this.requests[0].levels[3].id, null);
    assert.deepEqual(this.requests[0].levels[3].conditions, [
      { metric: "posts_read", period: "all_time", value: 60 },
    ]);
  });

  test("confirms affected accounts before deleting and retains the remaining identities", async function (assert) {
    let confirmation;
    this.owner.lookup("service:dialog").deleteConfirm = (options) => {
      confirmation = options;
    };
    pretender.get(`${ENDPOINT}/deletion-impact`, () =>
      response({ revision: 1, level_id: "silver", assigned_users: 7 })
    );
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await click(
      button(
        "academy_roles.activity_levels.delete_level",
        findAll(".academy-activity-levels__level")[1]
      )
    );
    assert
      .dom(".academy-activity-levels__level")
      .exists({ count: 3 }, "nothing is removed before confirmation");
    assert.true(confirmation.message.includes("7"));
    confirmation.didConfirm();
    await settled();
    assert.dom(".academy-activity-levels__level").exists({ count: 2 });
    assert
      .dom(".academy-activity-levels__level:last-child")
      .includesText("LV1");
    await formKit().submit();
    assert.deepEqual(
      this.requests[0].levels.map((entry) => entry.id),
      ["legacy-0", "gold"]
    );
    assert.deepEqual(this.requests[0].confirmed_deleted_ids, ["silver"]);
  });

  test("reset restores condition edits without saving them", async function (assert) {
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await select('[name="levels.1.basic_conditions.0.metric"]', "posts_read");
    await formKit().field("levels.1.basic_conditions.0.value").fillIn("60");
    await formKit().reset();
    assert
      .dom('select[name="levels.1.basic_conditions.0.metric"]')
      .hasValue("topics_entered");
    assert.dom('input[name="levels.1.basic_conditions.0.value"]').hasValue("5");
    assert.strictEqual(this.requests.length, 0);
  });

  test("retains edits when saving encounters a newer rules version", async function (assert) {
    pretender.put(ENDPOINT, () =>
      response(409, { errors: ["A newer version is available"] })
    );
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await formKit().field("levels.1.name").fillIn("Unsaved contributor");
    await formKit().submit();
    assert.dom('input[name="levels.1.name"]').hasValue("Unsaved contributor");
    assert
      .dom(".academy-activity-levels")
      .includesText("A newer version is available");
  });

  test("rejects an empty new level before making a save request", async function (assert) {
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await click(button("academy_roles.activity_levels.add_level"));
    await formKit().submit();
    assert.strictEqual(this.requests.length, 0);
    assert
      .dom(".academy-activity-levels__level")
      .exists({ count: 4 }, "the draft remains editable");
    assert
      .dom(".academy-activity-levels")
      .includesText(
        i18n("academy_roles.activity_levels.invalid_level", { level: 3 })
      );
  });

  test("saves cosmetic thresholds, mode-specific presets and a numeric badge binding", async function (assert) {
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await formKit().field("cosmetics.avatar_minimum_level_id").select("silver");
    await formKit()
      .field("cosmetics.name_color_minimum_level_id")
      .select("gold");
    await formKit().field("cosmetics.name_color_light").fillIn("c2188b");
    await formKit().field("cosmetics.name_color_dark").fillIn("ef82d1");
    await formKit().field("cosmetics.name_color_enabled").toggle();
    await formKit().field("levels.1.badge_id").select("51");
    await formKit().submit();
    assert.strictEqual(this.requests.length, 1);
    assert.deepEqual(this.requests[0].cosmetics, {
      avatar_minimum_level_id: "silver",
      name_color_enabled: true,
      name_color_minimum_level_id: "gold",
      name_color_light: "#c2188b",
      name_color_dark: "#ef82d1",
    });
    assert.strictEqual(this.requests[0].levels[1].badge_id, 51);
  });

  test("requires rebinding referenced levels before offering deletion", async function (assert) {
    let confirmed = false;
    this.owner.lookup("service:dialog").deleteConfirm = () => {
      confirmed = true;
    };
    pretender.get(`${ENDPOINT}/deletion-impact`, () =>
      response({
        revision: 1,
        assigned_users: 7,
        references: ["Magenta name color", "Celebration frame"],
      })
    );
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await click(
      button(
        "academy_roles.activity_levels.delete_level",
        findAll(".academy-activity-levels__level")[1]
      )
    );
    assert.false(confirmed);
    assert.dom(".academy-activity-levels__level").exists({ count: 3 });
    assert.dom(".academy-activity-levels").includesText("Celebration frame");
  });

  test("cosmetic-only saves preserve interleaved condition order for continuity fingerprints", async function (assert) {
    const conditions = [
      { metric: "posts_read_percent", period: "recent", value: 25, cap: 2000 },
      { metric: "topics_entered", period: "all_time", value: 5 },
    ];
    this.model.levels[1].conditions = conditions;
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    await formKit().field("cosmetics.avatar_minimum_level_id").select("silver");
    await formKit().submit();
    assert.strictEqual(this.requests.length, 1);
    assert.strictEqual(
      this.requests[0].cosmetics.avatar_minimum_level_id,
      "silver"
    );
    assert.deepEqual(this.requests[0].levels[1].conditions, conditions);
  });

  test("unavailable badge bindings can be explicitly cleared", async function (assert) {
    this.model.levels[1].badge_id = 999;
    await render(
      <template><AcademyActivityLevels @model={{this.model}} /></template>
    );
    assert.dom('select[name="levels.1.badge_id"]').hasValue("999");
    assert.dom(".academy-activity-levels__level").exists({ count: 3 });
    await formKit().field("levels.1.badge_id").select("__NONE__");
    await formKit().submit();
    assert.strictEqual(this.requests[0].levels[1].badge_id, null);
  });
});
