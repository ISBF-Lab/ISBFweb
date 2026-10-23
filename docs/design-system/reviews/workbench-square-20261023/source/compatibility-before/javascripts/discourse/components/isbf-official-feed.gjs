import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import {
  buildOfficialQuery,
  OfficialRequestGuard,
} from "../lib/official-filters";
import { sortHomePinList } from "../lib/pinning";
import ISBFOfficialPicker from "./isbf-official-picker";
import ISBFV2FeedCard from "./isbf-v2-feed-card";

export default class ISBFOfficialFeed extends Component {
  @service appEvents;
  @service router;
  @service store;

  @tracked campus = "";
  @tracked type = "";
  @tracked error = false;
  @tracked loading = false;
  @tracked topicList = null;
  @tracked topics = [];

  #requests = new OfficialRequestGuard();

  constructor() {
    super(...arguments);
    this.appEvents.on("isbf:home-pins-changed", this.refreshHomePins);
    scheduleOnce("afterRender", this, this.load);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:home-pins-changed", this.refreshHomePins);
    this.#requests.next();
  }

  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }

  get isEmpty() {
    return this.topicList && !this.topics.length && !this.loading;
  }

  get campusSelections() {
    return this.campus ? [this.campus] : [];
  }

  get typeSelections() {
    return this.type ? [this.type] : [];
  }

  @action
  refreshHomePins() {
    if (!this.isDestroying && this.topicList) {
      sortHomePinList(this.topicList);
      this.topics = [...this.topicList.topics];
    }
  }

  @action
  changeCampus(id) {
    this.campus = id;
    this.load();
  }

  @action
  changeType(id) {
    this.type = id;
    this.load();
  }

  @action
  async load() {
    const request = this.#requests.next();
    this.loading = true;
    this.error = false;
    this.topicList = null;
    this.topics = [];
    try {
      const list = await this.store.findFiltered("topicList", {
        filter: "filter",
        params: {
          q: buildOfficialQuery(this.args.config, this.campus, this.type),
        },
      });
      if (this.#isCurrent(request)) {
        this.topicList = list;
        this.topics = [...list.topics];
      }
    } catch {
      if (this.#isCurrent(request)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.loading = false;
      }
    }
  }

  @action
  async loadMore() {
    if (this.loading || !this.canLoadMore) {
      return;
    }
    const request = this.#requests.next();
    const list = this.topicList;
    this.loading = true;
    this.error = false;
    try {
      await list.loadMore();
      if (this.#isCurrent(request)) {
        this.topics = [...list.topics];
      }
    } catch {
      list.set("loadingMore", false);
      if (this.#isCurrent(request)) {
        this.error = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.loading = false;
      }
    }
  }

  @action
  navigateToTopic(topic) {
    this.router.transitionTo(topic.url);
  }

  @action
  retry() {
    return this.topicList ? this.loadMore() : this.load();
  }

  #isCurrent(request) {
    return !this.isDestroying && this.#requests.isCurrent(request);
  }

  <template>
    <main aria-busy={{this.loading}} class="isbf-official-feed">
      <div class="isbf-official-feed__filters">
        <ISBFOfficialPicker
          @allKey="isbf_v2.official_all_campuses"
          @items={{@config.campuses}}
          @labelKey="isbf_v2.official_campus"
          @onSelect={{this.changeCampus}}
          @selectedIds={{this.campusSelections}}
        />
        <ISBFOfficialPicker
          @allKey="isbf_v2.official_all_types"
          @items={{@config.types}}
          @labelKey="isbf_v2.official_type"
          @onSelect={{this.changeType}}
          @selectedIds={{this.typeSelections}}
        />
      </div>
      {{#each this.topics key="id" as |topic|}}
        <ISBFV2FeedCard
          @navigateToTopic={{this.navigateToTopic}}
          @officialLayout={{true}}
          @topic={{topic}}
        />
      {{/each}}
      <div aria-live="polite" class="isbf-official-feed__status">
        {{#if this.loading}}
          <p role="status">{{i18n (themePrefix "isbf_v2.official_loading")}}</p>
        {{else if this.error}}
          <p role="alert">{{i18n
              (themePrefix "isbf_v2.official_load_error")
            }}</p>
          <button type="button" {{on "click" this.retry}}>{{i18n
              (themePrefix "isbf_v2.official_retry")
            }}</button>
        {{else if this.isEmpty}}
          <p>{{i18n (themePrefix "isbf_v2.official_empty")}}</p>
        {{/if}}
        {{#if this.canLoadMore}}
          {{#unless this.error}}
            <button
              disabled={{this.loading}}
              type="button"
              {{on "click" this.loadMore}}
            >{{i18n (themePrefix "isbf_v2.load_more")}}</button>
          {{/unless}}
        {{/if}}
      </div>
    </main>
  </template>
}
