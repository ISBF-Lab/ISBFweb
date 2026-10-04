import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import dCategoryBadge from "discourse/ui-kit/helpers/d-category-badge";
import { i18n } from "discourse-i18n";
import {
  explorePreviewBudget,
  previewForHeights,
} from "../lib/explore-preview";
import { enqueueExploreQuery, uniqueTopicList } from "../lib/explore-query";
import ISBFV2FeedCard from "./isbf-v2-feed-card";

export default class ISBFExploreGroup extends Component {
  @service router;
  @service store;

  @tracked expanded = false;
  @tracked hasLoaded = false;
  @tracked isLoading = false;
  @tracked loadFailed = false;
  @tracked previewComplete = false;
  @tracked previewCount = 0;
  @tracked topics = [];
  @tracked topicList = null;

  #frame;
  #heights = new Map();
  #intersectionObserver;
  #mutationObserver;
  #observedCards = new Set();
  #requestNumber = 0;
  #resizeObserver;
  #root;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#requestNumber += 1;
    this.#intersectionObserver?.disconnect();
    this.#mutationObserver?.disconnect();
    this.#resizeObserver?.disconnect();
    window.cancelAnimationFrame(this.#frame);
    window.removeEventListener("resize", this.scheduleMeasurement);
    window.visualViewport?.removeEventListener(
      "resize",
      this.scheduleMeasurement
    );
  }

  get canLoadMore() {
    return Boolean(this.topicList?.canLoadMore);
  }

  get candidateTopic() {
    return !this.expanded && !this.previewComplete
      ? this.topics[this.previewCount]
      : null;
  }

  get renderedTopics() {
    return this.expanded
      ? this.topics
      : this.topics.slice(0, this.previewCount);
  }

  @action
  async load() {
    if (this.isLoading) {
      return;
    }
    const request = ++this.#requestNumber;
    this.isLoading = true;
    this.loadFailed = false;
    try {
      const list = await enqueueExploreQuery(
        () =>
          this.store.findFiltered("topicList", {
            filter: "filter",
            params: { q: this.args.query },
          }),
        () => this.#isCurrent(request)
      );
      if (!this.#isCurrent(request) || !list) {
        return;
      }
      this.topicList = list;
      this.topics = uniqueTopicList(list.topics);
      this.hasLoaded = true;
      this.#heights.clear();
      this.previewCount = 0;
      this.previewComplete = false;
      this.#scheduleAfterRender();
    } catch {
      if (this.#isCurrent(request)) {
        this.loadFailed = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.isLoading = false;
      }
    }
  }

  @action
  async loadMore() {
    if (!this.expanded || this.isLoading || !this.canLoadMore) {
      return;
    }
    const request = ++this.#requestNumber;
    const list = this.topicList;
    this.isLoading = true;
    this.loadFailed = false;
    try {
      await enqueueExploreQuery(
        () => list.loadMore(),
        () => this.#isCurrent(request) && this.expanded
      );
      if (this.#isCurrent(request)) {
        this.topics = uniqueTopicList(list.topics);
        this.#scheduleAfterRender();
      }
    } catch {
      if (this.#isCurrent(request)) {
        this.loadFailed = true;
      }
    } finally {
      if (this.#isCurrent(request)) {
        this.isLoading = false;
      }
    }
  }

  @action
  navigateToTopic(topic) {
    this.router.transitionTo(topic.url);
  }

  @action
  observe(element) {
    this.#root = element;
    this.#resizeObserver = new ResizeObserver(this.scheduleMeasurement);
    this.#resizeObserver.observe(element);
    this.#mutationObserver = new MutationObserver(this.scheduleMeasurement);
    this.#mutationObserver.observe(element, {
      attributeFilter: ["data-content-ready"],
      attributes: true,
      childList: true,
      subtree: true,
    });
    this.#intersectionObserver = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          this.#intersectionObserver.disconnect();
          void this.load();
        }
      },
      { rootMargin: "480px 0px" }
    );
    this.#intersectionObserver.observe(element);
    window.addEventListener("resize", this.scheduleMeasurement);
    window.visualViewport?.addEventListener("resize", this.scheduleMeasurement);
  }

  @action
  retry() {
    if (this.hasLoaded && this.expanded && this.canLoadMore) {
      void this.loadMore();
    } else {
      void this.load();
    }
  }

  @action
  scheduleMeasurement() {
    if (this.#frame || this.isDestroying) {
      return;
    }
    this.#frame = window.requestAnimationFrame(() => {
      this.#frame = null;
      if (!this.isDestroying) {
        this.#measurePreview();
      }
    });
  }

  @action
  toggleExpanded() {
    this.#measurePreview();
    this.expanded = !this.expanded;
    this.#scheduleAfterRender();
  }

  #isCurrent(request) {
    return request === this.#requestNumber && !this.isDestroying;
  }

  #measurePreview() {
    if (!this.#root || !this.hasLoaded) {
      return;
    }
    const topicContainer = this.#root.querySelector(
      ".isbf-explore-group__topics"
    );
    const width = topicContainer.getBoundingClientRect().width;
    if (width <= 0) {
      return;
    }
    const cards = new Map();
    const rendered = this.renderedTopics;
    topicContainer
      .querySelectorAll(":scope > .isbf-feed-card")
      .forEach((card, index) => cards.set(card, rendered[index]));
    const candidate = this.#root.querySelector(
      ".isbf-explore-group__measure > .isbf-feed-card"
    );
    if (candidate && this.candidateTopic) {
      cards.set(candidate, this.candidateTopic);
    }
    for (const oldCard of this.#observedCards) {
      if (!cards.has(oldCard)) {
        this.#resizeObserver.unobserve(oldCard);
      }
    }
    this.#observedCards = new Set(cards.keys());
    for (const [card, topic] of cards) {
      this.#resizeObserver.observe(card);
      if (topic && card.dataset.contentReady === "true") {
        const rect = card.getBoundingClientRect();
        if (rect.height > 0 && Math.abs(rect.width - width) < 1) {
          this.#heights.set(topic.id, { height: rect.height, width });
        }
      }
    }
    const heights = this.topics.map((topic) => {
      const measurement = this.#heights.get(topic.id);
      return measurement && Math.abs(measurement.width - width) < 1
        ? measurement.height
        : null;
    });
    const preview = previewForHeights(
      heights,
      explorePreviewBudget(this.#root)
    );
    if (
      this.previewCount !== preview.count ||
      this.previewComplete !== preview.complete
    ) {
      this.previewCount = preview.count;
      this.previewComplete = preview.complete;
      this.#scheduleAfterRender();
    }
  }

  #scheduleAfterRender() {
    scheduleOnce("afterRender", this, this.scheduleMeasurement);
  }

  <template>
    <section class="isbf-explore-group" {{didInsert this.observe}}>
      <header class="isbf-explore-group__header">
        <h2 class="isbf-explore-group__title">
          {{#if @category}}{{dCategoryBadge
              @category
              allowUncategorized=true
            }}{{else}}{{@label}}{{/if}}
        </h2>
      </header>
      <div class="isbf-explore-group__topics">
        {{#each this.renderedTopics key="id" as |topic|}}
          <ISBFV2FeedCard
            @navigateToTopic={{this.navigateToTopic}}
            @topic={{topic}}
          />
        {{/each}}
      </div>
      {{#if this.candidateTopic}}
        <div
          aria-hidden="true"
          class="isbf-explore-group__measure"
          data-has-previous={{if this.previewCount "true" "false"}}
          inert
        >
          <ISBFV2FeedCard
            @measureOnly={{true}}
            @navigateToTopic={{this.navigateToTopic}}
            @topic={{this.candidateTopic}}
          />
        </div>
      {{/if}}
      {{#if this.loadFailed}}
        <div class="isbf-explore-group__error" role="alert">
          <span>{{i18n (themePrefix "isbf_v2.explore_load_error")}}</span>
          <button type="button" {{on "click" this.retry}}>{{i18n
              (themePrefix "isbf_v2.explore_retry")
            }}</button>
        </div>
      {{else if this.isLoading}}
        <p class="isbf-explore-group__empty" role="status">{{i18n
            (themePrefix "isbf_v2.explore_loading")
          }}</p>
      {{else if this.hasLoaded}}
        {{#unless this.topics.length}}<p
            class="isbf-explore-group__empty"
          >{{i18n (themePrefix "isbf_v2.explore_empty")}}</p>{{/unless}}
      {{else}}
        <p class="isbf-explore-group__empty" role="status">{{i18n
            (themePrefix "isbf_v2.explore_loading")
          }}</p>
      {{/if}}
      <footer class="isbf-explore-group__footer">
        <button
          aria-expanded={{if this.expanded "true" "false"}}
          class="isbf-explore-group__toggle"
          disabled={{eq this.topics.length 0}}
          type="button"
          {{on "click" this.toggleExpanded}}
        >{{i18n
            (themePrefix
              (if
                this.expanded
                "isbf_v2.explore_collapse"
                "isbf_v2.explore_expand"
              )
            )
          }}</button>
        {{#if this.expanded}}
          {{#if this.canLoadMore}}
            <button
              class="isbf-explore-group__more"
              disabled={{this.isLoading}}
              type="button"
              {{on "click" this.loadMore}}
            >{{i18n (themePrefix "isbf_v2.explore_load_more")}}</button>
          {{else if this.hasLoaded}}
            <span>{{i18n (themePrefix "isbf_v2.explore_end")}}</span>
          {{/if}}
        {{/if}}
      </footer>
    </section>
  </template>
}
