import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import Composer from "discourse/models/composer";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { marketplaceConfig, marketplaceQuery } from "../lib/marketplace";
import ISBFMarketplaceCard from "./isbf-marketplace-card";

export default class ISBFMarketplace extends Component {
  @service appEvents;
  @service composer;
  @service currentUser;
  @service site;
  @service store;

  @tracked error = false;
  @tracked loading = false;
  @tracked topicList = null;
  @tracked topics = [];

  constructor() {
    super(...arguments);
    scheduleOnce("afterRender", this, this.load);
  }

  get config() {
    return marketplaceConfig(this.site);
  }

  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }

  get canCreate() {
    return Boolean(
      this.config?.publishing_enabled !== false &&
      this.currentUser &&
      this.site.categories?.find(
        (category) => category.id === this.config?.category_id,
      )?.canCreateTopic,
    );
  }

  @action
  login() {
    this.appEvents.trigger("show-login");
  }

  @action
  create() {
    if (!this.canCreate) {
      return;
    }
    this.composer.open({
      action: Composer.CREATE_TOPIC,
      categoryId: this.config.category_id,
      draftKey: Composer.NEW_TOPIC_KEY,
    });
  }

  @action
  async load() {
    if (!this.config || !this.currentUser || this.loading) {
      return;
    }
    this.loading = true;
    this.error = false;
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: marketplaceQuery(),
      });
      if (!this.isDestroying) {
        this.topicList = list;
        this.topics = [...list.topics];
      }
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }

  @action
  async loadMore() {
    if (this.loading || !this.canLoadMore) {
      return;
    }
    this.loading = true;
    this.error = false;
    const list = this.topicList;
    try {
      await list.loadMore();
      if (!this.isDestroying) {
        this.topics = [...list.topics];
      }
    } catch {
      list.set("loadingMore", false);
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }

  @action
  retry() {
    return this.topicList ? this.loadMore() : this.load();
  }

  <template>
    <main aria-busy={{this.loading}} class="isbf-marketplace">
      <header class="isbf-marketplace__header">
        <a
          aria-label={{i18n (themePrefix "isbf_v2.marketplace_back")}}
          href="/isbf/workbench"
        >{{dIcon "arrow-left"}}</a>
        <h1>{{i18n (themePrefix "isbf_v2.workbench_marketplace")}}</h1>
      </header>
      {{#if this.config}}
        {{#if this.currentUser}}
          {{#each this.topics key="id" as |topic|}}<ISBFMarketplaceCard
              @topic={{topic}}
            />{{/each}}
          {{#if this.loading}}
            <p class="isbf-marketplace__notice" role="status">{{i18n
                (themePrefix "isbf_v2.learning_loading")
              }}</p>
          {{else if this.error}}
            <p class="isbf-marketplace__notice" role="alert">{{i18n
                (themePrefix "isbf_v2.marketplace_error")
              }}</p>
            <DButton
              @action={{this.retry}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
            />
          {{else if this.canLoadMore}}
            <DButton
              @action={{this.loadMore}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.load_more")}}
            />
          {{else}}{{#unless this.topics.length}}
              <p class="isbf-marketplace__notice">{{i18n
                  (themePrefix "isbf_v2.marketplace_empty")
                }}</p>
            {{/unless}}{{/if}}
          {{#if this.canCreate}}
            <DButton
              class="btn-primary isbf-marketplace__create"
              @action={{this.create}}
              @icon="plus"
              @translatedLabel={{i18n
                (themePrefix "isbf_v2.marketplace_publish")
              }}
            />
          {{/if}}
        {{else}}
          <div class="isbf-marketplace__notice">
            <p>{{i18n (themePrefix "isbf_v2.marketplace_login")}}</p>
            <DButton @action={{this.login}} @label="log_in" />
          </div>
        {{/if}}
      {{else}}
        <p class="isbf-marketplace__notice">{{i18n
            (themePrefix "isbf_v2.marketplace_unavailable")
          }}</p>
      {{/if}}
    </main>
  </template>
}
