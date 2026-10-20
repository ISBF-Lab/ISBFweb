import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import PluginOutlet from "discourse/components/plugin-outlet";
import lazyHash from "discourse/helpers/lazy-hash";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { feedbackCategory, feedbackComposeHref, isFeedbackPath } from "../lib/feedback-category";
import { frontendConsistencyScope } from "../lib/frontend-consistency-scope";
import { notificationsEnabled } from "../lib/notification-groups";
import { officialConfig } from "../lib/official-filters";
import { isConversationTopic, isFeedStyleTopic } from "../lib/topic-card-scope";
import ISBFAlumni from "./isbf-alumni";
import ISBFExplore from "./isbf-explore";
import ISBFLearning from "./isbf-learning";
import ISBFMarketplace from "./isbf-marketplace";
import ISBFNotificationBell from "./isbf-notification-bell";
import ISBFNotifications from "./isbf-notifications";
import ISBFOfficialFeed from "./isbf-official-feed";
import ISBFV2AccountMenu from "./isbf-v2-account-menu";
import ISBFV2AnonymousPosts from "./isbf-v2-anonymous-posts";
import ISBFV2Brand from "./isbf-v2-brand";
import ISBFV2Calendar from "./isbf-v2-calendar";
import ISBFV2RightRail from "./isbf-v2-right-rail";
import ISBFV2SideNav from "./isbf-v2-side-nav";
import ISBFV2Workbench from "./isbf-v2-workbench";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFV2Shell extends Component {
  static {
    g(this.prototype, "categoryTypeChooser", [service]);
  }
  #categoryTypeChooser = (i(this, "categoryTypeChooser"), void 0);
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
  static {
    g(this.prototype, "isbfBackNavigation", [service]);
  }
  #isbfBackNavigation = (i(this, "isbfBackNavigation"), void 0);
  static {
    g(this.prototype, "isbfNotifications", [service]);
  }
  #isbfNotifications = (i(this, "isbfNotifications"), void 0);
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "site", [service]);
  }
  #site = (i(this, "site"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  get path() {
    return (this.router.currentURL ?? "").split("?")[0];
  }
  get informationPage() {
    return this.path.split("#")[0].match(/^\/(about|faq|guidelines|tos|privacy|rules|conduct)\/?$/)?.[1] ?? null;
  }
  get pageKind() {
    const path = this.path;
    if (/^\/(admin|login|signup|session)(\/|$)/.test(path)) {
      return null;
    }
    const scope = frontendConsistencyScope(this.router.currentRouteName);
    if (/^\/g(\/|$)/.test(path) && scope?.id.startsWith("group")) {
      return "groups";
    }
    if (scope?.id === "search" || scope?.id === "tags") {
      return scope.id;
    }
    if (this.informationPage) {
      return "information";
    }
    if (/^\/t\//.test(path)) {
      return "topic";
    }
    if (path === "/isbf-anonymous/posts") {
      return "anonymous-posts";
    }
    if (path === "/isbf/calendar") {
      return "calendar";
    }
    if (path === "/isbf/workbench/resume" && this.siteSettings.isbf_resume_enabled) {
      return "resume";
    }
    if (path === "/isbf/workbench") {
      return "workbench";
    }
    if (path === "/isbf/alumni") {
      return "alumni";
    }
    if (path === "/isbf/marketplace") {
      return "marketplace";
    }
    if (path === "/isbf/learning") {
      return "learning";
    }
    if (/^\/u\/[^/]+\/notifications(\/|$)/.test(path)) {
      return "notifications";
    }
    if (/^\/u\/[^/]+\/activity\/bookmarks(\/|$)/.test(path)) {
      return "bookmarks";
    }
    if (/^\/u\/?$/.test(path)) {
      return "directory";
    }
    if (/^\/u\//.test(path)) {
      return "profile";
    }
    if (/^\/badges(\/|$)/.test(path)) {
      return "badges";
    }
    if (this.#isOfficialPath(path) || this.isFeedback) {
      return "feed";
    }
    if (/^\/(search|categories|c|tag|tags)(\/|$)/.test(path)) {
      return "explore";
    }
    if (/^\/(|latest|hot|top|new|unread|following|filter)(\/|$)/.test(path)) {
      return "feed";
    }
    return null;
  }
  get isFeed() {
    return this.pageKind === "feed";
  }
  get feedbackCategory() {
    return feedbackCategory(this.site, settings.feedback_category_id);
  }
  get isFeedback() {
    return isFeedbackPath(this.path, this.feedbackCategory);
  }
  get composePrompt() {
    return i18n(themePrefix(this.isFeedback ? "isbf_v2.feedback_prompt" : "isbf_v2.compose_prompt"));
  }
  get canCreateExploreCategory() {
    return Boolean(this.currentUser?.admin || this.currentUser?.moderator && this.siteSettings.moderators_manage_categories);
  }
  get showCustomExplore() {
    return this.path.replace(/\/$/, "") === "/categories" && this.siteSettings.isbf_explore_enabled;
  }
  get isNotifications() {
    return this.pageKind === "notifications";
  }
  get showGroupedNotifications() {
    return notificationsEnabled(this.path, this.currentUser, this.siteSettings);
  }
  get isAnonymousPosts() {
    return this.pageKind === "anonymous-posts";
  }
  get isCalendar() {
    return this.pageKind === "calendar";
  }
  get isWorkbench() {
    return ["workbench", "resume", "learning", "alumni", "marketplace"].includes(this.pageKind);
  }
  get isWorkbenchHome() {
    return this.pageKind === "workbench";
  }
  get isAlumni() {
    return this.pageKind === "alumni";
  }
  get isMarketplace() {
    return this.pageKind === "marketplace";
  }
  get isLearning() {
    return this.pageKind === "learning";
  }
  get showPageHeader() {
    return !this.isFeed && !["alumni", "calendar", "explore", "learning", "marketplace", "notifications", "workbench", "resume"].includes(this.pageKind);
  }
  get showSectionHeading() {
    return !this.showGroupedNotifications && ["bookmarks", "explore", "notifications"].includes(this.pageKind);
  }
  get showRightRail() {
    return settings.show_right_rail && !this.isCalendar && !this.isWorkbench && !this.isAnonymousPosts;
  }
  get isOwnProfile() {
    if (this.pageKind !== "profile" || !this.currentUser) {
      return false;
    }
    const profilePath = `/u/${encodeURIComponent(this.currentUser.username)}`.toLowerCase();
    const path = this.path.toLowerCase();
    return path === profilePath || path.startsWith(`${profilePath}/`);
  }
  get pageTitle() {
    if (this.informationPage) {
      return i18n(this.informationPage === "about" ? "about.simple_title" : this.informationPage);
    }
    if (this.pageKind === "badges") {
      return i18n("badges.title");
    }
    if (this.pageKind === "directory") {
      return i18n("directory.title");
    }
    const frontendTitles = {
      groups: "groups.index.all",
      search: "search.full_page_title",
      tags: "tagging.tags"
    };
    if (frontendTitles[this.pageKind]) {
      return i18n(frontendTitles[this.pageKind]);
    }
    const titles = {
      "anonymous-posts": "my_anonymous_posts",
      bookmarks: "bookmarks",
      calendar: "calendar",
      explore: "explore",
      notifications: "notifications",
      profile: "profile",
      topic: "topic",
      workbench: "workbench"
    };
    return i18n(themePrefix("isbf_v2." + titles[this.pageKind]));
  }
  get latestActive() {
    return this.path === "/" || this.path.startsWith("/latest");
  }
  get officialActive() {
    return this.#isOfficialPath(this.path);
  }
  get officialConfig() {
    return officialConfig(this.site);
  }
  get showOfficialFeed() {
    return this.officialActive && Boolean(this.officialConfig);
  }
  get canCompose() {
    if (this.isFeedback) {
      return !this.currentUser || this.feedbackCategory.canCreateTopic;
    }
    if (!this.officialActive) {
      return true;
    }
    const categoryId = this.officialConfig?.category_id ?? Number(settings.official_path.split("/")[3]);
    const category = this.site.categories?.find(item => item.id === categoryId);
    return Boolean(this.currentUser?.academy_official_member && category?.canCreateTopic);
  }
  get showMobileCompose() {
    return this.isFeed && this.canCompose;
  }
  get showMobileReview() {
    return this.isFeed && (this.latestActive || this.officialActive) && Boolean(this.currentUser?.can_review);
  }
  get composeHref() {
    if (this.isFeedback) {
      return feedbackComposeHref(this.feedbackCategory);
    }
    const categorySlug = settings.official_path.split("/")[2];
    return this.officialActive ? `/new-topic?category=${encodeURIComponent(categorySlug)}` : "/new-topic";
  }
  get topicController() {
    return getOwner(this).lookup("controller:topic");
  }
  get topicFeedStyle() {
    return isFeedStyleTopic(this.topicController.get("model"), this.path) || this.topicConversations;
  }
  get topicConversations() {
    return isConversationTopic(this.topicController.get("model"), this.path, this.siteSettings);
  }
  get shellClass() {
    const classes = ["isbf-v2-shell", `isbf-v2-shell--${this.pageKind}`];
    if (this.topicFeedStyle) {
      classes.push("isbf-v2-shell--topic-feed-style");
      if (this.topicConversations) {
        classes.push("isbf-v2-shell--topic-conversations");
      }
      if (this.topicController.get("editingTopic")) {
        classes.push("isbf-v2-shell--topic-editing");
      }
    }
    if (!this.isFeed && !this.showPageHeader) {
      classes.push("isbf-v2-shell--no-page-header");
    }
    if (this.showGroupedNotifications) {
      classes.push("isbf-v2-shell--grouped-notifications");
    }
    if (this.showCustomExplore) {
      classes.push("isbf-v2-shell--custom-explore");
    }
    if (this.showSectionHeading) {
      classes.push("isbf-v2-shell--section-heading");
    }
    if (this.showOfficialFeed) {
      classes.push("isbf-v2-shell--official-filtered");
    }
    if (this.officialActive) {
      classes.push("isbf-v2-shell--official");
    }
    if (this.isFeedback) {
      classes.push("isbf-v2-shell--feedback");
    }
    if (!this.canCompose) {
      classes.push("isbf-v2-shell--no-compose");
    }
    return classes.join(" ");
  }
  get profileHref() {
    return this.currentUser ? "/u/" + this.currentUser.username : "/login";
  }
  get notificationsHref() {
    return this.currentUser ? "/u/" + this.currentUser.username + "/notifications" : "/login";
  }
  get backHref() {
    return this.isbfBackNavigation.href("/latest");
  }
  goBack(event) {
    this.isbfBackNavigation.back(event);
  }
  static {
    n(this.prototype, "goBack", [action]);
  }
  createExploreCategory() {
    if (this.canCreateExploreCategory) {
      this.categoryTypeChooser.createCategory();
    }
  }
  static {
    n(this.prototype, "createExploreCategory", [action]);
  }
  #isOfficialPath(path) {
    const categoryPath = settings.official_path.split("/l/")[0];
    return path === categoryPath || path.startsWith(`${categoryPath}/`);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.pageKind}}
      <div class={{this.shellClass}}>
        <ISBFV2SideNav />
        {{#if this.showRightRail}}<ISBFV2RightRail />{{/if}}
    
        {{#if this.isFeed}}
          {{#if this.isFeedback}}
            <header class="isbf-v2-feedback-header">
              <h1>{{i18n (themePrefix "isbf_v2.feedback")}}</h1>
            </header>
          {{else}}
            <header class="isbf-v2-feed-header">
              <div class="isbf-v2-feed-header__title">
                {{#if this.currentUser}}
                  <a
                    aria-label={{i18n (themePrefix "isbf_v2.profile")}}
                    class="isbf-v2-feed-header__avatar isbf-avatar"
                    href={{this.profileHref}}
                  >{{dAvatar this.currentUser imageSize="small"}}<PluginOutlet
                      @name="user-avatar-frame"
                      @outletArgs={{lazyHash
                        user=this.currentUser
                        motion="static"
                      }}
                    /></a>
                {{/if}}
                <span>{{i18n (themePrefix "isbf_v2.home")}}</span>
                <ISBFV2Brand
                  class="isbf-v2-feed-header__brand"
                  @mobile={{true}}
                />
                <a
                  aria-label={{i18n (themePrefix "isbf_v2.search")}}
                  class="isbf-v2-feed-header__search"
                  href="/search"
                >{{dIcon "magnifying-glass"}}</a>
              </div>
              <nav aria-label={{i18n (themePrefix "isbf_v2.feed_label")}}>
                <a
                  aria-current={{if this.latestActive "page"}}
                  class={{if this.latestActive "is-active"}}
                  href="/latest"
                >{{i18n (themePrefix "isbf_v2.latest")}}</a>
                <a
                  aria-current={{if this.officialActive "page"}}
                  class={{if this.officialActive "is-active"}}
                  href={{settings.official_path}}
                >{{i18n (themePrefix "isbf_v2.official")}}</a>
              </nav>
            </header>
          {{/if}}
    
          {{#if this.canCompose}}
            <div class="isbf-v2-compose">
              {{#if this.currentUser}}
                <a
                  aria-label={{this.currentUser.username}}
                  class="isbf-v2-compose__avatar isbf-avatar"
                  href={{this.profileHref}}
                >{{dAvatar this.currentUser imageSize="large"}}<PluginOutlet
                    @name="user-avatar-frame"
                    @outletArgs={{lazyHash
                      user=this.currentUser
                      motion="static"
                    }}
                  /></a>
              {{/if}}
              <a
                class="isbf-v2-compose__prompt"
                href={{this.composeHref}}
              >{{this.composePrompt}}</a>
              <a
                class="isbf-v2-compose__button"
                href={{this.composeHref}}
              >{{i18n (themePrefix "isbf_v2.compose")}}</a>
            </div>
          {{/if}}
        {{else if this.showPageHeader}}
          <header class="isbf-v2-page-header">
            <a
              aria-label={{i18n "back_button"}}
              class="isbf-v2-page-header__back"
              href={{this.backHref}}
              {{on "click" this.goBack}}
            >{{dIcon "arrow-left"}}</a>
            <span>{{this.pageTitle}}</span>
            {{#if this.isOwnProfile}}<ISBFV2AccountMenu
                @mobile={{true}}
              />{{/if}}
          </header>
        {{/if}}
    
        {{#if this.showSectionHeading}}
          <header class="isbf-v2-section-heading">
            <h1>{{this.pageTitle}}</h1>
          </header>
        {{/if}}
    
        {{#if this.showGroupedNotifications}}<ISBFNotifications />{{/if}}
    
        {{#if this.showCustomExplore}}<ISBFExplore
            @canCreateCategory={{this.canCreateExploreCategory}}
            @onCreateCategory={{this.createExploreCategory}}
          />{{/if}}
    
        {{#if this.showOfficialFeed}}<ISBFOfficialFeed
            @config={{this.officialConfig}}
          />{{/if}}
    
        {{#if this.isAnonymousPosts}}<ISBFV2AnonymousPosts />{{/if}}
        {{#if this.isCalendar}}<ISBFV2Calendar />{{/if}}
        {{#if this.isAlumni}}<ISBFAlumni />
        {{else if this.isMarketplace}}<ISBFMarketplace />
        {{else if this.isLearning}}<ISBFLearning />
        {{else if this.isWorkbenchHome}}<ISBFV2Workbench />{{/if}}
    
        {{#if this.showMobileCompose}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.compose")}}
            class="isbf-v2-mobile-compose"
            href={{this.composeHref}}
          >{{dIcon "plus"}}</a>
        {{/if}}
    
        {{#if this.showMobileReview}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.review")}}
            class="isbf-v2-mobile-review"
            href="/review"
          >{{i18n (themePrefix "isbf_v2.review")}}</a>
        {{/if}}
    
        <nav
          aria-label={{i18n (themePrefix "isbf_v2.quick_label")}}
          class="isbf-v2-mobile-nav"
        >
          <a
            aria-current={{if this.isFeed "page"}}
            class={{if this.isFeed "is-active"}}
            href="/latest"
          >{{dIcon "house"}}<span>{{i18n
                (themePrefix "isbf_v2.home")
              }}</span></a>
          <a
            aria-current={{if this.isNotifications "page"}}
            aria-label={{this.isbfNotifications.linkLabel}}
            class={{if this.isNotifications "is-active"}}
            href={{this.notificationsHref}}
          ><ISBFNotificationBell /><span>{{i18n
                (themePrefix "isbf_v2.notifications")
              }}</span></a>
          <a
            aria-current={{if this.isCalendar "page"}}
            class={{if this.isCalendar "is-active"}}
            href="/isbf/calendar"
          >{{dIcon "calendar-days"}}<span>{{i18n
                (themePrefix "isbf_v2.calendar")
              }}</span></a>
          <a
            aria-current={{if this.isWorkbench "page"}}
            class={{if this.isWorkbench "is-active"}}
            href="/isbf/workbench"
          >{{dIcon "table-cells-large"}}<span>{{i18n
                (themePrefix "isbf_v2.workbench")
              }}</span></a>
        </nav>
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"pageKind\"]],[[[1,\"  \"],[10,0],[15,0,[30,0,[\"shellClass\"]]],[12],[1,\"\\n    \"],[8,[32,0],null,null,null],[1,\"\\n    \"],[41,[30,0,[\"showRightRail\"]],[[[8,[32,1],null,null,null]],[]],null],[1,\"\\n\\n\"],[41,[30,0,[\"isFeed\"]],[[[41,[30,0,[\"isFeedback\"]],[[[1,\"        \"],[10,\"header\"],[14,0,\"isbf-v2-feedback-header\"],[12],[1,\"\\n          \"],[10,\"h1\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.feedback\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,\"header\"],[14,0,\"isbf-v2-feed-header\"],[12],[1,\"\\n          \"],[10,0],[14,0,\"isbf-v2-feed-header__title\"],[12],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"              \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.profile\"],null]],null]],[14,0,\"isbf-v2-feed-header__avatar isbf-avatar\"],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,4],[[30,0,[\"currentUser\"]]],[[\"imageSize\"],[\"small\"]]]],[8,[32,5],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,6],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n\"]],[]],null],[1,\"            \"],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.home\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,7],[[24,0,\"isbf-v2-feed-header__brand\"]],[[\"@mobile\"],[true]],null],[1,\"\\n            \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.search\"],null]],null]],[14,0,\"isbf-v2-feed-header__search\"],[14,6,\"/search\"],[12],[1,[28,[32,8],[\"magnifying-glass\"],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n          \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.feed_label\"],null]],null]],[12],[1,\"\\n            \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"latestActive\"]],\"page\"]],[15,0,[52,[30,0,[\"latestActive\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.latest\"],null]],null]],[13],[1,\"\\n            \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"officialActive\"]],\"page\"]],[15,0,[52,[30,0,[\"officialActive\"]],\"is-active\"]],[15,6,[32,9,[\"official_path\"]]],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.official\"],null]],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]]],[1,\"\\n\"],[41,[30,0,[\"canCompose\"]],[[[1,\"        \"],[10,0],[14,0,\"isbf-v2-compose\"],[12],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"            \"],[10,3],[15,\"aria-label\",[30,0,[\"currentUser\",\"username\"]]],[14,0,\"isbf-v2-compose__avatar isbf-avatar\"],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,4],[[30,0,[\"currentUser\"]]],[[\"imageSize\"],[\"large\"]]]],[8,[32,5],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,6],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[10,3],[14,0,\"isbf-v2-compose__prompt\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[30,0,[\"composePrompt\"]]],[13],[1,\"\\n          \"],[10,3],[14,0,\"isbf-v2-compose__button\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.compose\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null]],[]],[[[41,[30,0,[\"showPageHeader\"]],[[[1,\"      \"],[10,\"header\"],[14,0,\"isbf-v2-page-header\"],[12],[1,\"\\n        \"],[11,3],[16,\"aria-label\",[28,[32,2],[\"back_button\"],null]],[24,0,\"isbf-v2-page-header__back\"],[16,6,[30,0,[\"backHref\"]]],[4,[32,10],[\"click\",[30,0,[\"goBack\"]]],null],[12],[1,[28,[32,8],[\"arrow-left\"],null]],[13],[1,\"\\n        \"],[10,1],[12],[1,[30,0,[\"pageTitle\"]]],[13],[1,\"\\n        \"],[41,[30,0,[\"isOwnProfile\"]],[[[8,[32,11],null,[[\"@mobile\"],[true]],null]],[]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"]],[]],null]],[]]],[1,\"\\n\"],[41,[30,0,[\"showSectionHeading\"]],[[[1,\"      \"],[10,\"header\"],[14,0,\"isbf-v2-section-heading\"],[12],[1,\"\\n        \"],[10,\"h1\"],[12],[1,[30,0,[\"pageTitle\"]]],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"showGroupedNotifications\"]],[[[8,[32,12],null,null,null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"showCustomExplore\"]],[[[8,[32,13],null,[[\"@canCreateCategory\",\"@onCreateCategory\"],[[30,0,[\"canCreateExploreCategory\"]],[30,0,[\"createExploreCategory\"]]]],null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"showOfficialFeed\"]],[[[8,[32,14],null,[[\"@config\"],[[30,0,[\"officialConfig\"]]]],null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"isAnonymousPosts\"]],[[[8,[32,15],null,null,null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"isCalendar\"]],[[[8,[32,16],null,null,null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"isAlumni\"]],[[[8,[32,17],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isMarketplace\"]],[[[8,[32,18],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isLearning\"]],[[[8,[32,19],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isWorkbenchHome\"]],[[[8,[32,20],null,null,null]],[]],null]],[]]]],[]]]],[]]],[1,\"\\n\"],[41,[30,0,[\"showMobileCompose\"]],[[[1,\"      \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.compose\"],null]],null]],[14,0,\"isbf-v2-mobile-compose\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[28,[32,8],[\"plus\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"showMobileReview\"]],[[[1,\"      \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.review\"],null]],null]],[14,0,\"isbf-v2-mobile-review\"],[14,6,\"/review\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.review\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.quick_label\"],null]],null]],[14,0,\"isbf-v2-mobile-nav\"],[12],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isFeed\"]],\"page\"]],[15,0,[52,[30,0,[\"isFeed\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,8],[\"house\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.home\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isNotifications\"]],\"page\"]],[15,\"aria-label\",[30,0,[\"isbfNotifications\",\"linkLabel\"]]],[15,0,[52,[30,0,[\"isNotifications\"]],\"is-active\"]],[15,6,[30,0,[\"notificationsHref\"]]],[12],[8,[32,21],null,null,null],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.notifications\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isCalendar\"]],\"page\"]],[15,0,[52,[30,0,[\"isCalendar\"]],\"is-active\"]],[14,6,\"/isbf/calendar\"],[12],[1,[28,[32,8],[\"calendar-days\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isWorkbench\"]],\"page\"]],[15,0,[52,[30,0,[\"isWorkbench\"]],\"is-active\"]],[14,6,\"/isbf/workbench\"],[12],[1,[28,[32,8],[\"table-cells-large\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.workbench\"],null]],null]],[13],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        ISBFV2SideNav,
        ISBFV2RightRail,
        i18n,
        themePrefix,
        dAvatar,
        PluginOutlet,
        lazyHash,
        ISBFV2Brand,
        dIcon,
        settings,
        on,
        ISBFV2AccountMenu,
        ISBFNotifications,
        ISBFExplore,
        ISBFOfficialFeed,
        ISBFV2AnonymousPosts,
        ISBFV2Calendar,
        ISBFAlumni,
        ISBFMarketplace,
        ISBFLearning,
        ISBFV2Workbench,
        ISBFNotificationBell
      }),
      "isStrictMode": true
    }), this);
  }
}