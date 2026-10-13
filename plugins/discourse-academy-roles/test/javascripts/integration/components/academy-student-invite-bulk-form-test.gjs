import { clearRender, click, render, triggerEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { i18n } from "discourse-i18n";
import AcademyStudentInviteBulkForm from "discourse/plugins/discourse-academy-roles/discourse/components/academy-student-invite-bulk-form";

module(
  "Integration | Component | AcademyStudentInviteBulkForm",
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      this.currentUser.set("admin", true);
      this.siteSettings.academy_roles_enabled = true;
      this.siteSettings.invite_expiry_days = 30;
      this.downloads = [];
      sinon.stub(URL, "createObjectURL").callsFake((blob) => {
        this.downloads.push(blob);
        return "blob:student-invitations";
      });
      sinon.stub(HTMLAnchorElement.prototype, "click");
    });

    test("uploads the CSV and downloads the result again without generating more invitations", async function (assert) {
      const file = new File(["student_number\n000123\n"], "students.csv", {
        type: "text/csv",
      });
      const result = {
        created_count: 1,
        skipped_count: 2,
        failed_count: 1,
        csv: '\uFEFF"学号","邀请码"\r\n"000123","new-code"\r\n',
      };
      let requests = 0;

      pretender.post("/academy-roles/admin/student-invites/bulk", (request) => {
        requests++;
        assert.strictEqual(
          request.requestBody.get("file").name,
          file.name,
          "the chosen CSV is uploaded as a file"
        );
        assert.true(
          moment(request.requestBody.get("expires_at")).isAfter(moment()),
          "the batch uses a future expiry"
        );
        return response(201, result);
      });

      await render(<template><AcademyStudentInviteBulkForm /></template>);
      await triggerEvent("input[type='file']", "change", { files: [file] });
      await formKit().submit();

      assert.dom(".academy-student-invite-bulk-form__summary").hasText(
        i18n("academy_roles.student_invites.bulk.summary", {
          created: 1,
          skipped: 2,
          failed: 1,
        }),
        "the administrator sees all processing counts"
      );
      assert
        .dom(".academy-student-invite-bulk-form form")
        .doesNotExist("the result replaces the submitted form");
      assert.strictEqual(
        this.downloads.length,
        1,
        "the result downloads automatically"
      );
      assert.strictEqual(
        await this.downloads[0].text(),
        result.csv.replace(/^\uFEFF/, ""),
        "the downloaded file contains the server's CSV"
      );

      await click(".academy-student-invite-bulk-form__download");
      assert.strictEqual(
        this.downloads.length,
        2,
        "the same result can be downloaded again"
      );
      assert.strictEqual(
        requests,
        1,
        "downloading again does not create new invitations"
      );
    });

    test("downloads an importable template with a text student number", async function (assert) {
      await render(<template><AcademyStudentInviteBulkForm /></template>);
      await click(".academy-student-invite-bulk-form > button");

      assert.strictEqual(this.downloads.length, 1, "a template is downloaded");
      assert.strictEqual(
        await this.downloads[0].text(),
        "student_number\r\n001234\r\n",
        "the supported header and leading zeroes are retained"
      );
    });

    test("requires a CSV and rejects oversized or incorrectly named files", async function (assert) {
      await render(<template><AcademyStudentInviteBulkForm /></template>);
      await formKit().submit();

      assert
        .dom("[data-name='file'] .form-kit__errors")
        .exists("a file must be chosen before submitting");

      const invalidFiles = [
        {
          file: new File(["000123"], "students.txt"),
          message: i18n("academy_roles.student_invites.bulk.csv_required"),
        },
        {
          file: new File([new Uint8Array(1024 * 1024 + 1)], "students.csv"),
          message: i18n("academy_roles.student_invites.bulk.too_large"),
        },
      ];

      for (const { file, message } of invalidFiles) {
        await triggerEvent("input[type='file']", "change", { files: [file] });
        await formKit().submit();
        assert
          .dom("[data-name='file'] .form-kit__errors")
          .includesText(message, "the invalid file is explained");
      }

      assert.strictEqual(
        this.downloads.length,
        0,
        "invalid inputs do not produce a result"
      );
    });

    test("hides bulk generation from members, moderators and disabled sites", async function (assert) {
      this.currentUser.set("admin", false);
      await render(<template><AcademyStudentInviteBulkForm /></template>);
      assert
        .dom(".academy-student-invite-bulk-form")
        .doesNotExist("a regular member has no bulk form");

      await clearRender();
      this.currentUser.set("moderator", true);
      await render(<template><AcademyStudentInviteBulkForm /></template>);
      assert
        .dom(".academy-student-invite-bulk-form")
        .doesNotExist("a moderator has no bulk form");

      await clearRender();
      this.currentUser.set("admin", true);
      this.siteSettings.academy_roles_enabled = false;
      await render(<template><AcademyStudentInviteBulkForm /></template>);
      assert
        .dom(".academy-student-invite-bulk-form")
        .doesNotExist("a disabled site has no bulk form");
    });
  }
);
