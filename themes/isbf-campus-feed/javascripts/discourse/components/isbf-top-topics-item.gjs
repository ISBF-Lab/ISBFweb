import { on } from "@ember/modifier";
import { themePrefix } from "virtual:theme";
import TopicListItem from "discourse/components/topic-list/item";
import TopicLink from "discourse/components/topic-list/topic-link";
import TopicStatus from "discourse/components/topic-status";
import { localizedTopicTitle } from "discourse/lib/topic-display-title";
import DUserLink from "discourse/ui-kit/d-user-link";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { i18n } from "discourse-i18n";
import { optionalTopicTitle } from "../lib/optional-topic-title";
import { postPreview } from "../lib/post-preview";
import { unavailableTitleContent } from "../lib/topic-display-title";

export default class ISBFTopTopicsItem extends TopicListItem {
  get additionalClasses() {
    return super.additionalClasses.filter((name) => name !== "isbf-v2-topic");
  }

  get rank() {
    return this.args.index + 1;
  }

  get leading() {
    return this.rank <= 3;
  }

  get summary() {
    const topic = this.args.topic;
    if (
      unavailableTitleContent(topic) ||
      (!localizedTopicTitle(topic) && !optionalTopicTitle(topic.title).trim())
    ) {
      return "";
    }
    return postPreview(topic.excerpt).text;
  }

  get showCategory() {
    const category = this.args.topic.category;
    return (
      category &&
      (category.id !== this.site.uncategorized_category_id ||
        !this.siteSettings.suppress_uncategorized_badge)
    );
  }

  get unread() {
    const topic = this.args.topic;
    return topic.is_nested_view
      ? Boolean(topic.has_new_replies)
      : topic.unread_posts > 0;
  }

  get unreadLabel() {
    return this.args.topic.is_nested_view
      ? i18n("topic.has_new_replies")
      : i18n("topic.unread_posts", {
          count: this.args.topic.unread_posts,
        });
  }

  <template>
    {{! eslint-disable ember/template-no-invalid-interactive }}
    <tr
      class={{dConcatClass
        "isbf-top-topics__item topic-list-item"
        (if @topic.visited "visited")
        (if @topic.unseen "unseen-topic")
        (if this.unread "unread-posts")
        this.additionalClasses
      }}
      data-topic-id={{@topic.id}}
      style={{this.style}}
      {{this.highlightIfNeeded}}
      {{on "click" this.click}}
      {{on "auxclick" this.click}}
    >
      <td class="isbf-top-topics__cell topic-list-data">
        <span
          aria-label={{i18n
            (themePrefix "isbf_v2.top_topics.rank")
            rank=this.rank
          }}
          class={{dConcatClass
            "isbf-top-topics__rank"
            (if this.leading "is-leading")
          }}
        >{{this.rank}}</span>
        <div class="isbf-top-topics__body">
          <div class="isbf-top-topics__title-row main-link">
            <TopicStatus @context="topic-list" @topic={{@topic}} />
            <TopicLink
              class="isbf-top-topics__title raw-topic-link"
              @topic={{@topic}}
              {{on "keydown" this.keyDown}}
              {{on "focus" this.onTitleFocus}}
              {{on "blur" this.onTitleBlur}}
            />
            {{#if this.unread}}
              <span class="isbf-top-topics__unread" title={{this.unreadLabel}}>
                <span class="sr-only">{{this.unreadLabel}}</span>
              </span>
            {{/if}}
            {{#if @topic.unseen}}<span class="sr-only">{{i18n
                  "topic.new"
                }}</span>{{/if}}
          </div>
          {{#if this.summary}}
            <p class="isbf-top-topics__summary">{{this.summary}}</p>
          {{/if}}
          <div class="isbf-top-topics__metadata">
            {{#if @topic.creator.username}}
              <DUserLink
                class="isbf-top-topics__author"
                @user={{@topic.creator}}
              >
                {{@topic.creator.username}}
              </DUserLink>
            {{/if}}
            {{#if this.showCategory}}
              {{dCategoryLink @topic.category}}
            {{/if}}
            <a
              class="isbf-top-topics__time post-activity"
              href={{@topic.lastPostUrl}}
              title={{@topic.bumpedAtTitle}}
            >{{dFormatDate @topic.bumpedAt format="tiny" noTitle="true"}}</a>
          </div>
          <div class="isbf-top-topics__stats">
            <span class="isbf-top-topics__stat" data-stat="views">
              {{dIcon "eye"}}
              <span aria-hidden="true">{{dNumber @topic.views}}</span>
              <span class="sr-only">{{i18n
                  (themePrefix "isbf_v2.top_topics.views")
                  count=@topic.views
                }}</span>
            </span>
            <a
              class="isbf-top-topics__stat badge-posts"
              data-stat="replies"
              href={{@topic.firstPostUrl}}
            >
              {{dIcon "comment"}}
              <span aria-hidden="true">{{dNumber @topic.replyCount}}</span>
              <span class="sr-only">{{i18n
                  (themePrefix "isbf_v2.top_topics.replies")
                  count=@topic.replyCount
                }}</span>
            </a>
            <span class="isbf-top-topics__stat" data-stat="likes">
              {{dIcon "heart"}}
              <span aria-hidden="true">{{dNumber @topic.like_count}}</span>
              <span class="sr-only">{{i18n
                  (themePrefix "isbf_v2.top_topics.likes")
                  count=@topic.like_count
                }}</span>
            </span>
          </div>
        </div>
      </td>
    </tr>
  </template>
}
