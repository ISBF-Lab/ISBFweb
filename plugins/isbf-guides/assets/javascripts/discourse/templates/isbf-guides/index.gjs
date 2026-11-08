import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import routeTemplate from "ember-route-template";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

class IsbfGuidesIndex extends Component {
  @tracked pagination;
  @tracked loading = false;

  get guides() {
    return this.pagination?.base === this.args.model
      ? this.pagination.guides
      : this.args.model.guides;
  }

  get page() {
    return this.pagination?.base === this.args.model
      ? this.pagination.page
      : this.args.model.page;
  }

  get hasMore() {
    return this.pagination?.base === this.args.model
      ? this.pagination.hasMore
      : this.args.model.has_more;
  }

  @action
  async loadMore() {
    this.loading = true;
    try {
      const response = await ajax("/guides.json", {
        data: { page: this.page + 1 },
      });
      this.pagination = {
        base: this.args.model,
        guides: [...this.guides, ...response.guides],
        page: response.page,
        hasMore: response.has_more,
      };
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  <template>
    <main class="isbf-guides isbf-v2-feature">
      <header class="isbf-guides__heading">
        <h1>{{i18n "isbf_guides.title"}}</h1>
        <p class="isbf-guides__intro">{{i18n "isbf_guides.intro"}}</p>
      </header>
      <div class="isbf-guides__list">
        {{#each this.guides key="id" as |guide|}}
          <a class="isbf-guides__entry" href={{guide.url}}>
            <div class="isbf-guides__entry-content">
              <h2>{{guide.title}}</h2>
              <p>{{guide.summary}}</p>
              <span class="isbf-guides__updated">{{i18n "isbf_guides.updated"}}
                <time datetime={{guide.updated_at}}>{{dFormatDate
                    guide.updated_at
                  }}</time></span>
            </div>
            {{dIcon "chevron-right"}}
          </a>
        {{else}}
          <p class="isbf-guides__empty">{{i18n "isbf_guides.empty"}}</p>
        {{/each}}
      </div>
      {{#if this.hasMore}}
        <DButton
          @action={{this.loadMore}}
          @isLoading={{this.loading}}
          @label="isbf_guides.more"
        />
      {{/if}}
    </main>
  </template>
}

export default routeTemplate(IsbfGuidesIndex);
