import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import Composer from "discourse/models/composer";
import { teamupConfig, teamupQuery } from "../lib/teamup";
import ISBFV2FeedCard from "./isbf-v2-feed-card";
import ISBFWorkbenchTopicPage from "./isbf-workbench-topic-page";

export default class ISBFTeamup extends Component {
  @service appEvents;
  @service composer;
  @service currentUser;
  @service router;
  @service site;
  @service store;

  @tracked error = false;
  @tracked loading = false;
  @tracked topicList = null;
  @tracked topics = [];

  #refreshPending = false;
  #retryLoadMore = false;

  constructor() {
    super(...arguments);
    this.appEvents.on("composer:created-post", this.refresh);
    this.appEvents.on("composer:edited-post", this.editRefresh);
    scheduleOnce("afterRender", this, this.load);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("composer:created-post", this.refresh);
    this.appEvents.off("composer:edited-post", this.editRefresh);
  }

  get config() {
    return teamupConfig(this.site);
  }

  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }

  get canCreate() {
    return Boolean(
      this.config &&
      this.config?.publishing_enabled !== false &&
      this.currentUser &&
      this.site.categories?.find(
        (category) => category.id === this.config?.category_id,
      )?.canCreateTopic,
    );
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
    if (
      this.isDestroying ||
      !this.config ||
      !this.currentUser ||
      this.loading
    ) {
      return;
    }
    this.loading = true;
    this.error = false;
    this.#retryLoadMore = false;
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: teamupQuery(),
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
        if (this.#refreshPending) {
          this.#refreshPending = false;
          this.load();
        }
      }
    }
  }

  @action
  async loadMore() {
    if (this.isDestroying || this.loading || !this.canLoadMore) {
      return;
    }
    this.loading = true;
    this.error = false;
    this.#retryLoadMore = true;
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
        if (this.#refreshPending) {
          this.#refreshPending = false;
          this.load();
        }
      }
    }
  }

  @action
  login() {
    this.appEvents.trigger("show-login");
  }

  @action
  navigateToTopic(topic) {
    this.router.transitionTo(topic.url);
  }

  @action
  editRefresh() {
    if (this.isDestroying) {
      return;
    }
    this.topics = [];
    return this.refresh();
  }

  @action
  refresh() {
    if (this.loading) {
      this.#refreshPending = true;
      return;
    }
    return this.load();
  }

  @action
  retry() {
    return this.#retryLoadMore ? this.loadMore() : this.load();
  }

  <template>
    <ISBFWorkbenchTopicPage
      class="isbf-teamup"
      @canCreate={{this.canCreate}}
      @canLoadMore={{this.canLoadMore}}
      @config={{this.config}}
      @currentUser={{this.currentUser}}
      @error={{this.error}}
      @hasTopics={{this.topics.length}}
      @kind="teamup"
      @loading={{this.loading}}
      @onCreate={{this.create}}
      @onLoadMore={{this.loadMore}}
      @onLogin={{this.login}}
      @onRetry={{this.retry}}
    >
      {{#each this.topics key="id" as |topic|}}
        <ISBFV2FeedCard
          @navigateToTopic={{this.navigateToTopic}}
          @topic={{topic}}
        />
      {{/each}}
    </ISBFWorkbenchTopicPage>
  </template>
}
