import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { deliverBlobDownload } from "discourse/lib/download-blob";
import { and } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

const MAX_FILE_BYTES = 1024 * 1024;

export default class AcademyStudentInviteBulkForm extends Component {
  @service a11y;
  @service currentUser;
  @service siteSettings;

  @tracked busy = false;
  @tracked result;

  data = {
    file: null,
    expires_after_days: this.siteSettings.invite_expiry_days,
  };

  get summary() {
    return i18n("academy_roles.student_invites.bulk.summary", {
      created: this.result.created_count,
      skipped: this.result.skipped_count,
      failed: this.result.failed_count,
    });
  }

  @action
  selectFile(set, event) {
    set(event.target.files?.[0] ?? null);
  }

  @action
  validateFile(name, value, { addError }) {
    if (!value) {
      return;
    }

    let message;
    if (!/\.csv$/i.test(value.name)) {
      message = i18n("academy_roles.student_invites.bulk.csv_required");
    } else if (value.size > MAX_FILE_BYTES) {
      message = i18n("academy_roles.student_invites.bulk.too_large");
    }

    if (message) {
      addError(name, {
        title: i18n("academy_roles.student_invites.bulk.file"),
        message,
      });
    }
  }

  @action
  async generate(data) {
    if (this.busy) {
      return;
    }

    this.busy = true;
    const formData = new FormData();
    formData.append("file", data.file);
    formData.append(
      "expires_at",
      moment().add(data.expires_after_days, "days").toISOString()
    );

    try {
      this.result = await ajax("/academy-roles/admin/student-invites/bulk", {
        type: "POST",
        processData: false,
        contentType: false,
        data: formData,
      });
      this.a11y.announce(this.summary);
      await this.downloadResult();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
    }
  }

  @action
  async downloadResult() {
    await deliverBlobDownload(
      new Blob([this.result.csv], { type: "text/csv;charset=utf-8" }),
      { fallbackFilename: "student-invitations.csv" }
    );
  }

  @action
  async downloadTemplate() {
    await deliverBlobDownload(
      new Blob(["\uFEFFstudent_number\r\n001234\r\n"], {
        type: "text/csv;charset=utf-8",
      }),
      { fallbackFilename: "student-numbers-template.csv" }
    );
  }

  @action
  reset() {
    this.result = null;
  }

  <template>
    {{#if (and this.currentUser.admin this.siteSettings.academy_roles_enabled)}}
      <div class="academy-student-invite-bulk-form" ...attributes>
        {{#if this.result}}
          <p
            class="academy-student-invite-bulk-form__summary"
          >{{this.summary}}</p>
          <p>{{i18n
              "academy_roles.student_invites.bulk.result_description"
            }}</p>
          <DButton
            class="btn-primary academy-student-invite-bulk-form__download"
            @action={{this.downloadResult}}
            @disabled={{this.busy}}
            @label="academy_roles.student_invites.bulk.download_result"
          />
          <DButton
            @action={{this.reset}}
            @disabled={{this.busy}}
            @label="academy_roles.student_invites.bulk.another_batch"
          />
        {{else}}
          <p>{{i18n "academy_roles.student_invites.bulk.description"}}</p>
          <DButton
            @action={{this.downloadTemplate}}
            @disabled={{this.busy}}
            @label="academy_roles.student_invites.bulk.download_template"
          />
          <Form @data={{this.data}} @onSubmit={{this.generate}} as |form|>
            <form.Field
              @disabled={{this.busy}}
              @name="file"
              @title={{i18n "academy_roles.student_invites.bulk.file"}}
              @type="custom"
              @validate={{this.validateFile}}
              @validation="required"
              as |field|
            >
              <field.Control>
                <input
                  accept=".csv,text/csv"
                  aria-describedby={{field.errorId}}
                  disabled={{this.busy}}
                  id={{field.id}}
                  type="file"
                  {{on "change" (fn this.selectFile field.set)}}
                />
              </field.Control>
            </form.Field>
            <form.Field
              @disabled={{this.busy}}
              @name="expires_after_days"
              @title={{i18n "academy_roles.student_invites.bulk.expiry_days"}}
              @type="input-number"
              @validation="required|integer|between:1,36500"
              as |field|
            >
              <field.Control max="36500" min="1" />
            </form.Field>
            <form.Submit
              @disabled={{this.busy}}
              @label="academy_roles.student_invites.bulk.generate"
            />
          </Form>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
