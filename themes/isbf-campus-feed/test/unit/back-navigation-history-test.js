import { module, test } from "qunit";
import BackNavigationHistory from "../../discourse/lib/back-navigation-history";

function storage() {
  const data = new Map();
  return {
    getObject(key) {
      return JSON.parse(data.get(key) ?? "null");
    },
    setObject({ key, value }) {
      data.set(key, JSON.stringify(value));
    },
  };
}

function move(browser, uuid, url) {
  browser.history.state = { uuid };
  browser.location = new URL(url, "https://forum.example");
}

function visit(history, browser, uuid, url, replace = false) {
  history.capture();
  move(browser, uuid, url);
  history.commit(replace);
}

module("ISBF | Unit | Lib | back-navigation-history", function (hooks) {
  hooks.beforeEach(function () {
    this.storage = storage();
    this.browser = { history: {} };
    move(this.browser, "source", "/search?q=campus&order=latest#results");
    this.history = new BackNavigationHistory(this.storage, this.browser);
  });

  test("returning from a topic retains the exact source page", function (assert) {
    visit(this.history, this.browser, "topic", "/t/campus/123/1");
    assert.strictEqual(
      this.history.previousURL,
      "/search?q=campus&order=latest#results",
      "the return target retains filters and its fragment"
    );
  });

  test("back and forward move the return target without creating a loop", function (assert) {
    visit(this.history, this.browser, "profile", "/u/student/activity/topics");
    visit(this.history, this.browser, "badge", "/badges/1/basic");
    move(this.browser, "profile", "/u/student/activity/topics");
    this.history.traverse();
    this.history.commit();
    assert.strictEqual(
      this.history.previousURL,
      "/search?q=campus&order=latest#results",
      "returning to the profile exposes its original predecessor"
    );
    move(this.browser, "source", "/search?q=campus&order=latest#results");
    this.history.traverse();
    assert.strictEqual(
      this.history.previousURL,
      null,
      "consecutive returns stop at the first recorded entry"
    );
    move(this.browser, "profile", "/u/student/activity/topics");
    this.history.traverse();
    assert.strictEqual(
      this.history.previousURL,
      "/search?q=campus&order=latest#results",
      "browser forward restores the predecessor"
    );
    visit(this.history, this.browser, "marketplace", "/isbf/marketplace");
    assert.strictEqual(
      this.history.previousURL,
      "/u/student/activity/topics",
      "a new navigation after back uses the current page"
    );
    move(this.browser, "profile", "/u/student/activity/topics");
    this.history.traverse();
    move(this.browser, "marketplace", "/isbf/marketplace");
    this.history.traverse();
    assert.strictEqual(
      this.history.previousURL,
      "/u/student/activity/topics",
      "the new forward branch remains navigable"
    );
  });

  test("address replacements do not add a return step", function (assert) {
    visit(this.history, this.browser, "query", "/search?q=exam", true);
    assert.strictEqual(
      this.history.previousURL,
      null,
      "replacing the initial query creates no predecessor"
    );
    visit(this.history, this.browser, "topic", "/t/exam/123/1");
    move(this.browser, "reading", "/t/exam/123/40");
    this.history.capture();
    visit(this.history, this.browser, "profile", "/u/student");
    assert.strictEqual(
      this.history.previousURL,
      "/t/exam/123/40",
      "the latest reading position becomes the return URL"
    );
    move(this.browser, "reading", "/t/exam/123/40");
    this.history.traverse();
    assert.strictEqual(
      this.history.previousURL,
      "/search?q=exam",
      "returning from reading goes directly to the source search"
    );
  });

  test("refresh restores the current browser entry after topic scrolling", function (assert) {
    visit(this.history, this.browser, "topic", "/t/campus/123/1");
    move(this.browser, "reading", "/t/campus/123/40");
    this.history.capture();
    const restored = new BackNavigationHistory(this.storage, this.browser);
    assert.strictEqual(
      restored.previousURL,
      "/search?q=campus&order=latest#results",
      "a refresh retains the source of the replaced reading entry"
    );
  });

  test("a new tab or unrecorded entry starts a new return boundary", function (assert) {
    visit(this.history, this.browser, "topic", "/t/campus/123/1");
    move(this.browser, "new-tab", "/t/campus/123/1");
    const freshTab = new BackNavigationHistory(this.storage, this.browser);
    assert.strictEqual(
      freshTab.previousURL,
      null,
      "copied session storage does not supply another tab's predecessor"
    );
    move(this.browser, "unrecorded", "/about");
    freshTab.traverse();
    assert.strictEqual(
      freshTab.previousURL,
      null,
      "an unknown browser entry cannot lead outside the recorded history"
    );
  });

  test("unavailable storage keeps navigation usable within the page lifetime", function (assert) {
    const unavailable = {
      getObject() {
        throw new Error("Storage unavailable");
      },
      setObject() {
        throw new Error("Storage unavailable");
      },
    };
    const history = new BackNavigationHistory(unavailable, this.browser);
    visit(history, this.browser, "topic", "/t/campus/123/1");
    assert.strictEqual(
      history.previousURL,
      "/search?q=campus&order=latest#results",
      "blocked persistence does not break current-tab navigation"
    );
  });
});
