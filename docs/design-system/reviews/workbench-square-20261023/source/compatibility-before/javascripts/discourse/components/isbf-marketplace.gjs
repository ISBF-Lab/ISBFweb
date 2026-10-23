import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import Composer from "discourse/models/composer";
import { marketplaceConfig, marketplaceQuery } from "../lib/marketplace";
import ISBFMarketplaceCard from "./isbf-marketplace-card";
import ISBFWorkbenchTopicPage from "./isbf-workbench-topic-page";

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
    <ISBFWorkbenchTopicPage
      class="isbf-marketplace"
      @canCreate={{this.canCreate}}
      @canLoadMore={{this.canLoadMore}}
      @config={{this.config}}
      @currentUser={{this.currentUser}}
      @error={{this.error}}
      @hasTopics={{this.topics.length}}
      @kind="marketplace"
      @loading={{this.loading}}
      @onCreate={{this.create}}
      @onLoadMore={{this.loadMore}}
      @onLogin={{this.login}}
      @onRetry={{this.retry}}
    >
      {{#each this.topics key="id" as |topic|}}
        <ISBFMarketplaceCard @topic={{topic}} />
      {{/each}}
    </ISBFWorkbenchTopicPage>
  </template>
}
