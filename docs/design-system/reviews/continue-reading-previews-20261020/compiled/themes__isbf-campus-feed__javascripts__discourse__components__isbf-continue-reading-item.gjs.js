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
import { optionalTopicTitle } from "../lib/optional-topic-title";
import ISBFPostPreview from "./isbf-post-preview";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
export default class ISBFContinueReadingItem extends TopicListItem {
  get defaultAvatarUrl() {
    return getURL("/images/avatar.png");
  }
  get hasEssentialStatus() {
    const topic = this.args.topic;
    return topic.closed || topic.archived || topic.invisible || topic.is_warning;
  }
  get hasUnread() {
    const topic = this.args.topic;
    return topic.get("is_nested_view") ? Boolean(topic.get("has_new_replies")) : topic.get("unread_posts") > 0;
  }
  get previewDisabled() {
    return this.args.topic.hidden || this.args.topic.deleted;
  }
  get titled() {
    return Boolean(optionalTopicTitle(this.args.topic.title).trim());
  }
  get titleUrl() {
    const topic = this.args.topic;
    return topic.linked_post_number ? topic.urlForPostNumber(topic.linked_post_number) : topic.lastUnreadUrl;
  }
  get showCategory() {
    const category = this.args.topic.category;
    return category && (category.id !== this.site.uncategorized_category_id || !this.siteSettings.suppress_uncategorized_badge);
  }
  get unreadLabel() {
    const topic = this.args.topic;
    return topic.get("is_nested_view") ? i18n("topic.has_new_replies") : i18n("topic.unread_posts", {
      count: topic.get("unread_posts")
    });
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
          {{#if this.titled}}
            <TopicLink
              class="isbf-continue-reading__title raw-topic-link"
              @topic={{@topic}}
              {{on "keydown" this.keyDown}}
              {{on "focus" this.onTitleFocus}}
              {{on "blur" this.onTitleBlur}}
            />
          {{else}}
            <ISBFPostPreview
              class="isbf-continue-reading__title title raw-topic-link"
              data-topic-id={{@topic.id}}
              @disabled={{this.previewDisabled}}
              @excerpt={{@topic.excerpt}}
              @href={{this.titleUrl}}
              @postNumber={{1}}
              @title={{@topic.title}}
              @topicId={{@topic.id}}
              @variant="continue-reading"
              {{on "keydown" this.keyDown}}
              {{on "focus" this.onTitleFocus}}
              {{on "blur" this.onTitleBlur}}
            >
              {{#if @topic.visited}}
                <span class="sr-only">&nbsp;{{i18n "topic.sr_read"}}</span>
              {{/if}}
            </ISBFPostPreview>
          {{/if}}
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
    */
    {
      "id": null,
      "block": "[[[11,\"li\"],[16,0,[28,[32,0],[\"isbf-continue-reading__item topic-list-item\",[52,[30,1,[\"visited\"]],\"visited\"],[52,[30,1,[\"unseen\"]],\"unseen-topic\"],[52,[30,0,[\"hasUnread\"]],\"unread-posts\"],[30,0,[\"additionalClasses\"]]],null]],[16,\"data-topic-id\",[30,1,[\"id\"]]],[16,5,[30,0,[\"style\"]]],[17,2],[4,[30,0,[\"highlightIfNeeded\"]],null,null],[4,[32,1],[\"click\",[30,0,[\"click\"]]],null],[4,[32,1],[\"auxclick\",[30,0,[\"click\"]]],null],[12],[1,\"\\n\"],[41,[30,1,[\"creator\",\"username\"]],[[[1,\"    \"],[8,[32,2],[[24,0,\"isbf-continue-reading__avatar\"]],[[\"@user\"],[[30,1,[\"creator\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"creator\",\"avatar_template\"]],[[[1,\"        \"],[1,[28,[32,3],[[30,1,[\"creator\"]]],[[\"imageSize\",\"loading\"],[\"large\",\"lazy\"]]]],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"36\"],[15,\"src\",[30,0,[\"defaultAvatarUrl\"]]],[14,\"width\",\"36\"],[12],[13],[1,\"\\n\"]],[]]],[1,\"    \"]],[]]]]],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,1],[14,0,\"isbf-continue-reading__avatar\"],[12],[1,\"\\n      \"],[10,\"img\"],[14,\"alt\",\"\"],[14,\"height\",\"36\"],[15,\"src\",[30,0,[\"defaultAvatarUrl\"]]],[14,\"width\",\"36\"],[12],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]]],[1,\"\\n  \"],[10,0],[14,0,\"isbf-continue-reading__body\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-continue-reading__title-row main-link\"],[12],[1,\"\\n\"],[41,[30,0,[\"hasEssentialStatus\"]],[[[1,\"        \"],[8,[32,4],null,[[\"@context\",\"@topic\"],[\"topic-list\",[30,1]]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"titled\"]],[[[1,\"        \"],[8,[32,5],[[24,0,\"isbf-continue-reading__title raw-topic-link\"],[4,[32,1],[\"keydown\",[30,0,[\"keyDown\"]]],null],[4,[32,1],[\"focus\",[30,0,[\"onTitleFocus\"]]],null],[4,[32,1],[\"blur\",[30,0,[\"onTitleBlur\"]]],null]],[[\"@topic\"],[[30,1]]],null],[1,\"\\n\"]],[]],[[[1,\"        \"],[8,[32,6],[[24,0,\"isbf-continue-reading__title title raw-topic-link\"],[16,\"data-topic-id\",[30,1,[\"id\"]]],[4,[32,1],[\"keydown\",[30,0,[\"keyDown\"]]],null],[4,[32,1],[\"focus\",[30,0,[\"onTitleFocus\"]]],null],[4,[32,1],[\"blur\",[30,0,[\"onTitleBlur\"]]],null]],[[\"@disabled\",\"@excerpt\",\"@href\",\"@postNumber\",\"@title\",\"@topicId\",\"@variant\"],[[30,0,[\"previewDisabled\"]],[30,1,[\"excerpt\"]],[30,0,[\"titleUrl\"]],1,[30,1,[\"title\"]],[30,1,[\"id\"]],\"continue-reading\"]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"visited\"]],[[[1,\"            \"],[10,1],[14,0,\"sr-only\"],[12],[1,\" \"],[1,[28,[32,7],[\"topic.sr_read\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"]],[]]]]],[1,\"\\n\"]],[]]],[41,[30,0,[\"hasUnread\"]],[[[1,\"        \"],[10,1],[14,0,\"isbf-continue-reading__unread\"],[15,\"title\",[30,0,[\"unreadLabel\"]]],[12],[1,\"\\n          \"],[10,1],[14,0,\"sr-only\"],[12],[1,[30,0,[\"unreadLabel\"]]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[41,[30,1,[\"unseen\"]],[[[1,\"        \"],[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,7],[\"topic.new\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n\\n    \"],[10,0],[14,0,\"isbf-continue-reading__metadata\"],[12],[1,\"\\n\"],[41,[30,0,[\"showCategory\"]],[[[1,\"        \"],[1,[28,[32,8],[[30,1,[\"category\"]]],null]],[1,\"\\n        \"],[10,1],[14,\"aria-hidden\",\"true\"],[12],[1,\"·\"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,3],[14,0,\"isbf-continue-reading__time post-activity\"],[15,6,[30,1,[\"lastPostUrl\"]]],[15,\"title\",[30,1,[\"bumpedAtTitle\"]]],[12],[1,\"\\n        \"],[1,[28,[32,9],[[30,1,[\"bumpedAt\"]]],[[\"format\",\"noTitle\"],[\"tiny\",\"true\"]]]],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n    \"],[10,3],[15,\"aria-label\",[28,[32,7],[\"topic.reply_count_link\"],[[\"count\"],[[30,1,[\"replyCount\"]]]]]],[14,0,\"isbf-continue-reading__replies badge-posts\"],[15,6,[30,1,[\"firstPostUrl\"]]],[12],[1,\"\\n      \"],[1,[28,[32,10],[\"comment\"],null]],[1,\"\\n      \"],[1,[28,[32,7],[[28,[32,11],[\"isbf_v2.continue_reading.replies\"],null]],[[\"count\"],[[30,1,[\"replyCount\"]]]]]],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@topic\",\"&attrs\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        on,
        DUserLink,
        dAvatar,
        TopicStatus,
        TopicLink,
        ISBFPostPreview,
        i18n,
        dCategoryLink,
        dFormatDate,
        dIcon,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}