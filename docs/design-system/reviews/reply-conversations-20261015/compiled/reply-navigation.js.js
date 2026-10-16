import { tracked } from "@glimmer/tracking";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DiscourseURL from "discourse/lib/url";
import { i18n } from "discourse-i18n";
import { g, i } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ReplyNavigation {
  static {
    g(this.prototype, "currentIndex", [tracked], function () {
      return 1;
    });
  }
  #currentIndex = (i(this, "currentIndex"), void 0);
  static {
    g(this.prototype, "lastReadIndex", [tracked], function () {
      return 0;
    });
  }
  #lastReadIndex = (i(this, "lastReadIndex"), void 0);
  static {
    g(this.prototype, "metadata", [tracked]);
  }
  #metadata = (i(this, "metadata"), void 0);
  #appEvents;
  #entries = new Map();
  #generation = 0;
  #topic;
  #destroyed = false;
  constructor(topic, appEvents) {
    this.#topic = topic;
    this.#appEvents = appEvents;
    this.metadata = topic.reply_navigation || {
      root_count: 0,
      reply_count: 0
    };
    this.currentIndex = this.metadata.root_index || 1;
    for (const post of topic.postStream.posts) {
      if (post.root_index) {
        this.#entries.set(post.root_index, {
          root_post_number: post.post_number,
          root_created_at: post.created_at
        });
      }
    }
    if (topic.last_read_post_number > 1) {
      this.#fetch({
        post_number: topic.last_read_post_number
      }).then(data => {
        if (!this.#destroyed) {
          this.lastReadIndex = data.root_index;
          this.notify();
        }
      }).catch(() => {});
    }
  }
  get total() {
    return (this.#topic.reply_navigation || this.metadata).root_count;
  }
  get loadedAllPosts() {
    return true;
  }
  dateForIndex(index) {
    const date = this.#entries.get(index)?.root_created_at || this.#topic.postStream.posts.find(post => post.root_index === index)?.created_at;
    return date ? new Date(date) : null;
  }
  destroy() {
    this.#destroyed = true;
    this.#generation++;
  }
  excerpt() {
    return Promise.resolve(null);
  }
  label(index = this.currentIndex) {
    return i18n(themePrefix("isbf_v2.reply_conversations.progress"), {
      current: Math.min(index, this.total),
      total: this.total
    });
  }
  notify(index = this.currentIndex) {
    this.currentIndex = index;
    this.#appEvents.trigger("topic:group-scrolled", {
      postIndex: index,
      percent: index >= this.total ? 1 : (index - 1) / Math.max(this.total, 1)
    });
  }
  async jumpToIndex(index) {
    const generation = ++this.#generation;
    const data = await this.#fetch({
      root_index: index
    });
    if (this.#destroyed || generation !== this.#generation) {
      return;
    }
    this.jumpToPostNumber(data.root_post_number);
  }
  jumpToPostNumber(postNumber) {
    if (postNumber && !this.#destroyed) {
      DiscourseURL.routeTo(`${this.#topic.url}/${postNumber}`);
    }
  }
  async #fetch(query) {
    const data = await ajax(`/n/${this.#topic.slug}/${this.#topic.id}/navigation.json`, {
      data: query
    });
    if (!this.#destroyed) {
      this.#entries.set(data.root_index, data);
    }
    return data;
  }
}