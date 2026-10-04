import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { and } from "discourse/truth-helpers";
import DCopyButton from "discourse/ui-kit/d-copy-button";
import { i18n } from "discourse-i18n";

export default class AcademyStudentInviteForm extends Component {
  @service a11y;
  @service currentUser;
  @service siteSettings;

  @tracked invitation;

  data = {
    student_number: "",
    expires_after_days: this.siteSettings.invite_expiry_days,
  };

  @action
  async createInvite(data) {
    try {
      this.invitation = await ajax("/academy-roles/admin/student-invites", {
        type: "POST",
        data: {
          student_number: data.student_number,
          expires_at: moment()
            .add(data.expires_after_days, "days")
            .toISOString(),
        },
      });
      this.a11y.announce(i18n("academy_roles.student_invites.created"));
      this.args.onCreated?.(this.invitation);
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    {{#if (and this.currentUser.admin this.siteSettings.academy_roles_enabled)}}
      <div class="academy-student-invite-form" ...attributes>
        {{#if this.invitation}}
          <p>{{i18n "academy_roles.student_invites.created"}}</p>
          <dl>
            <dt>{{i18n "academy_roles.student_number"}}</dt>
            <dd>{{this.invitation.student_number}}</dd>
            <dt>{{i18n "academy_roles.invite_code"}}</dt>
            <dd><code>{{this.invitation.invite_key}}</code></dd>
          </dl>
          <DCopyButton
            @translatedLabel={{i18n "academy_roles.copy_code"}}
            @translatedLabelAfterCopy={{i18n
              "academy_roles.student_invites.copied"
            }}
            @value={{this.invitation.invite_key}}
          />
          <DCopyButton
            @copyClass="btn-default"
            @translatedLabel={{i18n "user.invited.invite.copy_link"}}
            @translatedLabelAfterCopy={{i18n
              "academy_roles.student_invites.copied"
            }}
            @value={{this.invitation.link}}
          />
        {{else}}
          <Form @data={{this.data}} @onSubmit={{this.createInvite}} as |form|>
            <form.Field
              @name="student_number"
              @title={{i18n "academy_roles.student_number"}}
              @type="input"
              @validation="required:trim|length:1,64"
              as |field|
            >
              <field.Control autocomplete="off" maxlength="64" />
            </form.Field>
            <form.Field
              @name="expires_after_days"
              @title={{i18n "academy_roles.student_invites.expiry_days"}}
              @type="input-number"
              @validation="required|integer"
              as |field|
            >
              <field.Control max="36500" min="1" />
            </form.Field>
            <form.Submit @label="academy_roles.student_invites.create" />
          </Form>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
