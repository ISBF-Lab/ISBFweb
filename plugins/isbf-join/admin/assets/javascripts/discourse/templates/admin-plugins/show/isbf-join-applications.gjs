import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeTemplate from "ember-route-template";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";

class IsbfJoinApplications extends Component {
  @service router;

  @tracked loading = false;

  get hasPrevious() {
    return this.args.model.page > 1;
  }

  get nextPage() {
    return this.args.model.page + 1;
  }

  get previousPage() {
    return this.args.model.page - 1;
  }

  @action
  async changePage(page) {
    this.loading = true;
    try {
      await this.router.transitionTo({ queryParams: { page } });
    } finally {
      this.loading = false;
    }
  }

  @action
  async retry() {
    this.loading = true;
    try {
      await this.router.refresh();
    } finally {
      this.loading = false;
    }
  }

  <template>
    <div class="admin-config-page__main-area isbf-join-applications">
      <DPageSubheader
        @descriptionLabel={{i18n "isbf_join.admin.description"}}
        @titleLabel={{i18n "isbf_join.admin.applications"}}
      />

      <DConditionalLoadingSpinner @condition={{this.loading}} />

      {{#if @model.load_error}}
        <p role="alert">{{i18n "isbf_join.admin.load_error"}}</p>
        <DButton
          class="btn-default isbf-join-applications__retry"
          @action={{this.retry}}
          @disabled={{this.loading}}
          @label="isbf_join.admin.retry"
        />
      {{else if @model.applications.length}}
        <table class="d-table">
          <thead class="d-table__header">
            <tr class="d-table__row">
              <th class="d-table__header-cell" scope="col">{{i18n
                  "isbf_join.admin.name"
                }}</th>
              <th class="d-table__header-cell" scope="col">{{i18n
                  "isbf_join.admin.student_id"
                }}</th>
              <th class="d-table__header-cell" scope="col">{{i18n
                  "isbf_join.admin.phone"
                }}</th>
              <th class="d-table__header-cell" scope="col">{{i18n
                  "isbf_join.admin.created_at"
                }}</th>
            </tr>
          </thead>
          <tbody class="d-table__body">
            {{#each @model.applications key="id" as |application|}}
              <tr class="d-table__row">
                <td class="d-table__cell --overview">
                  {{application.name}}
                </td>
                <td class="d-table__cell --detail">
                  <div class="d-table__mobile-label">{{i18n
                      "isbf_join.admin.student_id"
                    }}</div>
                  {{application.student_id}}
                </td>
                <td class="d-table__cell --detail">
                  <div class="d-table__mobile-label">{{i18n
                      "isbf_join.admin.phone"
                    }}</div>
                  {{application.phone}}
                </td>
                <td class="d-table__cell --detail">
                  <div class="d-table__mobile-label">{{i18n
                      "isbf_join.admin.created_at"
                    }}</div>
                  <time datetime={{application.created_at}}>
                    {{dFormatDate application.created_at}}
                  </time>
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        <p class="isbf-join-applications__empty">{{i18n
            "isbf_join.admin.empty"
          }}</p>
      {{/if}}

      {{#unless @model.load_error}}
        {{#if (or this.hasPrevious @model.has_more)}}
          <nav
            aria-label={{i18n "isbf_join.admin.pagination"}}
            class="isbf-join-applications__pagination"
          >
            <DButton
              class="btn-default isbf-join-applications__previous"
              @action={{fn this.changePage this.previousPage}}
              @disabled={{or this.loading (not this.hasPrevious)}}
              @label="isbf_join.admin.previous"
            />
            <span>{{i18n "isbf_join.admin.page" page=@model.page}}</span>
            <DButton
              class="btn-default isbf-join-applications__next"
              @action={{fn this.changePage this.nextPage}}
              @disabled={{or this.loading (not @model.has_more)}}
              @label="isbf_join.admin.next"
            />
          </nav>
        {{/if}}
      {{/unless}}
    </div>
  </template>
}

export default routeTemplate(IsbfJoinApplications);
