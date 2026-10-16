import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

const application = {
  id: 1,
  name: "申请人",
  student_id: "2026101401",
  phone: "+86 138-0013-8000",
  created_at: "2026-10-14T01:00:00.000Z",
};

function configure(needs) {
  needs.user({ admin: true });
  needs.pretender((server, helper) => {
    const plugin = {
      id: "isbf-join",
      name: "isbf-join",
      humanized_name: "Join us",
      enabled: true,
      admin_route: {
        location: "isbf-join",
        label: "isbf_join.admin.title",
        full_location: "adminPlugins.show",
        use_new_show_route: true,
      },
    };
    server.get("/admin/plugins", () => helper.response({ plugins: [plugin] }));
    server.get("/admin/plugins/isbf-join.json", () => helper.response(plugin));
    server.get("/isbf/join/admin/applications.json", () =>
      helper.response({ applications: [application], page: 1, has_more: false })
    );
  });
}

acceptance("ISBF join | Admin applications", function (needs) {
  configure(needs);

  test("renders contact fields and escapes submitted text", async function (assert) {
    const name = "<img src=x onerror=alert(1)>";
    pretender.get("/isbf/join/admin/applications.json", () =>
      response({
        applications: [{ ...application, name }],
        page: 1,
        has_more: false,
      })
    );

    await visit("/admin/plugins/isbf-join/applications");

    assert
      .dom(".isbf-join-applications tbody .--overview")
      .hasText(name, "the name is rendered as text");
    assert
      .dom(".isbf-join-applications tbody img")
      .doesNotExist("submitted markup cannot create elements");
    assert
      .dom(".isbf-join-applications tbody")
      .includesText(application.student_id, "the student ID is shown");
    assert
      .dom(".isbf-join-applications tbody")
      .includesText(application.phone, "the phone is shown");
    assert
      .dom(".isbf-join-applications time")
      .hasAttribute(
        "datetime",
        application.created_at,
        "the submission time is preserved"
      );
    assert
      .dom(".isbf-join-applications__pagination")
      .doesNotExist("one page needs no pagination");
  });

  test("fetches next and previous pages and updates disabled controls", async function (assert) {
    const requestedPages = [];
    pretender.get("/isbf/join/admin/applications.json", (request) => {
      const page = Number(request.queryParams.page || 1);
      requestedPages.push(page);
      return response({
        applications: [
          { ...application, id: page, name: `Page ${page} applicant` },
        ],
        page,
        has_more: page === 1,
      });
    });

    await visit("/admin/plugins/isbf-join/applications");
    assert
      .dom(".isbf-join-applications__previous")
      .isDisabled("the first page has no predecessor");
    await click(".isbf-join-applications__next");
    assert
      .dom(".isbf-join-applications .--overview")
      .hasText("Page 2 applicant", "the next page replaces the records");
    assert
      .dom(".isbf-join-applications__next")
      .isDisabled("the final page has no successor");
    await click(".isbf-join-applications__previous");
    assert
      .dom(".isbf-join-applications .--overview")
      .hasText("Page 1 applicant", "previous returns to page one");
    assert.deepEqual(
      requestedPages,
      [1, 2, 1],
      "pagination fetches the requested page each time"
    );
  });

  test("retries a failed load and shows the empty result", async function (assert) {
    let failed = true;
    pretender.get("/isbf/join/admin/applications.json", () =>
      response(
        failed ? 503 : 200,
        failed ? {} : { applications: [], page: 1, has_more: false }
      )
    );

    await visit("/admin/plugins/isbf-join/applications");
    assert
      .dom(".isbf-join-applications [role=alert]")
      .hasText(
        i18n("isbf_join.admin.load_error"),
        "a failed request has a visible error"
      );
    assert
      .dom(".isbf-join-applications__pagination")
      .doesNotExist("failed results have no paging controls");
    failed = false;
    await click(".isbf-join-applications__retry");
    assert
      .dom(".isbf-join-applications [role=alert]")
      .doesNotExist("a successful retry clears the error");
    assert
      .dom(".isbf-join-applications__empty")
      .hasText(
        i18n("isbf_join.admin.empty"),
        "an empty response has its own message"
      );
  });
});

acceptance("ISBF join | Admin applications | Mobile", function (needs) {
  configure(needs);
  needs.mobileView();

  test("keeps a label beside every detail cell on small screens", async function (assert) {
    await visit("/admin/plugins/isbf-join/applications");

    assert
      .dom(".isbf-join-applications tbody .--overview")
      .hasText(application.name, "the applicant remains the row overview");
    assert
      .dom(".isbf-join-applications .d-table__mobile-label")
      .exists({ count: 3 }, "all detail fields retain mobile labels");
    for (const [index, key] of [
      "student_id",
      "phone",
      "created_at",
    ].entries()) {
      assert
        .dom(
          `.isbf-join-applications td:nth-child(${index + 2}) .d-table__mobile-label`
        )
        .hasText(
          i18n(`isbf_join.admin.${key}`),
          `the ${key} field remains identifiable`
        );
    }
  });
});
