import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import getURL from "discourse/lib/get-url";
import { and, not } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class AcademyInviteCode extends Component {
  @service siteSettings;

  @action
  redeem({ code }) {
    const inviteCode = code?.trim();
    if (!inviteCode) {
      return;
    }

    window.location.assign(
      getURL(`/invites/${encodeURIComponent(inviteCode)}`)
    );
  }

  <template>
    {{#if
      (and
        this.siteSettings.academy_roles_enabled
        (not this.siteSettings.academy_auth_page_enabled)
      )
    }}
      <section class="academy-invite-code" ...attributes>
        <h2>{{i18n "academy_roles.invite_title"}}</h2>
        <Form @onSubmit={{this.redeem}} as |form|>
          <form.Field
            @name="code"
            @title={{i18n "academy_roles.invite_code"}}
            @type="input"
            @validation="required"
            as |field|
          >
            <field.Control autocomplete="off" />
          </form.Field>
          <form.Submit @label="academy_roles.redeem" />
        </Form>
      </section>
    {{/if}}
  </template>
}
