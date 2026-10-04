import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeTemplate from "ember-route-template";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

class AccountSwitchAdmin extends Component {
  @service dialog;

  @tracked busyId;
  @tracked refreshedModel;

  get model() {
    return this.refreshedModel || this.args.model;
  }

  get links() {
    return this.model.links || [];
  }

  @action
  async update(link, operation) {
    this.busyId = link.id;
    try {
      await ajax(`/isbf/account-switch/admin/links/${link.id}/${operation}`, {
        type: "PUT",
      });
      this.refreshedModel = await ajax("/isbf/account-switch/admin/links");
    } catch (error) {
      await this.dialog.alert(
        error?.jqXHR?.responseJSON?.errors?.[0] || i18n("generic_error")
      );
    } finally {
      this.busyId = null;
    }
  }

  <template>
    <section class="isbf-account-switch-admin">
      <h2>{{i18n "isbf_account_switch.admin.title"}}</h2>
      <p>{{i18n "isbf_account_switch.admin.description"}}</p>

      <table class="table">
        <thead>
          <tr>
            <th>{{i18n "isbf_account_switch.admin.accounts"}}</th>
            <th>{{i18n "isbf_account_switch.admin.requester"}}</th>
            <th>{{i18n "isbf_account_switch.admin.status"}}</th>
            <th>{{i18n "isbf_account_switch.admin.actions"}}</th>
          </tr>
        </thead>
        <tbody>
          {{#each this.links as |link|}}
            <tr>
              <td>@{{link.user_a.username}} ↔ @{{link.user_b.username}}</td>
              <td>@{{link.requester}}</td>
              <td>{{link.status}}</td>
              <td>
                {{#if (eq link.status "pending_admin")}}
                  <DButton
                    @action={{fn this.update link "approve"}}
                    @disabled={{eq this.busyId link.id}}
                    @label="isbf_account_switch.admin.approve"
                  />
                  <DButton
                    @action={{fn this.update link "reject"}}
                    @disabled={{eq this.busyId link.id}}
                    @label="isbf_account_switch.admin.reject"
                  />
                {{else if (eq link.status "pending_target")}}
                  <DButton
                    @action={{fn this.update link "reject"}}
                    @disabled={{eq this.busyId link.id}}
                    @label="isbf_account_switch.admin.reject"
                  />
                {{else if (eq link.status "approved")}}
                  <DButton
                    @action={{fn this.update link "revoke"}}
                    @disabled={{eq this.busyId link.id}}
                    @label="isbf_account_switch.admin.revoke"
                  />
                {{/if}}
              </td>
            </tr>
          {{else}}
            <tr>
              <td colspan="4">{{i18n "isbf_account_switch.admin.empty"}}</td>
            </tr>
          {{/each}}
        </tbody>
      </table>

      <h3>{{i18n "isbf_account_switch.admin.audit"}}</h3>
      <table class="table">
        <thead>
          <tr>
            <th>{{i18n "isbf_account_switch.admin.time"}}</th>
            <th>{{i18n "isbf_account_switch.admin.actor"}}</th>
            <th>{{i18n "isbf_account_switch.admin.event"}}</th>
            <th>{{i18n "isbf_account_switch.admin.link"}}</th>
          </tr>
        </thead>
        <tbody>
          {{#each this.model.audit_events as |event|}}
            <tr>
              <td>{{event.created_at}}</td>
              <td>{{event.actor}}</td>
              <td>{{event.action}}</td>
              <td>{{event.account_link_id}}</td>
            </tr>
          {{/each}}
        </tbody>
      </table>
    </section>
  </template>
}

export default routeTemplate(AccountSwitchAdmin);
