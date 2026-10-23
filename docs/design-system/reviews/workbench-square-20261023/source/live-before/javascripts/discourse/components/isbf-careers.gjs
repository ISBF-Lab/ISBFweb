import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import Composer from "discourse/models/composer";
import { careersConfig, careersQuery } from "../lib/careers";
import ISBFCareersCard from "./isbf-careers-card";
import ISBFWorkbenchTopicPage from "./isbf-workbench-topic-page";

export default class ISBFCareers extends Component {
  @service appEvents;
  @service composer;
  @service currentUser;
  @service site;
  @service store;

  @tracked error = false;
  @tracked loading = false;
  @tracked topicList = null;
  @tracked topics = [];

  #request = 0;

  constructor() {
    super(...arguments);
    scheduleOnce("afterRender", this, this.load);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
  }

  get config() {
    return careersConfig(this.site);
  }

  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }

  get canCreate() {
    return Boolean(
      this.config?.publishing_enabled !== false &&
      this.currentUser &&
      this.site.categories?.find(
        (category) => category.id === this.config?.category_id
      )?.canCreateTopic
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
    const request = ++this.#request;
    const userId = this.currentUser?.id;
    const config = this.config;
    this.loading = true;
    this.error = false;
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: careersQuery(),
      });
      if (this.#isCurrent(request, userId, config)) {
        this.topicList = list;
        this.topics = [...list.topics];
      }
    } catch {
      if (this.#isCurrent(request, userId, config)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request, userId, config)) {
        this.loading = false;
      }
    }
  }

  @action
  async loadMore() {
    if (
      !this.currentUser ||
      !this.config ||
      this.loading ||
      !this.canLoadMore
    ) {
      return;
    }
    const request = ++this.#request;
    const userId = this.currentUser?.id;
    const config = this.config;
    this.loading = true;
    this.error = false;
    const list = this.topicList;
    try {
      await list.loadMore();
      if (this.#isCurrent(request, userId, config)) {
        this.topics = [...list.topics];
      }
    } catch {
      list.set("loadingMore", false);
      if (this.#isCurrent(request, userId, config)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request, userId, config)) {
        this.loading = false;
      }
    }
  }

  @action
  retry() {
    return this.topicList ? this.loadMore() : this.load();
  }

  #isCurrent(request, userId, config) {
    return (
      !this.isDestroying &&
      request === this.#request &&
      this.currentUser?.id === userId &&
      this.config === config
    );
  }

  <template>
    <ISBFWorkbenchTopicPage
      class="isbf-careers"
      @canCreate={{this.canCreate}}
      @canLoadMore={{this.canLoadMore}}
      @config={{this.config}}
      @currentUser={{this.currentUser}}
      @error={{this.error}}
      @hasTopics={{this.topics.length}}
      @kind="careers"
      @loading={{this.loading}}
      @onCreate={{this.create}}
      @onLoadMore={{this.loadMore}}
      @onLogin={{this.login}}
      @onRetry={{this.retry}}
    >
      {{#each this.topics key="id" as |topic|}}
        <ISBFCareersCard @topic={{topic}} />
      {{/each}}
    </ISBFWorkbenchTopicPage>
  </template>
}
