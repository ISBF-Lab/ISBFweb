import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import PluginOutlet from "discourse/components/plugin-outlet";
import { actionDescriptionHtml } from "discourse/components/post-action-description";
import TopicAdminMenu from "discourse/components/topic-admin-menu";
import TopicContentLanguagePreferences from "discourse/components/topic-content-language-preferences";
import UserTip from "discourse/components/user-tip";
import lazyHash from "discourse/helpers/lazy-hash";
import topicFeaturedLink from "discourse/helpers/topic-featured-link";
import { bind, debounce } from "discourse/lib/decorators";
import domUtils from "discourse/lib/dom-utils";
import { headerOffset } from "discourse/lib/offset-calculator";
import TopicNotificationsButton from "discourse/select-kit/components/topic-notifications-button";
import { and, not, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dAgeWithTooltip from "discourse/ui-kit/helpers/d-age-with-tooltip";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dDiscourseTags from "discourse/ui-kit/helpers/d-discourse-tags";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import BackButton from "./back-button";
import Scroller from "./scroller";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export const SCROLLER_HEIGHT = 50;
const DEFAULT_MIN_SCROLLAREA_HEIGHT = 170;
const DEFAULT_MAX_SCROLLAREA_HEIGHT = 300;
const LAST_READ_HEIGHT = 20;
let desktopMinScrollAreaHeight = DEFAULT_MIN_SCROLLAREA_HEIGHT;
let desktopMaxScrollAreaHeight = DEFAULT_MAX_SCROLLAREA_HEIGHT;
export function setDesktopScrollAreaHeight(height = {
  min: DEFAULT_MIN_SCROLLAREA_HEIGHT,
  max: DEFAULT_MAX_SCROLLAREA_HEIGHT
}) {
  desktopMinScrollAreaHeight = height.min;
  desktopMaxScrollAreaHeight = height.max;
}
export function timelineDate(date) {
  const fmt = date.getFullYear() === new Date().getFullYear() ? "long_no_year_no_time" : "timeline_date";
  return moment(date).format(i18n(`dates.${fmt}`));
}
export default class TopicTimelineScrollArea extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "site", [service]);
  }
  #site = (i(this, "site"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
  static {
    g(this.prototype, "composer", [service]);
  }
  #composer = (i(this, "composer"), void 0);
  static {
    g(this.prototype, "showButton", [tracked], function () {
      return false;
    });
  }
  #showButton = (i(this, "showButton"), void 0);
  static {
    g(this.prototype, "current", [tracked]);
  }
  #current = (i(this, "current"), void 0);
  static {
    g(this.prototype, "percentage", [tracked], function () {
      return this._percentFor(this.args.model, this.args.enteredIndex);
    });
  }
  #percentage = (i(this, "percentage"), void 0);
  static {
    g(this.prototype, "total", [tracked]);
  }
  #total = (i(this, "total"), void 0);
  static {
    g(this.prototype, "date", [tracked]);
  }
  #date = (i(this, "date"), void 0);
  static {
    g(this.prototype, "lastReadPercentage", [tracked], function () {
      return null;
    });
  }
  #lastReadPercentage = (i(this, "lastReadPercentage"), void 0);
  static {
    g(this.prototype, "lastRead", [tracked]);
  }
  #lastRead = (i(this, "lastRead"), void 0);
  static {
    g(this.prototype, "lastReadTop", [tracked]);
  }
  #lastReadTop = (i(this, "lastReadTop"), void 0);
  static {
    g(this.prototype, "before", [tracked]);
  }
  #before = (i(this, "before"), void 0);
  static {
    g(this.prototype, "after", [tracked]);
  }
  #after = (i(this, "after"), void 0);
  static {
    g(this.prototype, "timelineScrollareaStyle", [tracked]);
  }
  #timelineScrollareaStyle = (i(this, "timelineScrollareaStyle"), void 0);
  static {
    g(this.prototype, "dragging", [tracked], function () {
      return false;
    });
  }
  #dragging = (i(this, "dragging"), void 0);
  static {
    g(this.prototype, "excerpt", [tracked], function () {
      return "";
    });
  }
  #excerpt = (i(this, "excerpt"), void 0);
  intersectionObserver = null;
  scrollareaElement = null;
  scrollerElement = null;
  dragOffset = null;
  constructor() {
    super(...arguments);
    if (this.site.desktopView || this.args.navigation) {
      // listen for scrolling event to update timeline
      this.appEvents.on(this.scrollEvent, this.postScrolled);
      // listen for composer sizing changes to update timeline
      this.appEvents.on("composer:opened", this.calculatePosition);
      this.appEvents.on("composer:resized", this.calculatePosition);
      this.appEvents.on("composer:closed", this.calculatePosition);
      this.appEvents.on("composer:preview-toggled", this.calculatePosition);
    }
    this.intersectionObserver = new IntersectionObserver(entries => {
      for (const entry of entries) {
        const bounds = entry.boundingClientRect;
        if (entry.target.id === "topic-bottom") {
          this.topicBottom = bounds.y + window.scrollY;
        } else {
          this.topicTop = bounds.y + window.scrollY;
        }
      }
    });
    // The timeline is usually rendered on a topic page where both of these
    // anchors exist. When it's rendered outside of that context (for example,
    // a modal opened from a floating composer on a non-topic route), they
    // may be absent — skip observing rather than crashing.
    const elements = [document.querySelector(".container.posts"), document.querySelector("#topic-bottom")].filter(Boolean);
    for (let i = 0; i < elements.length; i++) {
      this.intersectionObserver.observe(elements[i]);
    }
    this.calculatePosition();
    this.dockCheck();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    if (this.site.desktopView || this.args.navigation) {
      this.intersectionObserver?.disconnect();
      this.intersectionObserver = null;
      this.appEvents.off("composer:opened", this.calculatePosition);
      this.appEvents.off("composer:resized", this.calculatePosition);
      this.appEvents.off("composer:closed", this.calculatePosition);
      this.appEvents.off("composer:preview-toggled", this.calculatePosition);
      this.appEvents.off(this.scrollEvent, this.postScrolled);
    }
  }
  get displaySummary() {
    return !this.args.navigation && this.siteSettings.summary_timeline_button && !this.args.fullScreen && this.args.model.has_summary && !this.args.model.postStream.summary;
  }
  get displayTimeLineScrollArea() {
    if (this.args.navigation) {
      return this.total > 0;
    }
    if (this.site.mobileView) {
      return true;
    }
    if (this.total === 1) {
      const postsWrapper = document.querySelector(".posts-wrapper");
      if (postsWrapper && postsWrapper.offsetHeight < 1000) {
        return false;
      }
    }
    return true;
  }
  get scrollEvent() {
    return this.args.navigation ? "topic:group-scrolled" : "topic:current-post-scrolled";
  }
  get navigationLabel() {
    return this.args.navigation?.label(this.current);
  }
  get canCreatePost() {
    return this.args.model.details?.can_create_post;
  }
  get showTimelineControls() {
    return !this.args.fullscreen && (this.currentUser || this.args.model.has_localized_content);
  }
  get topicTitle() {
    return trustHTML(this.site.mobileView ? this.args.model.fancyTitle : "");
  }
  get showTags() {
    return this.siteSettings.tagging_enabled && this.args.model.tags?.length > 0;
  }
  get style() {
    return trustHTML(`height: ${this.scrollareaHeight}px`);
  }
  get beforePadding() {
    return trustHTML(`height: ${this.before}px`);
  }
  get afterPadding() {
    return trustHTML(`height: ${this.after}px`);
  }
  get showDockedButton() {
    return this.site.desktopView && this.hasBackPosition && !this.showButton;
  }
  get hasBackPosition() {
    return this.lastRead && this.lastRead > 3 && this.lastRead > this.current && Math.abs(this.lastRead - this.current) > 3 && Math.abs(this.lastRead - this.total) > 1 && this.lastRead !== this.total;
  }
  get lastReadStyle() {
    return trustHTML(`height: ${LAST_READ_HEIGHT}px; top: ${this.topPosition}px`);
  }
  get topPosition() {
    const bottom = this.scrollareaHeight - LAST_READ_HEIGHT / 2;
    return this.lastReadTop > bottom ? bottom : this.lastReadTop;
  }
  get scrollareaHeight() {
    const composerHeight = this.composer.isPreviewActive ? document.getElementById("reply-control")?.offsetHeight || 0 : 0;
    const headerHeight = document.querySelector(".d-header")?.offsetHeight || 0;
    // scrollarea takes up about half of the timeline's height
    const availableHeight = (window.innerHeight - composerHeight - headerHeight) / 2;
    const minHeight = this.site.mobileView ? DEFAULT_MIN_SCROLLAREA_HEIGHT : this.composer.isPreviewActive ? desktopMinScrollAreaHeight : DEFAULT_MIN_SCROLLAREA_HEIGHT;
    const maxHeight = this.site.mobileView ? DEFAULT_MAX_SCROLLAREA_HEIGHT : this.composer.isPreviewActive ? desktopMaxScrollAreaHeight : DEFAULT_MAX_SCROLLAREA_HEIGHT;
    return Math.max(minHeight, Math.min(availableHeight, maxHeight));
  }
  get startDate() {
    return timelineDate(this.args.model.createdAt);
  }
  get nowDateOptions() {
    return {
      customTitle: i18n("topic_entrance.jump_bottom_button_title"),
      addAgo: true,
      defaultFormat: timelineDate
    };
  }
  get nowDate() {
    return this.args.model.get("last_posted_at") || this.args.model.get("created_at");
  }
  get lastReadHeight() {
    return Math.round(this.lastReadPercentage * this.scrollareaHeight);
  }
  calculatePosition() {
    this.timelineScrollareaStyle = trustHTML(`height: ${this.scrollareaHeight}px`);
    const topic = this.args.model;
    const postStream = topic.postStream;
    this.total = this.args.navigation?.total ?? postStream.filteredPostsCount;
    this.scrollPosition = this.clamp(Math.floor(this.total * this.percentage), 0, this.total) + 1;
    this.current = this.clamp(this.scrollPosition, 1, this.total);
    const daysAgo = postStream.closestDaysAgoFor(this.current);
    let date;
    if (daysAgo === undefined) {
      const post = postStream.posts.find(p => p.id === postStream.stream[this.current]);
      if (post) {
        date = new Date(post.created_at);
      }
    } else if (daysAgo !== null) {
      date = new Date();
      date.setDate(date.getDate() - daysAgo || 0);
    } else {
      date = null;
    }
    this.date = this.args.navigation ? this.args.navigation.dateForIndex(this.current) : date;
    const lastReadNumber = topic.last_read_post_number;
    const lastReadId = topic.last_read_post_id;
    if (lastReadId && lastReadNumber) {
      const idx = postStream.stream.indexOf(lastReadId) + 1;
      this.lastRead = idx;
      this.lastReadPercentage = this._percentFor(topic, idx);
    }
    if (this.args.navigation) {
      this.lastRead = this.args.navigation.lastReadIndex;
      this.lastReadPercentage = this.lastRead ? this._percentFor(topic, this.lastRead - 1) : null;
    }
    if (this.position !== this.scrollPosition) {
      this.position = this.scrollPosition;
      this.updateScrollPosition(this.current);
    }
    this.before = this.scrollareaRemaining() * this.percentage;
    this.after = this.scrollareaHeight - this.before - SCROLLER_HEIGHT;
    if (this.percentage === null) {
      return;
    }
    if (this.hasBackPosition) {
      this.lastReadTop = Math.round(this.lastReadPercentage * this.scrollareaHeight);
      this.showButton = this.before + SCROLLER_HEIGHT - 5 < this.lastReadTop || this.before > this.lastReadTop + 25;
    }
  }
  static {
    n(this.prototype, "calculatePosition", [bind]);
  }
  updateScrollPosition(scrollPosition) {
    // only ran on mobile
    if (!this.args.fullscreen) {
      return;
    }
    const stream = this.args.navigation || this.args.model.postStream;
    if (!this.position === scrollPosition) {
      return;
    }
    // we have an off by one, stream is zero based,
    stream.excerpt(scrollPosition - 1).then(info => {
      if (info && this.position === scrollPosition) {
        let excerpt = "";
        if (info.username) {
          excerpt = "<span class='username'>" + info.username + ":</span> ";
        }
        if (info.excerpt) {
          this.excerpt = excerpt + info.excerpt;
        } else if (info.action_code) {
          this.excerpt = `${excerpt} ${actionDescriptionHtml(info.action_code, info.created_at, info.username)}`;
        }
      }
    });
  }
  static {
    n(this.prototype, "updateScrollPosition", [debounce(50)]);
  }
  updatePercentage(e) {
    e.preventDefault();
    // Both a pointer drag and a click on the timeline track land here, and both
    // carry `pageY` directly.
    const currentCursorY = e.pageY;
    const desiredScrollerCentre = currentCursorY - this.dragOffset;
    const areaTop = domUtils.offset(this.scrollareaElement).top;
    const areaHeight = this.scrollareaElement.offsetHeight;
    const scrollerHeight = this.scrollerElement.offsetHeight;
    // The range of possible positions for the centre of the scroller
    const scrollableTop = areaTop + scrollerHeight / 2;
    const scrollableHeight = areaHeight - scrollerHeight;
    this.percentage = this.clamp(parseFloat(desiredScrollerCentre - scrollableTop) / scrollableHeight);
    this.commit();
  }
  static {
    n(this.prototype, "updatePercentage", [action]);
  }
  didStartDrag(event) {
    const y = event.pageY;
    const scrollerCentre = domUtils.offset(this.scrollerElement).top + this.scrollerElement.offsetHeight / 2;
    this.dragOffset = y - scrollerCentre;
    this.dragging = true;
  }
  static {
    n(this.prototype, "didStartDrag", [bind]);
  }
  dragMove(event) {
    event.stopPropagation();
    event.preventDefault();
    this.updatePercentage(event);
  }
  static {
    n(this.prototype, "dragMove", [bind]);
  }
  didEndDrag() {
    this.dragging = false;
    this.dragOffset = null;
    this.commit();
  }
  static {
    n(this.prototype, "didEndDrag", [bind]);
  }
  postScrolled(e) {
    this.current = e.postIndex;
    this.percentage = e.percent;
    this.calculatePosition();
    this.dockCheck();
  }
  static {
    n(this.prototype, "postScrolled", [bind]);
  }
  goBack() {
    this.args.jumpToIndex(this.lastRead);
  }
  static {
    n(this.prototype, "goBack", [action]);
  }
  dockCheck() {
    const timeline = document.querySelector(".timeline-container");
    const timelineHeight = timeline && timeline.offsetHeight || 400;
    const prevDockAt = this.dockAt;
    const positionTop = headerOffset() + window.pageYOffset;
    const currentPosition = positionTop + timelineHeight;
    const postStream = this.args.model.postStream;
    const allPostsLoaded = this.args.navigation?.loadedAllPosts ?? postStream.loadedAllPosts;
    this.dockBottom = false;
    if (positionTop < this.topicTop) {
      this.dockAt = parseInt(this.topicTop, 10);
    } else if (allPostsLoaded && currentPosition > this.topicBottom) {
      this.dockAt = parseInt(this.topicBottom - timelineHeight, 10);
      this.dockBottom = true;
      if (this.dockAt < 0) {
        this.dockAt = 0;
      }
    } else {
      this.dockAt = null;
    }
    if (this.dockAt !== prevDockAt) {
      if (this.dockAt) {
        this.args.setDocked(true);
        if (this.dockBottom) {
          this.args.setDockedBottom(true);
        }
      } else {
        this.args.setDocked(false);
        this.args.setDockedBottom(false);
      }
    }
  }
  commit() {
    this.calculatePosition();
    if (!this.dragging) {
      if (this.current === this.scrollPosition) {
        this.args.jumpToIndex(this.current);
      } else {
        this.args.jumpEnd();
      }
    }
  }
  clamp(p, min = 0.0, max = 1.0) {
    return Math.max(Math.min(p, max), min);
  }
  scrollareaRemaining() {
    return this.scrollareaHeight - SCROLLER_HEIGHT;
  }
  registerScrollarea(element) {
    this.scrollareaElement = element;
  }
  static {
    n(this.prototype, "registerScrollarea", [action]);
  }
  registerScroller(element) {
    this.scrollerElement = element;
  }
  static {
    n(this.prototype, "registerScroller", [action]);
  }
  _percentFor(topic, postIndex) {
    const total = this.args.navigation?.total ?? topic.postStream.filteredPostsCount;
    switch (postIndex) {
      // if first post, no top padding
      case 0:
        return 0;
      // if last, no bottom padding
      case total - 1:
        return 1;
      // otherwise, calculate
      default:
        return this.clamp(parseFloat(postIndex) / total);
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if @fullscreen}}
      <div class="title">
        <h2>
          <a
            class="fancy-title"
            href={{@model.firstPostUrl}}
            {{on "click" @jumpTop}}
          >{{this.topicTitle}}</a>
        </h2>
    
        {{#if (or this.siteSettings.topic_featured_link_enabled this.showTags)}}
          <div class="topic-header-extra">
            {{#if this.showTags}}
              <div class="list-tags">
                {{dDiscourseTags @model mode="list" tags=@model.tags}}
              </div>
            {{/if}}
            {{#if this.siteSettings.topic_featured_link_enabled}}
              {{topicFeaturedLink @model}}
            {{/if}}
          </div>
        {{/if}}
    
        {{#if (and (not @model.isPrivateMessage) @model.category)}}
          <div class="topic-category">
            {{#if @model.category.parentCategory}}
              {{dCategoryLink @model.category.parentCategory}}
            {{/if}}
            {{dCategoryLink @model.category}}
          </div>
        {{/if}}
    
        {{#if this.excerpt}}
          <div class="post-excerpt">{{trustHTML this.excerpt}}</div>
        {{/if}}
      </div>
    {{/if}}
    
    {{#if this.showTimelineControls}}
      <div class="timeline-controls">
        <PluginOutlet
          @name="timeline-controls-before"
          @outletArgs={{lazyHash model=@model}}
        />
    
        <TopicAdminMenu
          @convertToPrivateMessage={{@convertToPrivateMessage}}
          @convertToPublicTopic={{@convertToPublicTopic}}
          @deleteTopic={{@deleteTopic}}
          @recoverTopic={{@recoverTopic}}
          @resetBumpDate={{@resetBumpDate}}
          @showChangeTimestamp={{@showChangeTimestamp}}
          @showFeatureTopic={{@showFeatureTopic}}
          @showTopicSlowModeUpdate={{@showTopicSlowModeUpdate}}
          @showTopicTimerModal={{@showTopicTimerModal}}
          @toggleArchived={{@toggleArchived}}
          @toggleClosed={{@toggleClosed}}
          @toggleMultiSelect={{@toggleMultiSelect}}
          @toggleVisibility={{@toggleVisibility}}
          @topic={{@model}}
        />
    
        {{#if @model.has_localized_content}}
          <TopicContentLanguagePreferences />
        {{/if}}
      </div>
    {{/if}}
    
    {{#if this.displayTimeLineScrollArea}}
      <UserTip
        @contentText={{i18n "user_tips.topic_timeline.content"}}
        @id="topic_timeline"
        @placement="left"
        @portalOutletSelector=".timeline-scrollarea-wrapper"
        @priority={{900}}
        @titleText={{i18n "user_tips.topic_timeline.title"}}
        @triggerSelector=".timeline-scrollarea"
      />
    
      <div class="timeline-scrollarea-wrapper">
        <div class="timeline-date-wrapper">
          <a
            class="start-date"
            href={{@model.firstPostUrl}}
            title={{i18n "topic_entrance.jump_top_button_title"}}
            {{on "click" this.updatePercentage}}
          >
            <span>
              {{this.startDate}}
            </span>
          </a>
        </div>
    
        <div
          class={{dConcatClass
            "timeline-scrollarea"
            (if this.dragging "--dragging")
          }}
          style={{this.timelineScrollareaStyle}}
          {{didInsert this.registerScrollarea}}
        >
          {{! eslint-disable ember/template-no-invalid-interactive }}
          <div
            class="timeline-padding"
            style={{this.beforePadding}}
            {{on "click" this.updatePercentage}}
          ></div>
    
          <Scroller
            @current={{this.current}}
            @date={{this.date}}
            @didEndDrag={{this.didEndDrag}}
            @didStartDrag={{this.didStartDrag}}
            @dragMove={{this.dragMove}}
            @fullscreen={{@fullscreen}}
            @onGoBack={{this.onGoBack}}
            @showDockedButton={{this.showDockedButton}}
            @total={{this.total}}
            @translatedLabel={{this.navigationLabel}}
            {{didInsert this.registerScroller}}
          />
    
          {{! eslint-disable ember/template-no-invalid-interactive }}
          <div
            class="timeline-padding"
            style={{this.afterPadding}}
            {{on "click" this.updatePercentage}}
          ></div>
    
          {{#if (and this.hasBackPosition this.showButton)}}
            <div class="timeline-last-read" style={{this.lastReadStyle}}>
              {{dIcon "minus" class="progress"}}
              <BackButton @onGoBack={{this.goBack}} />
            </div>
          {{/if}}
        </div>
    
        <div class="timeline-date-wrapper">
          <a
            class="now-date"
            href={{@model.lastPostUrl}}
            {{on "click" this.updatePercentage}}
          >
            <span>
              {{dAgeWithTooltip this.nowDate this.nowDateOptions}}
            </span>
          </a>
        </div>
      </div>
    
      <div class="timeline-footer-controls">
        {{#if this.displaySummary}}
          <DButton
            class="show-summary btn-default btn-small"
            title={{i18n "summary.short_title"}}
            @action={{@showTopReplies}}
            @icon="layer-group"
            @label="summary.short_label"
          />
        {{/if}}
    
        {{#if (and this.currentUser (not @fullscreen))}}
          {{#if this.canCreatePost}}
            <DButton
              class="btn-default create reply-to-post"
              title={{i18n "topic.reply.help"}}
              @action={{fn @replyToPost null}}
              @icon="reply"
            />
          {{/if}}
        {{/if}}
    
        {{#if @fullscreen}}
          <DButton
            class="timeline-open-jump-to-post-prompt-btn jump-to-post"
            title={{i18n "topic.progress.jump_prompt_long"}}
            @action={{@jumpToPostPrompt}}
            @label="topic.progress.jump_prompt"
          />
        {{/if}}
    
        {{#if (and this.currentUser this.site.desktopView)}}
          <TopicNotificationsButton
            @contentClass="topic-timeline-notifications-tracking-content"
            @expanded={{false}}
            @topic={{@model}}
          />
        {{/if}}
    
        <PluginOutlet
          @name="timeline-footer-controls-after"
          @outletArgs={{lazyHash
            model=@model
            fullscreen=@fullscreen
            navigation=@navigation
          }}
        />
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,1],[[[1,\"  \"],[10,0],[14,0,\"title\"],[12],[1,\"\\n    \"],[10,\"h2\"],[12],[1,\"\\n      \"],[11,3],[24,0,\"fancy-title\"],[16,6,[30,2,[\"firstPostUrl\"]]],[4,[32,0],[\"click\",[30,3]],null],[12],[1,[30,0,[\"topicTitle\"]]],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n\"],[41,[28,[32,1],[[30,0,[\"siteSettings\",\"topic_featured_link_enabled\"]],[30,0,[\"showTags\"]]],null],[[[1,\"      \"],[10,0],[14,0,\"topic-header-extra\"],[12],[1,\"\\n\"],[41,[30,0,[\"showTags\"]],[[[1,\"          \"],[10,0],[14,0,\"list-tags\"],[12],[1,\"\\n            \"],[1,[28,[32,2],[[30,2]],[[\"mode\",\"tags\"],[\"list\",[30,2,[\"tags\"]]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[41,[30,0,[\"siteSettings\",\"topic_featured_link_enabled\"]],[[[1,\"          \"],[1,[28,[32,3],[[30,2]],null]],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[28,[32,4],[[28,[32,5],[[30,2,[\"isPrivateMessage\"]]],null],[30,2,[\"category\"]]],null],[[[1,\"      \"],[10,0],[14,0,\"topic-category\"],[12],[1,\"\\n\"],[41,[30,2,[\"category\",\"parentCategory\"]],[[[1,\"          \"],[1,[28,[32,6],[[30,2,[\"category\",\"parentCategory\"]]],null]],[1,\"\\n\"]],[]],null],[1,\"        \"],[1,[28,[32,6],[[30,2,[\"category\"]]],null]],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"excerpt\"]],[[[1,\"      \"],[10,0],[14,0,\"post-excerpt\"],[12],[1,[28,[32,7],[[30,0,[\"excerpt\"]]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"showTimelineControls\"]],[[[1,\"  \"],[10,0],[14,0,\"timeline-controls\"],[12],[1,\"\\n    \"],[8,[32,8],null,[[\"@name\",\"@outletArgs\"],[\"timeline-controls-before\",[28,[32,9],null,[[\"model\"],[[30,2]]]]]],null],[1,\"\\n\\n    \"],[8,[32,10],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@recoverTopic\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\",\"@topic\"],[[30,4],[30,5],[30,6],[30,7],[30,8],[30,9],[30,10],[30,11],[30,12],[30,13],[30,14],[30,15],[30,16],[30,2]]],null],[1,\"\\n\\n\"],[41,[30,2,[\"has_localized_content\"]],[[[1,\"      \"],[8,[32,11],null,null,null],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"displayTimeLineScrollArea\"]],[[[1,\"  \"],[8,[32,12],null,[[\"@contentText\",\"@id\",\"@placement\",\"@portalOutletSelector\",\"@priority\",\"@titleText\",\"@triggerSelector\"],[[28,[32,13],[\"user_tips.topic_timeline.content\"],null],\"topic_timeline\",\"left\",\".timeline-scrollarea-wrapper\",900,[28,[32,13],[\"user_tips.topic_timeline.title\"],null],\".timeline-scrollarea\"]],null],[1,\"\\n\\n  \"],[10,0],[14,0,\"timeline-scrollarea-wrapper\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"timeline-date-wrapper\"],[12],[1,\"\\n      \"],[11,3],[24,0,\"start-date\"],[16,6,[30,2,[\"firstPostUrl\"]]],[16,\"title\",[28,[32,13],[\"topic_entrance.jump_top_button_title\"],null]],[4,[32,0],[\"click\",[30,0,[\"updatePercentage\"]]],null],[12],[1,\"\\n        \"],[10,1],[12],[1,\"\\n          \"],[1,[30,0,[\"startDate\"]]],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n    \"],[11,0],[16,0,[28,[32,14],[\"timeline-scrollarea\",[52,[30,0,[\"dragging\"]],\"--dragging\"]],null]],[16,5,[30,0,[\"timelineScrollareaStyle\"]]],[4,[32,15],[[30,0,[\"registerScrollarea\"]]],null],[12],[1,\"\\n\"],[1,\"      \"],[11,0],[24,0,\"timeline-padding\"],[16,5,[30,0,[\"beforePadding\"]]],[4,[32,0],[\"click\",[30,0,[\"updatePercentage\"]]],null],[12],[13],[1,\"\\n\\n      \"],[8,[32,16],[[4,[32,15],[[30,0,[\"registerScroller\"]]],null]],[[\"@current\",\"@date\",\"@didEndDrag\",\"@didStartDrag\",\"@dragMove\",\"@fullscreen\",\"@onGoBack\",\"@showDockedButton\",\"@total\",\"@translatedLabel\"],[[30,0,[\"current\"]],[30,0,[\"date\"]],[30,0,[\"didEndDrag\"]],[30,0,[\"didStartDrag\"]],[30,0,[\"dragMove\"]],[30,1],[30,0,[\"onGoBack\"]],[30,0,[\"showDockedButton\"]],[30,0,[\"total\"]],[30,0,[\"navigationLabel\"]]]],null],[1,\"\\n\\n\"],[1,\"      \"],[11,0],[24,0,\"timeline-padding\"],[16,5,[30,0,[\"afterPadding\"]]],[4,[32,0],[\"click\",[30,0,[\"updatePercentage\"]]],null],[12],[13],[1,\"\\n\\n\"],[41,[28,[32,4],[[30,0,[\"hasBackPosition\"]],[30,0,[\"showButton\"]]],null],[[[1,\"        \"],[10,0],[14,0,\"timeline-last-read\"],[15,5,[30,0,[\"lastReadStyle\"]]],[12],[1,\"\\n          \"],[1,[28,[32,17],[\"minus\"],[[\"class\"],[\"progress\"]]]],[1,\"\\n          \"],[8,[32,18],null,[[\"@onGoBack\"],[[30,0,[\"goBack\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n\\n    \"],[10,0],[14,0,\"timeline-date-wrapper\"],[12],[1,\"\\n      \"],[11,3],[24,0,\"now-date\"],[16,6,[30,2,[\"lastPostUrl\"]]],[4,[32,0],[\"click\",[30,0,[\"updatePercentage\"]]],null],[12],[1,\"\\n        \"],[10,1],[12],[1,\"\\n          \"],[1,[28,[32,19],[[30,0,[\"nowDate\"]],[30,0,[\"nowDateOptions\"]]],null]],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,0],[14,0,\"timeline-footer-controls\"],[12],[1,\"\\n\"],[41,[30,0,[\"displaySummary\"]],[[[1,\"      \"],[8,[32,20],[[24,0,\"show-summary btn-default btn-small\"],[16,\"title\",[28,[32,13],[\"summary.short_title\"],null]]],[[\"@action\",\"@icon\",\"@label\"],[[30,17],\"layer-group\",\"summary.short_label\"]],null],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[28,[32,4],[[30,0,[\"currentUser\"]],[28,[32,5],[[30,1]],null]],null],[[[41,[30,0,[\"canCreatePost\"]],[[[1,\"        \"],[8,[32,20],[[24,0,\"btn-default create reply-to-post\"],[16,\"title\",[28,[32,13],[\"topic.reply.help\"],null]]],[[\"@action\",\"@icon\"],[[28,[32,21],[[30,18],null],null],\"reply\"]],null],[1,\"\\n\"]],[]],null]],[]],null],[1,\"\\n\"],[41,[30,1],[[[1,\"      \"],[8,[32,20],[[24,0,\"timeline-open-jump-to-post-prompt-btn jump-to-post\"],[16,\"title\",[28,[32,13],[\"topic.progress.jump_prompt_long\"],null]]],[[\"@action\",\"@label\"],[[30,19],\"topic.progress.jump_prompt\"]],null],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[28,[32,4],[[30,0,[\"currentUser\"]],[30,0,[\"site\",\"desktopView\"]]],null],[[[1,\"      \"],[8,[32,22],null,[[\"@contentClass\",\"@expanded\",\"@topic\"],[\"topic-timeline-notifications-tracking-content\",false,[30,2]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[8,[32,8],null,[[\"@name\",\"@outletArgs\"],[\"timeline-footer-controls-after\",[28,[32,9],null,[[\"model\",\"fullscreen\",\"navigation\"],[[30,2],[30,1],[30,20]]]]]],null],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[\"@fullscreen\",\"@model\",\"@jumpTop\",\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@recoverTopic\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\",\"@showTopReplies\",\"@replyToPost\",\"@jumpToPostPrompt\",\"@navigation\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        on,
        or,
        dDiscourseTags,
        topicFeaturedLink,
        and,
        not,
        dCategoryLink,
        trustHTML,
        PluginOutlet,
        lazyHash,
        TopicAdminMenu,
        TopicContentLanguagePreferences,
        UserTip,
        i18n,
        dConcatClass,
        didInsert,
        Scroller,
        dIcon,
        BackButton,
        dAgeWithTooltip,
        DButton,
        fn,
        TopicNotificationsButton
      }),
      "isStrictMode": true
    }), this);
  }
}