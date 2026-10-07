import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { array, concat, fn } from "@ember/helper";
import { action } from "@ember/object";
import { trackedObject } from "@ember/reactive/collections";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import AdminConfigAreaEmptyList from "discourse/admin/components/admin-config-area-empty-list";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { longDate } from "discourse/lib/formatter";
import { eq, notEq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DCopyButton from "discourse/ui-kit/d-copy-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

export default class AcademyStudentInvites extends Component {
  @service currentUser;
  @service dialog;

  @tracked busy = false;

  @cached
  get state() {
    return trackedObject({
      records: this.args.model.student_invites,
      hasMore: this.args.model.has_more,
      page: 0,
    });
  }

  @action
  async loadMore() {
    this.busy = true;
    try {
      const result = await ajax("/academy-roles/admin/student-invites", {
        data: { page: this.state.page + 1 },
      });
      this.state.records = [...this.state.records, ...result.student_invites];
      this.state.hasMore = result.has_more;
      this.state.page++;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
    }
  }

  @action
  async reissue(record) {
    this.dialog.confirm({
      message: i18n("academy_roles.student_invites.confirm_reissue"),
      didConfirm: async () => {
        this.busy = true;
        try {
          const updated = await ajax(
            `/academy-roles/admin/student-invites/${record.id}/reissue`,
            {
              type: "POST",
            }
          );
          this.state.records = this.state.records.map((item) =>
            item.id === record.id ? updated : item
          );
        } catch (error) {
          popupAjaxError(error);
        } finally {
          this.busy = false;
        }
      },
    });
  }

  @action
  async revoke(record) {
    this.dialog.confirm({
      message: i18n("academy_roles.student_invites.confirm_revoke"),
      didConfirm: async () => {
        this.busy = true;
        try {
          await ajax(`/academy-roles/admin/student-invites/${record.id}`, {
            type: "DELETE",
          });
          this.state.records = this.state.records.map((item) =>
            item.id === record.id
              ? { ...item, status: "revoked", invite_key: null, link: null }
              : item
          );
        } catch (error) {
          popupAjaxError(error);
        } finally {
          this.busy = false;
        }
      },
    });
  }

  <template>
    {{#if this.currentUser.admin}}
      <div
        class="admin-config-page__main-area academy-student-invites"
        ...attributes
      >
        <DPageSubheader
          @descriptionLabel={{i18n "academy_roles.student_invites.description"}}
          @titleLabel={{i18n "academy_roles.student_invites.title"}}
        >
          <:actions as |actions|>
            <actions.Primary
              @label="academy_roles.student_invites.create"
              @route="adminPlugins.show.academy-student-invites.new"
            />
            <actions.Default
              @label="academy_roles.student_invites.bulk.title"
              @route="adminPlugins.show.academy-student-invites.bulk"
            />
          </:actions>
        </DPageSubheader>
        {{#if this.state.records.length}}
          <table class="d-table">
            <thead class="d-table__header">
              <tr class="d-table__row">
                <th>{{i18n "academy_roles.student_number"}}</th>
                <th>{{i18n "academy_roles.student_invites.status"}}</th>
                <th>{{i18n "academy_roles.student_invites.expires_at"}}</th>
                <th>{{i18n "academy_roles.student_invites.account"}}</th>
                <th>{{i18n "academy_roles.invite_code"}}</th>
                <th>{{i18n "academy_roles.student_invites.actions"}}</th>
              </tr>
            </thead>
            <tbody class="d-table__body">
              {{#each this.state.records as |record|}}
                <tr class="d-table__row">
                  <td
                    class="d-table__cell --overview"
                  >{{record.student_number}}</td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n
                        "academy_roles.student_invites.status"
                      }}</div>
                    {{i18n
                      (concat
                        "academy_roles.student_invites.states." record.status
                      )
                    }}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n
                        "academy_roles.student_invites.expires_at"
                      }}</div>
                    {{#if record.expires_at}}
                      {{longDate record.expires_at}}
                    {{/if}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n
                        "academy_roles.student_invites.account"
                      }}</div>
                    {{#if record.user}}
                      <LinkTo
                        @models={{array record.user.id record.user.username}}
                        @route="adminUser"
                      >{{record.user.username}}</LinkTo>
                    {{else}}
                      {{i18n "academy_roles.student_invites.no_account"}}
                    {{/if}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n
                        "academy_roles.invite_code"
                      }}</div>
                    {{#if (eq record.status "pending")}}
                      <code>{{record.invite_key}}</code>
                      <DCopyButton
                        @copyClass="btn-default btn-small"
                        @translatedLabel={{i18n "academy_roles.copy_code"}}
                        @translatedLabelAfterCopy={{i18n
                          "academy_roles.student_invites.copied"
                        }}
                        @value={{record.invite_key}}
                      />
                      <DCopyButton
                        @copyClass="btn-default btn-small"
                        @translatedLabel={{i18n
                          "user.invited.invite.copy_link"
                        }}
                        @translatedLabelAfterCopy={{i18n
                          "academy_roles.student_invites.copied"
                        }}
                        @value={{record.link}}
                      />
                    {{/if}}
                  </td>
                  <td class="d-table__cell --controls">
                    {{#if (notEq record.status "registered")}}
                      <div class="d-table__cell-actions">
                        <DButton
                          class="btn-default btn-small"
                          @action={{fn this.reissue record}}
                          @disabled={{this.busy}}
                          @label="academy_roles.student_invites.reissue"
                        />
                        {{#if (eq record.status "pending")}}
                          <DButton
                            class="btn-danger btn-small"
                            @action={{fn this.revoke record}}
                            @disabled={{this.busy}}
                            @label="academy_roles.student_invites.revoke"
                          />
                        {{/if}}
                      </div>
                    {{/if}}
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
          {{#if this.state.hasMore}}
            <DButton
              @action={{this.loadMore}}
              @disabled={{this.busy}}
              @label="academy_roles.student_invites.load_more"
            />
          {{/if}}
        {{else}}
          <AdminConfigAreaEmptyList
            @ctaLabel="academy_roles.student_invites.create"
            @ctaRoute="adminPlugins.show.academy-student-invites.new"
            @emptyLabel="academy_roles.student_invites.empty"
          />
        {{/if}}
      </div>
    {{/if}}
  </template>
}
