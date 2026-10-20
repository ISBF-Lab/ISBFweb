import { on } from "@ember/modifier";
import { themePrefix } from "virtual:theme";
import TopicListItem from "discourse/components/topic-list/item";
import TopicLink from "discourse/components/topic-list/topic-link";
import TopicStatus from "discourse/components/topic-status";
import getURL from "discourse/lib/get-url";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ISBFContinueReadingItem extends TopicListItem {
  get defaultAvatarUrl() {
    return getURL("/images/avatar.png");
  }

  get hasEssentialStatus() {
    const topic = this.args.topic;
    return (
      topic.closed || topic.archived || topic.invisible || topic.is_warning
    );
  }

  get hasUnread() {
    const topic = this.args.topic;
    return topic.get("is_nested_view")
      ? Boolean(topic.get("has_new_replies"))
      : topic.get("unread_posts") > 0;
  }

  get showCategory() {
    const category = this.args.topic.category;
    return (
      category &&
      (category.id !== this.site.uncategorized_category_id ||
        !this.siteSettings.suppress_uncategorized_badge)
    );
  }

  get unreadLabel() {
    const topic = this.args.topic;
    return topic.get("is_nested_view")
      ? i18n("topic.has_new_replies")
      : i18n("topic.unread_posts", { count: topic.get("unread_posts") });
  }

  <template>
    {{! eslint-disable ember/template-no-invalid-interactive }}
    <li
      class={{dConcatClass
        "isbf-continue-reading__item topic-list-item"
        (if @topic.visited "visited")
        (if @topic.unseen "unseen-topic")
        (if this.hasUnread "unread-posts")
        this.additionalClasses
      }}
      data-topic-id={{@topic.id}}
      style={{this.style}}
      ...attributes
      {{this.highlightIfNeeded}}
      {{on "click" this.click}}
      {{on "auxclick" this.click}}
    >
      {{#if @topic.creator.username}}
        <DUserLink
          class="isbf-continue-reading__avatar"
          @user={{@topic.creator}}
        >
          {{#if @topic.creator.avatar_template}}
            {{dAvatar @topic.creator imageSize="large" loading="lazy"}}
          {{else}}
            <img alt="" height="36" src={{this.defaultAvatarUrl}} width="36" />
          {{/if}}
        </DUserLink>
      {{else}}
        <span class="isbf-continue-reading__avatar">
          <img alt="" height="36" src={{this.defaultAvatarUrl}} width="36" />
        </span>
      {{/if}}

      <div class="isbf-continue-reading__body">
        <div class="isbf-continue-reading__title-row main-link">
          {{#if this.hasEssentialStatus}}
            <TopicStatus @context="topic-list" @topic={{@topic}} />
          {{/if}}
          <TopicLink
            class="isbf-continue-reading__title raw-topic-link"
            @topic={{@topic}}
            {{on "keydown" this.keyDown}}
            {{on "focus" this.onTitleFocus}}
            {{on "blur" this.onTitleBlur}}
          />
          {{#if this.hasUnread}}
            <span
              class="isbf-continue-reading__unread"
              title={{this.unreadLabel}}
            >
              <span class="sr-only">{{this.unreadLabel}}</span>
            </span>
          {{/if}}
          {{#if @topic.unseen}}
            <span class="sr-only">{{i18n "topic.new"}}</span>
          {{/if}}
        </div>

        <div class="isbf-continue-reading__metadata">
          {{#if this.showCategory}}
            {{dCategoryLink @topic.category}}
            <span aria-hidden="true">·</span>
          {{/if}}
          <a
            class="isbf-continue-reading__time post-activity"
            href={{@topic.lastPostUrl}}
            title={{@topic.bumpedAtTitle}}
          >
            {{dFormatDate @topic.bumpedAt format="tiny" noTitle="true"}}
          </a>
        </div>

        <a
          aria-label={{i18n "topic.reply_count_link" count=@topic.replyCount}}
          class="isbf-continue-reading__replies badge-posts"
          href={{@topic.firstPostUrl}}
        >
          {{dIcon "comment"}}
          {{i18n
            (themePrefix "isbf_v2.continue_reading.replies")
            count=@topic.replyCount
          }}
        </a>
      </div>
    </li>
  </template>
}
