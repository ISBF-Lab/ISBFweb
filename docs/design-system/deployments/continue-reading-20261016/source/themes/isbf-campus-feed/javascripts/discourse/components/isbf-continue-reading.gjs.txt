import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import UserTip from "discourse/components/user-tip";
import EmbedMode from "discourse/lib/embed-mode";
import { eq, gt } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import ISBFContinueReadingFooter from "./isbf-continue-reading-footer";
import ISBFContinueReadingItem from "./isbf-continue-reading-item";

export default class ISBFContinueReading extends Component {
  @service moreTopicsTabs;
  @service router;

  get topic() {
    return this.args.outletArgs.topic;
  }

  get listContext() {
    return this.moreTopicsTabs.selectedTab?.id === "suggested-topics"
      ? "suggested"
      : "related";
  }

  get shouldRender() {
    return (
      !EmbedMode.enabled &&
      /^\/t\//.test(this.router.currentURL ?? "") &&
      this.topic.archetype === "regular" &&
      this.topics?.length > 0
    );
  }

  get sourceTitle() {
    return this.listContext === "suggested"
      ? i18n(themePrefix("isbf_v2.continue_reading.suggested"))
      : i18n(themePrefix("isbf_v2.continue_reading.related"));
  }

  get topics() {
    switch (this.moreTopicsTabs.selectedTab?.id) {
      case "suggested-topics":
        return this.topic.suggestedTopics;
      case "related-topics":
        return this.topic.relatedTopics;
      default:
        return null;
    }
  }

  <template>
    {{#if this.shouldRender}}
      <section
        aria-labelledby="isbf-continue-reading-title"
        class="isbf-continue-reading"
        data-source={{this.listContext}}
        id={{this.moreTopicsTabs.selectedTab.id}}
        ...attributes
      >
        {{#if (eq this.listContext "suggested")}}
          <UserTip
            @contentText={{i18n "user_tips.suggested_topics.content"}}
            @id="suggested_topics"
            @placement="top-start"
            @priority={{700}}
            @titleText={{i18n "user_tips.suggested_topics.title"}}
          />
        {{/if}}

        <header class="isbf-continue-reading__header">
          <h3
            class="isbf-continue-reading__heading"
            id="isbf-continue-reading-title"
          >
            {{i18n (themePrefix "isbf_v2.continue_reading.title")}}
          </h3>
          <span
            class="isbf-continue-reading__source"
          >{{this.sourceTitle}}</span>
        </header>

        {{#if (gt this.moreTopicsTabs.tabs.length 1)}}
          <nav
            aria-label={{i18n (themePrefix "isbf_v2.continue_reading.sources")}}
            class="isbf-continue-reading__tabs"
          >
            {{#each this.moreTopicsTabs.tabs as |tab|}}
              <DButton
                aria-pressed={{this.moreTopicsTabs.isActiveTab tab}}
                class={{dConcatClass
                  "isbf-continue-reading__tab"
                  (if (this.moreTopicsTabs.isActiveTab tab) "is-active")
                }}
                @action={{fn this.moreTopicsTabs.selectTab tab}}
                @translatedLabel={{tab.name}}
              />
            {{/each}}
          </nav>
        {{/if}}

        <ul class="isbf-continue-reading__list" role="list">
          {{#each this.topics key="id" as |topic index|}}
            <ISBFContinueReadingItem
              @index={{index}}
              @listContext={{this.listContext}}
              @topic={{topic}}
            />
          {{/each}}
        </ul>

        {{#if this.topic.suggestedTopics.length}}
          <ISBFContinueReadingFooter @topic={{this.topic}} />
        {{/if}}
      </section>
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
