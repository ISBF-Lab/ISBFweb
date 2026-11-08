import Component from "@glimmer/component";
import { concat, fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeTemplate from "ember-route-template";
import { gt } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

class IsbfGuidesAdminIndex extends Component {
  @service router;

  get previousPage() {
    return Math.max(1, this.args.model.page - 1);
  }

  get nextPage() {
    return this.args.model.page + 1;
  }

  @action
  async changePage(page) {
    await this.router.transitionTo({ queryParams: { page } });
  }

  <template>
    <div class="admin-config-page__main-area isbf-guides-admin">
      <DPageSubheader
        @descriptionLabel={{i18n "isbf_guides.admin.description"}}
        @titleLabel={{i18n "isbf_guides.admin.title"}}
      />
      <a
        class="btn btn-primary"
        href="/admin/plugins/isbf-guides/guides/new"
      >{{i18n "isbf_guides.admin.new"}}</a>
      <ul class="isbf-guides-admin__list">
        {{#each @model.guides key="id" as |guide|}}
          <li class="isbf-guides-admin__entry">
            <a
              href={{concat "/admin/plugins/isbf-guides/guides/" guide.id}}
            >{{guide.draft.title}}</a>
            <span>{{i18n
                (if
                  guide.published
                  "isbf_guides.admin.published"
                  "isbf_guides.admin.draft"
                )
              }}</span>
            {{#if guide.has_changes}}<span>{{i18n
                  "isbf_guides.admin.pending_changes"
                }}</span>{{/if}}
          </li>
        {{else}}
          <li>{{i18n "isbf_guides.admin.empty"}}</li>
        {{/each}}
      </ul>
      <div class="isbf-guides-admin__pagination">
        {{#if (gt @model.page 1)}}<DButton
            @action={{fn this.changePage this.previousPage}}
            @label="isbf_guides.admin.previous"
          />{{/if}}
        {{#if @model.has_more}}<DButton
            @action={{fn this.changePage this.nextPage}}
            @label="isbf_guides.admin.next"
          />{{/if}}
      </div>
    </div>
  </template>
}

export default routeTemplate(IsbfGuidesAdminIndex);
