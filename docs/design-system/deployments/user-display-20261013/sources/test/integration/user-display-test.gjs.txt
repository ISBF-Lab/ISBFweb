import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import PostMetaDataPosterName from "discourse/components/post/meta-data/poster-name";
import MenuItem from "discourse/components/user-menu/menu-item";
import UserMenuNotificationItem from "discourse/lib/user-menu/notification-item";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import userDisplayInitializer from "../../discourse/api-initializers/isbf-user-display";
import ISBFNotificationEntry from "../../discourse/components/isbf-notification-entry";

module("ISBF | Integration | Component | UserDisplay", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  hooks.beforeEach(function () {
    this.router = this.owner.lookup("service:router");
    this.router.currentURL = "/t/synthetic-topic/990001";
    this.siteSettings.enable_names = true;
    this.siteSettings.prioritize_username_in_ux = true;
    this.siteSettings.prioritize_full_name_in_ux = false;
    this.siteSettings.display_name_on_posts = false;
    userDisplayInitializer.initialize();
    const store = this.owner.lookup("service:store");
    const topic = store.createRecord("topic", {
      id: 990001,
      archetype: "regular",
    });
    this.post = store.createRecord("post", {
      id: 990002,
      post_number: 1,
      post_type: 1,
      topic,
      user_id: 990003,
      username: "student",
      name: "林同学",
      moderator: true,
    });
  });

  test("a regular post displays the name while retaining its profile and role", async function (assert) {
    const post = this.post;
    await render(
      <template><PostMetaDataPosterName @post={{post}} /></template>
    );
    assert
      .dom(".names .first a")
      .hasText(
        "林同学",
        "the account name is primary despite the global username preference"
      );
    assert
      .dom(".names .first")
      .hasClass("full-name", "the native name class stays accurate");
    assert
      .dom(".names .first a")
      .hasAttribute(
        "href",
        "/u/student",
        "the profile URL retains the username"
      );
    assert
      .dom(".d-icon-shield-halved")
      .exists("the moderator indicator remains present");
  });

  test("private messages retain the native name preference", async function (assert) {
    this.post.topic.set("archetype", "private_message");
    const post = this.post;
    await render(
      <template><PostMetaDataPosterName @post={{post}} /></template>
    );
    assert
      .dom(".names .first a")
      .hasText(
        "student",
        "the scoped author change does not affect private messages"
      );
  });

  test("a reply has the same author rule and user-supplied names stay escaped", async function (assert) {
    this.post.setProperties({
      post_number: 2,
      name: '<img src="x" onerror="alert(1)">',
    });
    const post = this.post;
    await render(
      <template><PostMetaDataPosterName @post={{post}} /></template>
    );
    assert
      .dom(".names .first a")
      .hasText(
        '<img src="x" onerror="alert(1)">',
        "a reply displays the literal name"
      );
    assert
      .dom(".names .first img")
      .doesNotExist("a name cannot create HTML elements");
  });

  test("a grouped notification displays the actor's name and username", async function (assert) {
    const entry = {
      action: "mentioned",
      actor: {
        name: "林同学",
        username: "student",
        avatar_template: "/letter_avatar_proxy/v4/letter/s/000000/{size}.png",
      },
      notification: { read: false },
      actionLabel: "mentioned you",
      item: { linkHref: "/t/synthetic-topic/990001", linkTitle: "Mention" },
      created_at: "2026-10-13T00:00:00Z",
    };
    await render(
      <template><ISBFNotificationEntry @entry={{entry}} /></template>
    );
    assert
      .dom(".isbf-notification-entry__name")
      .hasText(
        "林同学 @student",
        "the grouped entry uses the same identity rule"
      );
    assert
      .dom(".isbf-notification-entry__content a")
      .hasAttribute(
        "href",
        entry.item.linkHref,
        "the notification still opens its topic"
      );
  });

  test("the native notification menu displays both identities and keeps its target", async function (assert) {
    const notification = {
      notification_type: this.site.notification_types.mentioned,
      acting_user_name: "林同学",
      data: { display_username: "student", topic_title: "Synthetic topic" },
      topic_id: 990001,
      post_number: 2,
      slug: "synthetic-topic",
      read: true,
    };
    const item = new UserMenuNotificationItem({
      notification,
      currentUser: this.currentUser,
      siteSettings: this.siteSettings,
      site: this.site,
    });
    await render(<template><MenuItem @item={{item}} /></template>);
    assert
      .dom(".item-label")
      .hasText(
        "林同学 @student",
        "the native menu follows the same display rule"
      );
    assert
      .dom("li a")
      .hasAttribute(
        "href",
        "/t/synthetic-topic/990001/2",
        "the post target remains unchanged"
      );
  });

  test("other user-menu items keep their own labels", async function (assert) {
    const item = {
      label: "Synthetic bookmark",
      linkHref: "/my/activity/bookmarks",
      className: "bookmark",
    };
    await render(<template><MenuItem @item={{item}} /></template>);
    assert
      .dom(".item-label")
      .hasText(
        "Synthetic bookmark",
        "non-notification items are not reformatted"
      );
  });
});
