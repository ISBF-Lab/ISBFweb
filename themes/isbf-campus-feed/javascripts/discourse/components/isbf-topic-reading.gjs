import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { themePrefix } from "virtual:theme";
import EmbedMode from "discourse/lib/embed-mode";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

function isReadingTopic(topic) {
  return (
    !EmbedMode.enabled &&
    topic?.archetype === "regular" &&
    !topic.is_nested_view
  );
}

export default class ISBFTopicReading extends Component {
  @service appEvents;

  @tracked hasProgress = false;
  @tracked header = null;
  @tracked inRail = false;

  syncLayout = modifier((element) => {
    const navigation = element.closest(".topic-navigation");
    const posts = navigation.closest(".container.posts");
    const rail = document.querySelector(".isbf-v2-rail");
    let frame;

    const update = () => {
      navigation.classList.add("isbf-topic-reading");
      posts.classList.add("has-isbf-topic-reading");
      this.header = document.querySelector(".isbf-v2-page-header");
      const area = navigation.querySelector(".timeline-scrollarea-wrapper");
      this.inRail = Boolean(
        rail &&
        area &&
        !navigation.classList.contains("topic-progress-expanded") &&
        getComputedStyle(navigation).position === "fixed"
      );
      this.hasProgress = Boolean(
        area || navigation.querySelector("#topic-progress:not(.hidden)")
      );
      rail?.classList.toggle("has-topic-reading", this.inRail);
      rail?.style.setProperty(
        "--isbf-topic-reading-height",
        `${this.inRail ? navigation.getBoundingClientRect().height : 0}px`
      );
    };
    const schedule = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(update);
    };
    const observer = new ResizeObserver(schedule);
    observer.observe(navigation);
    schedule();

    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      navigation.classList.remove("isbf-topic-reading");
      posts.classList.remove("has-isbf-topic-reading");
      rail?.classList.remove("has-topic-reading");
      rail?.style.removeProperty("--isbf-topic-reading-height");
    };
  });

  get isReadingTopic() {
    return isReadingTopic(this.args.outletArgs.topic);
  }

  get progressLabel() {
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
  toggleProgress() {
    this.appEvents.trigger("topic:toggle-progress-expansion");
  }

  <template>
    {{#if this.isReadingTopic}}
      <header
        class="isbf-topic-reading__heading"
        {{this.syncLayout
          @outletArgs.renderTimeline
          @outletArgs.topicProgressExpanded
        }}
      >
        <h2>{{i18n (themePrefix "isbf_v2.reading_progress")}}</h2>
        {{#if @outletArgs.topicProgressExpanded}}
          <DButton
            class="btn-flat"
            @action={{this.toggleProgress}}
            @icon="xmark"
            @title="close"
          />
        {{/if}}
      </header>
      {{#if this.header}}
        {{#in-element this.header insertBefore=null}}
          {{#if this.hasProgress}}
            {{#unless this.inRail}}
              <DButton
                class="isbf-topic-reading__toggle"
                @action={{this.toggleProgress}}
                @ariaExpanded={{@outletArgs.topicProgressExpanded}}
                @translatedLabel={{this.progressLabel}}
                @translatedTitle={{i18n
                  (themePrefix "isbf_v2.reading_progress")
                }}
              />
            {{/unless}}
          {{/if}}
        {{/in-element}}
      {{/if}}
    {{/if}}
  </template>
}

export class ISBFTopicReadingJump extends Component {
  @service appEvents;

  get showJump() {
    return (
      isReadingTopic(this.args.outletArgs.model) &&
      !this.args.outletArgs.fullscreen
    );
  }

  @action
  jumpToPost() {
    this.appEvents.trigger("topic:keyboard-trigger", { type: "jump" });
  }

  <template>
    {{#if this.showJump}}
      <DButton
        class="isbf-topic-reading__jump"
        @action={{this.jumpToPost}}
        @label="topic.progress.jump_prompt"
      />
    {{/if}}
  </template>
}
