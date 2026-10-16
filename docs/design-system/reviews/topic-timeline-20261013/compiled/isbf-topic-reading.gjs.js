import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { themePrefix } from "virtual:theme";
import EmbedMode from "discourse/lib/embed-mode";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import isbfCloseOnClickOutside from "../modifiers/isbf-close-on-click-outside";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
function isReadingTopic(topic) {
  return !EmbedMode.enabled && topic?.archetype === "regular" && !topic.is_nested_view;
}
export default class ISBFTopicReading extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "menu", [service]);
  }
  #menu = (i(this, "menu"), void 0);
  static {
    g(this.prototype, "modal", [service]);
  }
  #modal = (i(this, "modal"), void 0);
  static {
    g(this.prototype, "hasProgress", [tracked], function () {
      return false;
    });
  }
  #hasProgress = (i(this, "hasProgress"), void 0);
  static {
    g(this.prototype, "header", [tracked], function () {
      return null;
    });
  }
  #header = (i(this, "header"), void 0);
  syncLayout = modifier(element => {
    const navigation = element.closest(".topic-navigation");
    const posts = navigation?.closest(".container.posts");
    const header = document.querySelector(".isbf-v2-shell--topic-feed-style .isbf-v2-page-header");
    if (!navigation || !posts || !header) {
      return;
    }
    let frame;
    navigation.classList.add("isbf-topic-reading");
    posts.classList.add("has-isbf-topic-reading");
    const update = () => {
      // The navigation's class binding can overwrite the outlet's classes.
      navigation.classList.add("isbf-topic-reading");
      posts.classList.add("has-isbf-topic-reading");
      if (this.header !== header) {
        this.header = header;
      }
      const area = navigation.querySelector(".timeline-scrollarea-wrapper");
      const hasProgress = Boolean(area || navigation.querySelector("#topic-progress:not(.hidden)"));
      if (this.hasProgress !== hasProgress) {
        this.hasProgress = hasProgress;
      }
      if (this.#needsInitialCollapse) {
        this.#needsInitialCollapse = false;
        this.#closeProgress();
      }
    };
    const scheduleLayout = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(update);
    };
    const observer = new ResizeObserver(scheduleLayout);
    observer.observe(navigation);
    document.addEventListener("keydown", this.onKeyDown);
    navigation.addEventListener("swipestart", this.#cancelSheetSwipe, true);
    navigation.addEventListener("swipecancel", this.#cancelSheetSwipe, true);
    scheduleLayout();
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      document.removeEventListener("keydown", this.onKeyDown);
      navigation.removeEventListener("swipestart", this.#cancelSheetSwipe, true);
      navigation.removeEventListener("swipecancel", this.#cancelSheetSwipe, true);
      navigation.classList.remove("isbf-topic-reading");
      posts.classList.remove("has-isbf-topic-reading");
    };
  });
  #cancelSheetSwipe = event => {
    event.preventDefault();
    event.stopImmediatePropagation();
  };
  // The navigation can survive a topic change while this outlet is recreated.
  #needsInitialCollapse = this.args.outletArgs.topicProgressExpanded;
  get isReadingTopic() {
    return isReadingTopic(this.args.outletArgs.topic);
  }
  get progressLabel() {
    const topic = this.args.outletArgs.topic;
    const controller = getOwner(this).lookup("controller:topic");
    return i18n("topic.timeline.replies_short", {
      current: topic.postStream.progressIndexOfPostId({
        id: controller.get("currentPostId"),
        post_number: topic.get("currentPost")
      }) || 1,
      total: topic.postStream.filteredPostsCount
    });
  }
  closeOnClickOutside(event) {
    if (this.modal.activeModal || event.target.closest?.(".select-kit-body, .fk-d-menu, .fk-d-menu-modal")) {
      return;
    }
    this.#closeProgress();
  }
  static {
    n(this.prototype, "closeOnClickOutside", [action]);
  }
  closeProgress() {
    this.#closeProgress();
    schedule("afterRender", () => {
      this.header?.querySelector(".isbf-topic-reading__toggle")?.focus();
    });
  }
  static {
    n(this.prototype, "closeProgress", [action]);
  }
  onKeyDown(event) {
    if (event.key !== "Escape" || event.defaultPrevented || !this.args.outletArgs.topicProgressExpanded || this.modal.activeModal || [...this.menu.registeredMenus].some(menu => menu.expanded)) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    this.closeProgress();
  }
  static {
    n(this.prototype, "onKeyDown", [action]);
  }
  onTogglePointerDown(event) {
    event.stopPropagation();
  }
  static {
    n(this.prototype, "onTogglePointerDown", [action]);
  }
  toggleProgress() {
    this.appEvents.trigger("topic:toggle-progress-expansion");
  }
  static {
    n(this.prototype, "toggleProgress", [action]);
  }
  #closeProgress() {
    if (this.header?.isConnected && this.args.outletArgs.topicProgressExpanded) {
      this.toggleProgress();
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.isReadingTopic}}
      <header
        class="isbf-topic-reading__heading"
        {{this.syncLayout
          @outletArgs.renderTimeline
          @outletArgs.topicProgressExpanded
        }}
        {{isbfCloseOnClickOutside
          this.closeOnClickOutside
          (hash
            targetSelector=".topic-navigation.isbf-topic-reading"
            secondaryTargetSelector=".isbf-topic-reading__toggle"
          )
        }}
      >
        <h2>{{i18n (themePrefix "isbf_v2.reading_progress")}}</h2>
        {{#if @outletArgs.topicProgressExpanded}}
          <DButton
            class="isbf-topic-reading__close btn-flat"
            @action={{this.closeProgress}}
            @icon="xmark"
            @title="close"
          />
        {{/if}}
      </header>
      {{#if this.header}}
        {{#in-element this.header insertBefore=null}}
          {{#if this.hasProgress}}
            {{! Exclude the detached trigger from native pointer dismissal before click. }}
            {{! eslint-disable ember/template-no-pointer-down-event-binding }}
            <DButton
              class="isbf-topic-reading__toggle"
              @action={{this.toggleProgress}}
              @ariaExpanded={{@outletArgs.topicProgressExpanded}}
              @translatedLabel={{this.progressLabel}}
              @translatedTitle={{i18n (themePrefix "isbf_v2.reading_progress")}}
              {{on "pointerdown" this.onTogglePointerDown}}
            />
            {{! eslint-enable ember/template-no-pointer-down-event-binding }}
          {{/if}}
        {{/in-element}}
      {{/if}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"isReadingTopic\"]],[[[1,\"  \"],[11,\"header\"],[24,0,\"isbf-topic-reading__heading\"],[4,[30,0,[\"syncLayout\"]],[[30,1,[\"renderTimeline\"]],[30,1,[\"topicProgressExpanded\"]]],null],[4,[32,0],[[30,0,[\"closeOnClickOutside\"]],[28,[32,1],null,[[\"targetSelector\",\"secondaryTargetSelector\"],[\".topic-navigation.isbf-topic-reading\",\".isbf-topic-reading__toggle\"]]]],null],[12],[1,\"\\n    \"],[10,\"h2\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.reading_progress\"],null]],null]],[13],[1,\"\\n\"],[41,[30,1,[\"topicProgressExpanded\"]],[[[1,\"      \"],[8,[32,4],[[24,0,\"isbf-topic-reading__close btn-flat\"]],[[\"@action\",\"@icon\",\"@title\"],[[30,0,[\"closeProgress\"]],\"xmark\",\"close\"]],null],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"],[41,[30,0,[\"header\"]],[[[40,[[[41,[30,0,[\"hasProgress\"]],[[[1,\"        \"],[8,[32,4],[[24,0,\"isbf-topic-reading__toggle\"],[4,[32,5],[\"pointerdown\",[30,0,[\"onTogglePointerDown\"]]],null]],[[\"@action\",\"@ariaExpanded\",\"@translatedLabel\",\"@translatedTitle\"],[[30,0,[\"toggleProgress\"]],[30,1,[\"topicProgressExpanded\"]],[30,0,[\"progressLabel\"]],[28,[32,2],[[28,[32,3],[\"isbf_v2.reading_progress\"],null]],null]]],null],[1,\"\\n\"]],[]],null]],[]],\"%cursor:0%\",[28,[31,2],[[30,0,[\"header\"]]],null],null]],[]],null]],[]],null]],[\"@outletArgs\"],[\"if\",\"in-element\",\"-in-el-null\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        isbfCloseOnClickOutside,
        hash,
        i18n,
        themePrefix,
        DButton,
        on
      }),
      "isStrictMode": true
    }), this);
  }
}
export class ISBFTopicReadingJump extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  get backIndex() {
    const topic = this.args.outletArgs.model;
    if (!isReadingTopic(topic) || !topic.last_read_post_number) {
      return 0;
    }
    const stream = topic.postStream;
    const lastRead = stream.stream.indexOf(topic.last_read_post_id) + 1;
    const controller = getOwner(this).lookup("controller:topic");
    const current = stream.progressIndexOfPostId({
      id: controller.get("currentPostId"),
      post_number: topic.get("currentPost")
    }) || 1;
    const total = stream.filteredPostsCount;
    return lastRead > 3 && lastRead > current && lastRead - current > 3 && total - lastRead > 1 ? lastRead : 0;
  }
  get showBack() {
    return this.args.outletArgs.fullscreen && this.backIndex > 0;
  }
  get showJump() {
    return isReadingTopic(this.args.outletArgs.model) && !this.args.outletArgs.fullscreen;
  }
  goBack() {
    if (this.backIndex) {
      getOwner(this).lookup("controller:topic").send("jumpToIndex", this.backIndex);
    }
  }
  static {
    n(this.prototype, "goBack", [action]);
  }
  jumpToPost() {
    this.appEvents.trigger("topic:keyboard-trigger", {
      type: "jump"
    });
  }
  static {
    n(this.prototype, "jumpToPost", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.showBack}}
      <DButton
        class="isbf-topic-reading__back btn-default"
        @action={{this.goBack}}
        @label="topic.timeline.back"
        @title="topic.timeline.back_description"
      />
    {{/if}}
    {{#if this.showJump}}
      <DButton
        class="isbf-topic-reading__jump"
        @action={{this.jumpToPost}}
        @label="topic.progress.jump_prompt"
      />
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"showBack\"]],[[[1,\"  \"],[8,[32,0],[[24,0,\"isbf-topic-reading__back btn-default\"]],[[\"@action\",\"@label\",\"@title\"],[[30,0,[\"goBack\"]],\"topic.timeline.back\",\"topic.timeline.back_description\"]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"showJump\"]],[[[1,\"  \"],[8,[32,0],[[24,0,\"isbf-topic-reading__jump\"]],[[\"@action\",\"@label\"],[[30,0,[\"jumpToPost\"]],\"topic.progress.jump_prompt\"]],null],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}