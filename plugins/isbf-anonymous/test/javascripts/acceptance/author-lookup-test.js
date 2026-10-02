import { click, currentURL, find, visit, waitUntil } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import topicFixtures from "discourse/tests/fixtures/topic";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

const authors = {
  62: {
    id: 1,
    username: "eviltrout",
    name: "Robin Ward",
    avatar_template: "/letter_avatar_proxy/v4/letter/e/aeaffb/{size}.png",
  },
  63: {
    id: 2,
    username: "sam",
    avatar_template: "/letter_avatar_proxy/v4/letter/s/aeaffb/{size}.png",
  },
};

function anonymousTopic() {
  const topic = cloneJSON(topicFixtures["/t/280/1.json"]);
  topic.id = 40;
  topic.slug = "topic";
  topic.posts_count = 3;
  topic.highest_post_number = 3;
  topic.post_stream.posts = topic.post_stream.posts.slice(0, 3);
  topic.post_stream.posts.forEach((post, index) => {
    post.id = 62 + index;
    post.post_number = index + 1;
    post.topic_id = 40;
    post.topic_slug = "topic";
    post.user_id = 77;
    post.username = "anon_pool_0001";
    post.name = null;
    post.custom_fields = { isbf_per_post_anonymous: index < 2 };
  });
  topic.post_stream.stream = topic.post_stream.posts.map((post) => post.id);
  return topic;
}

function lookupRequests() {
  return pretender.handledRequests.filter((request) =>
    request.url.startsWith("/isbf-anonymous/api/posts/")
  );
}

async function openPostAdminMenu(postNumber) {
  const postSelector = `.topic-post[data-post-number='${postNumber}']`;
  await click(`${postSelector} .show-more-actions`);
  await click(`${postSelector} .show-post-admin-menu`);
}

acceptance("ISBF anonymous author lookup", function (needs) {
  needs.user({ admin: true });

  needs.pretender((server, helper) => {
    server.get("/t/40.json", () => helper.response(anonymousTopic()));
    server.get("/t/40/1.json", () => helper.response(anonymousTopic()));
    server.get("/isbf-anonymous/api/posts/:id/author.json", (request) =>
      helper.response({ author: authors[request.params.id] })
    );
  });

  test("queries the post on demand and links to the real account", async function (assert) {
    await visit("/t/topic/40");
    await openPostAdminMenu(1);

    assert
      .dom(".isbf-anonymous-author-lookup")
      .hasText(
        i18n("isbf_anonymous.author_lookup.button"),
        "the menu has a named lookup entry"
      );
    assert.strictEqual(
      lookupRequests().length,
      0,
      "opening the menu does not fetch private data"
    );

    await click(".isbf-anonymous-author-lookup");

    assert.strictEqual(
      lookupRequests()[0].url,
      "/isbf-anonymous/api/posts/62/author.json",
      "the request uses post 62 rather than topic 40"
    );
    assert
      .dom(".isbf-anonymous-author__username")
      .hasText(authors[62].username, "the real username is shown");
    assert
      .dom(".isbf-anonymous-author__details")
      .includesText(authors[62].name, "the real name is shown");
    assert
      .dom(".isbf-anonymous-author__user-id")
      .hasText("1", "the real user ID is shown");
    assert
      .dom(".isbf-anonymous-author__manage")
      .hasAttribute(
        "href",
        "/admin/users/1/eviltrout",
        "management targets the real account"
      );

    await click(".isbf-anonymous-author__manage");

    assert.strictEqual(
      currentURL(),
      "/admin/users/1/eviltrout",
      "the link opens the existing admin user page"
    );
    assert
      .dom(".isbf-anonymous-author")
      .doesNotExist("navigation closes the private dialog");
  });

  test("queries each post separately when the public author is shared", async function (assert) {
    await visit("/t/topic/40");
    await openPostAdminMenu(1);
    await click(".isbf-anonymous-author-lookup");
    await click(".isbf-anonymous-author .modal-close");
    await openPostAdminMenu(2);
    await click(".isbf-anonymous-author-lookup");

    assert
      .dom(".isbf-anonymous-author__username")
      .hasText(authors[63].username, "the second post has its own real author");
    assert
      .dom(".isbf-anonymous-author__details")
      .doesNotIncludeText(
        authors[62].name,
        "the closed dialog's identity is discarded"
      );
    assert.deepEqual(
      lookupRequests().map((request) => request.url),
      [
        "/isbf-anonymous/api/posts/62/author.json",
        "/isbf-anonymous/api/posts/63/author.json",
      ],
      "shared public authors do not share lookup results"
    );
  });

  test("ordinary posts have no lookup entry", async function (assert) {
    await visit("/t/topic/40");
    await openPostAdminMenu(3);

    assert
      .dom(".isbf-anonymous-author-lookup")
      .doesNotExist("only marked anonymous posts offer lookup");
    assert.strictEqual(
      lookupRequests().length,
      0,
      "ordinary posts do not request an author"
    );
  });

  [
    { status: 403, key: "forbidden" },
    { status: 404, key: "unavailable" },
  ].forEach(({ status, key }) => {
    test(`handles author lookup ${status}`, async function (assert) {
      await visit("/t/topic/40");
      pretender.get("/isbf-anonymous/api/posts/62/author.json", () =>
        response(status, { errors: ["Lookup unavailable"] })
      );
      await openPostAdminMenu(1);
      await click(".isbf-anonymous-author-lookup");

      assert
        .dom(".isbf-anonymous-author__error")
        .hasText(
          i18n(`isbf_anonymous.author_lookup.${key}`),
          "the dialog explains the failure"
        );
      assert
        .dom(".isbf-anonymous-author__manage")
        .doesNotExist("failed lookups offer no account link");
      assert
        .dom(".isbf-anonymous-author__retry")
        .doesNotExist("permission and missing-author failures are final");
    });
  });

  test("retries a failed request", async function (assert) {
    await visit("/t/topic/40");
    let attempts = 0;
    pretender.get("/isbf-anonymous/api/posts/62/author.json", () => {
      attempts++;
      return attempts === 1
        ? response(503, { errors: ["Temporarily unavailable"] })
        : response({ author: authors[62] });
    });
    await openPostAdminMenu(1);
    await click(".isbf-anonymous-author-lookup");

    assert
      .dom(".isbf-anonymous-author__error")
      .hasText(
        i18n("isbf_anonymous.author_lookup.failed"),
        "temporary errors explain the retry"
      );
    await click(".isbf-anonymous-author__retry");

    assert.strictEqual(attempts, 2, "retry performs a new request");
    assert
      .dom(".isbf-anonymous-author__username")
      .hasText(authors[62].username, "retry displays the author");
  });

  test("a late response leaves a closed dialog closed", async function (assert) {
    await visit("/t/topic/40");
    let pendingRequest;
    pretender.get(
      "/isbf-anonymous/api/posts/62/author.json",
      (request) => {
        pendingRequest = request;
        return response({ author: authors[62] });
      },
      true
    );
    await openPostAdminMenu(1);
    const opening = click(".isbf-anonymous-author-lookup");
    await waitUntil(
      () => pendingRequest && find(".isbf-anonymous-author .modal-close")
    );
    assert
      .dom(".isbf-anonymous-author .spinner")
      .exists("the pending request shows a loading state");

    const closing = click(".isbf-anonymous-author .modal-close");
    await waitUntil(() => !find(".isbf-anonymous-author"));
    pretender.resolve(pendingRequest);
    await Promise.all([opening, closing]);

    assert
      .dom(".isbf-anonymous-author")
      .doesNotExist("the late response cannot reopen the dialog");
    assert
      .dom(".isbf-anonymous-author__username")
      .doesNotExist("the discarded result is not rendered");
  });
});

[
  { name: "guests" },
  { name: "members", user: { admin: false, moderator: false } },
  { name: "moderators", user: { admin: false, moderator: true } },
].forEach(({ name, user }) => {
  acceptance(`ISBF anonymous author privacy for ${name}`, function (needs) {
    if (user) {
      needs.user(user);
    }
    needs.pretender((server, helper) => {
      server.get("/t/40.json", () => helper.response(anonymousTopic()));
      server.get("/t/40/1.json", () => helper.response(anonymousTopic()));
    });

    test("hides author lookup", async function (assert) {
      await visit("/t/topic/40");
      if (find("#post_1 .show-more-actions")) {
        await click("#post_1 .show-more-actions");
      }
      if (find("#post_1 .show-post-admin-menu")) {
        await click("#post_1 .show-post-admin-menu");
      }

      assert
        .dom(".isbf-anonymous-author-lookup")
        .doesNotExist("real-author lookup is restricted to administrators");
      assert.strictEqual(
        lookupRequests().length,
        0,
        "private authors are not prefetched"
      );
    });
  });
});
