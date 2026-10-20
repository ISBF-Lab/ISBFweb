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
import { hasPostPreviewTarget, postPreview } from "../lib/post-preview";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFPostPreview extends Component {
  #generation = 0;
  #observer;
  #requested = false;
  static {
    g(this.prototype, "_failedImages", [tracked], function () {
      return [];
    });
  }
  #_failedImages = (i(this, "_failedImages"), void 0);
  static {
    g(this.prototype, "_preview", [tracked], function () {
      return null;
    });
  }
  #_preview = (i(this, "_preview"), void 0);
  get isRail() {
    return this.args.variant === "rail";
  }
  get isSummary() {
    return this.args.variant === "summary";
  }
  get preview() {
    return this.args.disabled ? {
      text: "",
      images: []
    } : this._preview ?? postPreview(this.args.excerpt);
  }
  static {
    n(this.prototype, "preview", [cached]);
  }
  get images() {
    if (this.args.disabled || this.isRail || this.isSummary) {
      return [];
    }
    return (this._preview?.images ?? []).filter(image => !this._failedImages.includes(image.src)).slice(0, 3);
  }
  get text() {
    return this.isRail && this.title || this.preview.text || i18n(themePrefix(this.isRail || this.isSummary ? this.preview.images.length ? "isbf_v2.preview_picture" : "isbf_v2.preview_post" : "isbf_v2.preview_open"));
  }
  get title() {
    return optionalTopicTitle(this.args.title);
  }
  observe(element) {
    this.#observer?.disconnect();
    this.#generation += 1;
    this.#requested = false;
    this._preview = null;
    this._failedImages = [];
    if (this.args.disabled || !hasPostPreviewTarget(this.args) || this.isRail && this.title) {
      return;
    }
    this.#observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        this.#observer.disconnect();
        this.#loadBody();
      }
    }, {
      rootMargin: "200px",
      threshold: 0
    });
    this.#observer.observe(element);
  }
  static {
    n(this.prototype, "observe", [action]);
  }
  destroyObserver() {
    this.#generation += 1;
    this.#observer?.disconnect();
  }
  static {
    n(this.prototype, "destroyObserver", [action]);
  }
  imageFailed(source) {
    this._failedImages = [...this._failedImages, source];
  }
  static {
    n(this.prototype, "imageFailed", [action]);
  }
  async #loadBody() {
    if (this.#requested) {
      return;
    }
    this.#requested = true;
    const generation = this.#generation;
    try {
      const cooked = await loadCookedPost(this.args.postId, {
        topicId: this.args.topicId,
        postNumber: this.args.postNumber
      });
      if (!this.isDestroying && generation === this.#generation) {
        this._preview = postPreview(cooked);
      }
    } catch {
      // The existing excerpt and post link remain usable if the request fails.
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <a
      class={{dConcatClass
        "isbf-post-preview"
        (if this.isRail "--rail" (if this.isSummary "--summary" "--activity"))
      }}
      href={{@href}}
      ...attributes
      {{didInsert this.observe}}
      {{didUpdate
        this.observe
        @postId
        @topicId
        @postNumber
        @disabled
        @title
        @excerpt
        @variant
      }}
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
    */
    {
      "id": null,
      "block": "[[[11,3],[16,0,[28,[32,0],[\"isbf-post-preview\",[52,[30,0,[\"isRail\"]],\"--rail\",[52,[30,0,[\"isSummary\"]],\"--summary\",\"--activity\"]]],null]],[16,6,[30,1]],[17,2],[4,[32,1],[[30,0,[\"observe\"]]],null],[4,[32,2],[[30,0,[\"observe\"]],[30,3],[30,4],[30,5],[30,6],[30,7],[30,8],[30,9]],null],[4,[32,3],[[30,0,[\"destroyObserver\"]]],null],[12],[1,\"\\n  \"],[10,1],[14,0,\"isbf-post-preview__text\"],[12],[1,[28,[32,4],[[30,0,[\"text\"]]],null]],[13],[1,\"\\n\"],[41,[30,0,[\"images\",\"length\"]],[[[1,\"    \"],[10,1],[14,0,\"isbf-post-preview__images\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"images\"]]],null]],null],\"src\",[[[1,\"        \"],[11,\"img\"],[16,\"alt\",[28,[32,5],[[28,[32,6],[\"isbf_v2.preview_image\"],null]],null]],[24,0,\"isbf-post-preview__image\"],[24,\"decoding\",\"async\"],[24,\"loading\",\"lazy\"],[16,\"src\",[30,10,[\"src\"]]],[4,[32,7],[\"error\",[28,[32,8],[[30,0,[\"imageFailed\"]],[30,10,[\"src\"]]],null]],null],[12],[13],[1,\"\\n\"]],[10]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[41,[30,0,[\"isRail\"]],[[[1,[28,[32,9],[\"chevron-right\"],null]]],[]],null],[1,\"\\n\"],[13]],[\"@href\",\"&attrs\",\"@postId\",\"@topicId\",\"@postNumber\",\"@disabled\",\"@title\",\"@excerpt\",\"@variant\",\"image\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        didInsert,
        didUpdate,
        willDestroy,
        dReplaceEmoji,
        i18n,
        themePrefix,
        on,
        fn,
        dIcon
      }),
      "isStrictMode": true
    }), this);
  }
}