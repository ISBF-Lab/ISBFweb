import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { localizedTopicTitle } from "discourse/lib/topic-display-title";
import dReplaceEmoji from "discourse/ui-kit/helpers/d-replace-emoji";
import { loadCookedPost } from "../lib/feed-post-loader";
import { isUntitledTopicTitle } from "../lib/optional-topic-title";
import { postPreview } from "../lib/post-preview";
import topicDisplayTitle, {
  unavailableTitleContent,
} from "../lib/topic-display-title";

export default class ISBFTopicLinkTitle extends Component {
  #generation = 0;

  #observer;
  @tracked _cooked;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#generation++;
    this.#observer?.disconnect();
  }

  get topic() {
    return this.args.outletArgs.topic;
  }

  get untitled() {
    return (
      !localizedTopicTitle(this.topic) &&
      isUntitledTopicTitle(this.topic.title ?? this.topic.fancy_title)
    );
  }

  get text() {
    return topicDisplayTitle(this.topic.title ?? this.topic.fancy_title, {
      cooked: this._cooked,
      excerpt: this.topic.excerpt,
      hidden: unavailableTitleContent(this.topic),
      postStream: this.topic.postStream,
    });
  }

  @action
  observe(element) {
    this.#observer?.disconnect();
    const generation = ++this.#generation;
    this._cooked = undefined;
    const preview = postPreview(this.topic.excerpt);
    if (
      !this.untitled ||
      unavailableTitleContent(this.topic) ||
      this.topic.archetype !== "regular" ||
      !this.topic.category ||
      this.topic.category?.read_restricted ||
      preview.text ||
      preview.images.length
    ) {
      return;
    }

    const topicId = this.topic.id;
    this.#observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          this.#observer.disconnect();
          void this.#load(topicId, generation);
        }
      },
      { rootMargin: "200px" }
    );
    this.#observer.observe(element);
  }

  async #load(topicId, generation) {
    try {
      const cooked = await loadCookedPost(null, { topicId, postNumber: 1 });
      if (!this.isDestroying && generation === this.#generation) {
        this._cooked = cooked;
      }
    } catch {
      // Keep the neutral title and the original link on request failure.
    }
  }

  <template>
    {{#if this.untitled}}
      <span
        class="isbf-topic-title-preview"
        {{didInsert this.observe}}
        {{didUpdate
          this.observe
          this.topic.id
          this.topic.title
          this.topic.excerpt
          this.topic.hidden
          this.topic.deleted
        }}
      >{{dReplaceEmoji this.text}}</span>
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
