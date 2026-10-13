import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  recordVisiblePostView,
  recordVisibleView,
} from "../lib/feed-view-tracker";
import { compactNumber } from "../lib/post-card-helpers";

export default class ISBFTopicViews extends Component {
  static shouldRender({ post }) {
    return post.post_type === 1 && post.post_number >= 1;
  }

  @service currentUser;
  @service siteSettings;

  @tracked count = null;

  #observer;
  #pending = false;
  #visible = false;

  get countLabel() {
    return this.count === null
      ? ""
      : this.count === 0
        ? "0"
        : compactNumber(this.count);
  }

  get label() {
    return this.count === null
      ? i18n(themePrefix("isbf_v2.views"))
      : i18n(themePrefix("isbf_v2.views_count"), { count: this.count });
  }

  @action
  observe(element) {
    if (!this.currentUser || !this.siteSettings.isbf_views_enabled) {
      return;
    }
    this.#observer = new IntersectionObserver(
      (entries) => {
        this.#visible = entries.some((entry) => entry.isIntersecting);
        this.onVisibilityChange();
      },
      { rootMargin: "0px", threshold: 0 }
    );
    this.#observer.observe(
      element.closest(".isbf-topic-card__article") ?? element
    );
    document.addEventListener("visibilitychange", this.onVisibilityChange);
  }

  @action
  onVisibilityChange() {
    if (this.#visible && document.visibilityState === "visible") {
      this.#recordView();
    }
  }

  @action
  destroyObserver() {
    this.#observer?.disconnect();
    this.#visible = false;
    document.removeEventListener("visibilitychange", this.onVisibilityChange);
  }

  async #recordView() {
    if (this.#pending) {
      return;
    }
    this.#pending = true;
    const post = this.args.post;
    const count = await (post.post_number === 1
      ? recordVisibleView(post.topic.id, this.currentUser.id)
      : recordVisiblePostView(post.id, this.currentUser.id));
    if (!this.isDestroying) {
      this.count = count;
      if (count !== null) {
        this.destroyObserver();
      }
    }
    this.#pending = false;
  }

  <template>
    <span
      aria-label={{this.label}}
      class="isbf-topic-card__views"
      title={{this.label}}
      ...attributes
      {{didInsert this.observe}}
      {{willDestroy this.destroyObserver}}
    >
      {{dIcon "chart-bar"}}{{this.countLabel}}
    </span>
  </template>
}
