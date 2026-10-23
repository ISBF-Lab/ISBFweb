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

function isReadingTopic(topic) {
  return (
    !EmbedMode.enabled &&
    topic?.archetype === "regular" &&
    !topic.is_nested_view
  );
}

export default class ISBFTopicReading extends Component {
  @service appEvents;
  @service menu;
  @service modal;

  @tracked hasProgress = false;
  @tracked header = null;

  syncLayout = modifier((element) => {
    const navigation = element.closest(".topic-navigation");
    const posts = navigation?.closest(".container.posts, .nested-view");
    const header = document.querySelector(
      ".isbf-v2-shell--topic-feed-style .isbf-v2-page-header"
    );
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
      const hasProgress = Boolean(
        area || navigation.querySelector("#topic-progress:not(.hidden)")
      );
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
      navigation.removeEventListener(
        "swipestart",
        this.#cancelSheetSwipe,
        true
      );
      navigation.removeEventListener(
        "swipecancel",
        this.#cancelSheetSwipe,
        true
      );
      navigation.classList.remove("isbf-topic-reading");
      posts.classList.remove("has-isbf-topic-reading");
    };
  });

  #cancelSheetSwipe = (event) => {
    event.preventDefault();
    event.stopImmediatePropagation();
  };

  // The navigation can survive a topic change while this outlet is recreated.
  #needsInitialCollapse = this.args.outletArgs.topicProgressExpanded;

  get isReadingTopic() {
    return (
      isReadingTopic(this.args.outletArgs.topic) ||
      Boolean(this.args.outletArgs.navigation)
    );
  }

  get progressLabel() {
    if (this.args.outletArgs.navigation) {
      return this.args.outletArgs.navigation.label();
    }
    const topic = this.args.outletArgs.topic;
    const controller = getOwner(this).lookup("controller:topic");
    return i18n("topic.timeline.replies_short", {
      current:
        topic.postStream.progressIndexOfPostId({
          id: controller.get("currentPostId"),
          post_number: topic.get("currentPost"),
        }) || 1,
      total: topic.postStream.filteredPostsCount,
    });
  }

  @action
  closeOnClickOutside(event) {
    if (
      this.modal.activeModal ||
      event.target.closest?.(".select-kit-body, .fk-d-menu, .fk-d-menu-modal")
    ) {
      return;
    }
    this.#closeProgress();
  }

  @action
  closeProgress() {
    this.#closeProgress();
    schedule("afterRender", () => {
      this.header?.querySelector(".isbf-topic-reading__toggle")?.focus();
    });
  }

  @action
  onKeyDown(event) {
    if (
      event.key !== "Escape" ||
      event.defaultPrevented ||
      !this.args.outletArgs.topicProgressExpanded ||
      this.modal.activeModal ||
      [...this.menu.registeredMenus].some((menu) => menu.expanded)
    ) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    this.closeProgress();
  }

  @action
  onTogglePointerDown(event) {
    event.stopPropagation();
  }

  @action
  toggleProgress() {
    this.appEvents.trigger("topic:toggle-progress-expansion");
  }

  #closeProgress() {
    if (
      this.header?.isConnected &&
      this.args.outletArgs.topicProgressExpanded
    ) {
      this.toggleProgress();
    }
  }

  <template>
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
  </template>
}

export class ISBFTopicReadingJump extends Component {
  @service appEvents;

  get backIndex() {
    if (this.args.outletArgs.navigation) {
      const navigation = this.args.outletArgs.navigation;
      const index = navigation.lastReadIndex;
      return index > navigation.currentIndex + 3 &&
        index > 3 &&
        navigation.total - index > 1
        ? index
        : 0;
    }
    const topic = this.args.outletArgs.model;
    if (!isReadingTopic(topic) || !topic.last_read_post_number) {
      return 0;
    }
    const stream = topic.postStream;
    const lastRead = stream.stream.indexOf(topic.last_read_post_id) + 1;
    const controller = getOwner(this).lookup("controller:topic");
    const current =
      stream.progressIndexOfPostId({
        id: controller.get("currentPostId"),
        post_number: topic.get("currentPost"),
      }) || 1;
    const total = stream.filteredPostsCount;

    return lastRead > 3 &&
      lastRead > current &&
      lastRead - current > 3 &&
      total - lastRead > 1
      ? lastRead
      : 0;
  }

  get showBack() {
    return this.args.outletArgs.fullscreen && this.backIndex > 0;
  }

  get showJump() {
    return (
      (isReadingTopic(this.args.outletArgs.model) ||
        this.args.outletArgs.navigation) &&
      !this.args.outletArgs.fullscreen
    );
  }

  @action
  goBack() {
    if (this.args.outletArgs.navigation) {
      this.args.outletArgs.navigation.jumpToPostNumber(
        this.args.outletArgs.model.last_read_post_number
      );
      return;
    }
    if (this.backIndex) {
      getOwner(this)
        .lookup("controller:topic")
        .send("jumpToIndex", this.backIndex);
    }
  }

  @action
  jumpToPost() {
    this.appEvents.trigger("topic:keyboard-trigger", { type: "jump" });
  }

  <template>
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
  </template>
}
