import {
  click,
  fillIn,
  find,
  findAll,
  focus,
  render,
  settled,
  tab,
  triggerEvent,
  triggerKeyEvent,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import DFloatPortal from "discourse/float-kit/components/d-float-portal";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import ISBFV2AccountMenu from "../../discourse/components/isbf-v2-account-menu";

const card = ".isbf-v2-account-menu";
const trigger = ".isbf-v2-account-menu__trigger";
const panel = ".isbf-v2-account-menu__panel";
const surface = ".isbf-v2-account-menu__float > .d-menu-surface";

async function renderCard(context, mobile = false) {
  context.mobile = mobile;
  await render(
    <template>
      <ISBFV2AccountMenu @mobile={{context.mobile}} />
      <button class="after-card" type="button">Next control</button>
      <div id="d-menu-portals"></div>
    </template>
  );
  if (!mobile) {
    find(card).style.cssText =
      "position:fixed;left:100px;bottom:16px;width:228px";
    await waitUntil(() => find(card).classList.contains("is-enclosed"));
  } else {
    find(card).style.display = "block";
  }
}

async function openCard() {
  await triggerEvent(card, "mouseenter");
  await waitUntil(() => find(surface));
  await waitUntil(() => {
    const element = find(card);
    const width = element.getBoundingClientRect().width;
    const scale = width / parseFloat(getComputedStyle(element).width);
    const finished = find(".isbf-v2-account-menu__float")
      .getAnimations()
      .every(
        (animation) =>
          animation.playState === "finished" || animation.playState === "idle"
      );
    return (
      finished &&
      Math.abs(
        find(surface).getBoundingClientRect().width - width - 18 * scale
      ) < 1
    );
  });
}

module("ISBF | Integration | Account menu enclosure", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(async function () {
    await waitUntil(
      () =>
        getComputedStyle(document.documentElement)
          .getPropertyValue("--d-menu-panel-radius")
          .trim() === "24px",
      { timeout: 60000 }
    );
    this.currentUser.setProperties({
      name: "Example member",
      username: "member",
      admin: true,
      avatar_template: "/letter_avatar_proxy/v4/letter/m/000000/{size}.png",
    });
    this.siteSettings.isbf_account_switch_enabled = true;
    pretender.get("/isbf/account-switch/accounts", () =>
      response({
        links: [1, 2, 3, 4].map((id) => ({
          id,
          status: "approved",
          device_authorized: false,
          account: {
            id: 990000 + id,
            name: "Linked member " + id,
            username: "linked" + id,
            email_code_enabled: true,
            backup_codes_enabled: this.backupCodesEnabled,
            avatar_template: "/letter_avatar_proxy/v4/letter/l/000000/32.png",
          },
        })),
      })
    );
  });

  test("the shared frame surrounds the original card without moving or duplicating it", async function (assert) {
    await renderCard(this);
    const before = find(card).getBoundingClientRect();
    await openCard();
    const after = find(card).getBoundingClientRect();
    const outer = find(surface).getBoundingClientRect();
    const style = getComputedStyle(find(surface));
    const inset =
      parseFloat(style.paddingLeft) + parseFloat(style.borderLeftWidth);
    const cardStyle = getComputedStyle(find(card));
    const insetX = (inset * after.width) / parseFloat(cardStyle.width);
    const insetY = (inset * after.height) / parseFloat(cardStyle.height);
    assert.true(Math.abs(outer.left + insetX - after.left) < 1);
    assert.true(Math.abs(outer.right - insetX - after.right) < 1);
    assert.true(Math.abs(outer.bottom - insetY - after.bottom) < 1);
    assert.strictEqual(before.x, after.x);
    assert.strictEqual(before.y, after.y);
    assert.strictEqual(before.width, after.width);
    assert.strictEqual(findAll(".isbf-v2-side__account").length, 1);
    assert.dom(".isbf-v2-side__account b").hasText("Example member");
    assert.dom(".isbf-v2-side__account small").hasText("@member");
    assert.strictEqual(style.borderRadius, "24px");
  });

  test("verification stays inside the scrolling body above a stationary card", async function (assert) {
    await renderCard(this);
    await openCard();
    const before = find(card).getBoundingClientRect();
    await click(".isbf-v2-account-menu__linked-account > button");
    assert.dom(".isbf-v2-account-menu__verify").exists();
    assert
      .dom(find(".isbf-v2-account-menu__account-name"))
      .hasText("Linked member 1");
    assert.strictEqual(getComputedStyle(find(panel)).overflowY, "auto");
    find(panel).scrollTop = find(panel).scrollHeight;
    await settled();
    const after = find(card).getBoundingClientRect();
    assert.strictEqual(before.y, after.y);
    assert.strictEqual(before.height, after.height);
    assert.true(find(surface).getBoundingClientRect().bottom > after.bottom);
    assert
      .dom(".isbf-v2-account-menu__card-space")
      .hasAttribute("aria-hidden", "true");
  });

  test("portaled verification selectors keep the account menu and drafts open", async function (assert) {
    this.backupCodesEnabled = true;
    sinon.stub(DFloatPortal.prototype, "inline").get(function () {
      return this.args.inline ?? false;
    });
    await renderCard(this);
    await openCard();
    await click(".isbf-v2-account-menu__linked-account > button");
    await fillIn(
      ".isbf-v2-account-menu__verify input[type='password']",
      "Synthetic draft"
    );
    const token =
      ".isbf-v2-account-menu__verify input[name='secondFactorToken']";
    await fillIn(token, "123456");
    const selects = findAll(".isbf-v2-account-menu__verify .d-select__trigger");
    assert.strictEqual(selects.length, 2);
    for (const select of selects) {
      await click(select);
      const options = find("#d-menu-portals .d-select__options");
      assert.dom(options).exists();
      assert.false(find(card).contains(options));
      assert.true(options.contains(document.activeElement));
      await triggerKeyEvent(document.activeElement, "keydown", "Escape");
      assert.dom("#d-menu-portals .d-select__options").doesNotExist();
      assert.dom(surface).exists();
      assert
        .dom(".isbf-v2-account-menu__verify input[type='password']")
        .hasValue("Synthetic draft");
      assert.dom(token).hasValue("123456");
    }
    await click(selects[1]);
    await click(findAll("#d-menu-portals .d-select__option")[1]);
    assert.dom(surface).exists();
    assert
      .dom(".isbf-v2-account-menu__verify select[name='secondFactorMethod']")
      .hasValue("2");
    assert
      .dom(".isbf-v2-account-menu__verify input[type='password']")
      .hasValue("Synthetic draft");
    assert.dom(token).hasValue("123456");
  });

  test("Escape restores the original three-dot button", async function (assert) {
    await renderCard(this);
    await openCard();
    await focus(panel + " > a");
    await triggerKeyEvent(panel + " > a", "keydown", "Escape");
    await waitUntil(() => !find(surface));
    assert.strictEqual(document.activeElement, find(trigger));
    assert.dom(".isbf-v2-side__account").exists({ count: 1 });
  });

  test("Tab leaves the last action without pulling focus back into the card", async function (assert) {
    await renderCard(this);
    await openCard();
    const actions = findAll(panel + " > button");
    await focus(actions.at(-1));
    await tab();
    await waitUntil(() => !find(surface));
    assert.dom(document.activeElement).hasClass("after-card");
  });

  test("mobile retains its separate floating account menu", async function (assert) {
    await renderCard(this, true);
    await click(trigger);
    assert.dom(card).doesNotHaveClass("is-enclosed");
    assert.dom(panel).exists();
    assert.strictEqual(
      getComputedStyle(find(".isbf-v2-account-menu__card-space")).display,
      "none"
    );
    assert.dom(".isbf-v2-side__account").doesNotExist();
  });
});
