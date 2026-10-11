import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { themePrefix } from "virtual:theme";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dReplaceEmoji from "discourse/ui-kit/helpers/d-replace-emoji";
import { i18n } from "discourse-i18n";
import { loadCookedPost } from "../lib/feed-post-loader";
import { optionalTopicTitle } from "../lib/optional-topic-title";
import { postPreview } from "../lib/post-preview";

export default class ISBFPostPreview extends Component {
  #generation = 0;
  #observer;

  #requested = false;
  @tracked _failedImages = [];
  @tracked _preview = null;

  get isRail() {
    return this.args.variant === "rail";
  }

  @cached
  get preview() {
    return this.args.disabled
      ? { text: "", images: [] }
      : (this._preview ?? postPreview(this.args.excerpt));
  }

  get images() {
    if (this.args.disabled || (this.isRail && this.title)) {
      return [];
    }
    return (this._preview?.images ?? [])
      .filter((image) => !this._failedImages.includes(image.src))
      .slice(0, this.isRail ? 1 : 3);
  }

  get text() {
    return (
      (this.isRail && this.title) ||
      this.preview.text ||
      i18n(themePrefix("isbf_v2.preview_open"))
    );
  }

  get title() {
    return optionalTopicTitle(this.args.title);
  }

  @action
  observe(element) {
    this.#observer?.disconnect();
    this.#generation += 1;
    this.#requested = false;
    this._preview = null;
    this._failedImages = [];
    if (
      this.args.disabled ||
      Number(this.args.postId) <= 0 ||
      !this.args.postId ||
      (this.isRail && this.title)
    ) {
      return;
    }

    this.#observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          this.#observer.disconnect();
          this.#loadBody();
        }
      },
      { rootMargin: "200px", threshold: 0 }
    );
    this.#observer.observe(element);
  }

  @action
  destroyObserver() {
    this.#generation += 1;
    this.#observer?.disconnect();
  }

  @action
  imageFailed(source) {
    this._failedImages = [...this._failedImages, source];
  }

  async #loadBody() {
    if (this.#requested) {
      return;
    }
    this.#requested = true;
    const generation = this.#generation;
    try {
      const cooked = await loadCookedPost(this.args.postId);
      if (!this.isDestroying && generation === this.#generation) {
        this._preview = postPreview(cooked);
      }
    } catch {
      // The existing excerpt and post link remain usable if the request fails.
    }
  }

  <template>
    <a
      class={{dConcatClass
        "isbf-post-preview"
        (if this.isRail "--rail" "--activity")
      }}
      href={{@href}}
      ...attributes
      {{didInsert this.observe}}
      {{didUpdate this.observe @postId @disabled @title}}
      {{willDestroy this.destroyObserver}}
    >
      <span class="isbf-post-preview__text">{{dReplaceEmoji this.text}}</span>
      {{#if this.images.length}}
        <span class="isbf-post-preview__images">
          {{#each this.images key="src" as |image|}}
            <img
              alt={{i18n (themePrefix "isbf_v2.preview_image")}}
              class="isbf-post-preview__image"
              decoding="async"
              loading="lazy"
              src={{image.src}}
              {{on "error" (fn this.imageFailed image.src)}}
            />
          {{/each}}
        </span>
      {{/if}}
      {{#if this.isRail}}{{dIcon "chevron-right"}}{{/if}}
    </a>
  </template>
}
