import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { feedbackCategory, feedbackComposeHref, isFeedbackPath } from "../lib/feedback-category";
import ISBFNotificationBell from "./isbf-notification-bell";
import ISBFV2AccountMenu from "./isbf-v2-account-menu";
import ISBFV2Brand from "./isbf-v2-brand";
import ISBFV2MoreMenu from "./isbf-v2-more-menu";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFV2SideNav extends Component {
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
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
  get composeHref() {
    const category = feedbackCategory(this.site, settings.feedback_category_id);
    return isFeedbackPath(this.router.currentURL, category) ? feedbackComposeHref(category) : "/new-topic";
  }
  get bookmarksHref() {
    return this.currentUser ? `/u/${this.currentUser.username}/activity/bookmarks` : "/login";
  }
  get notificationsHref() {
    return this.currentUser ? `/u/${this.currentUser.username}/notifications` : "/login";
  }
  get profileHref() {
    return this.currentUser ? `/u/${this.currentUser.username}` : "/login";
  }
  get homeActive() {
    const path = this.router.currentURL ?? "";
    const officialPath = settings.official_path.split("/l/")[0];
    if (isFeedbackPath(path, feedbackCategory(this.site, settings.feedback_category_id))) {
      return false;
    }
    return path === "/" || path.startsWith("/latest") || path === officialPath || path.startsWith(`${officialPath}/`);
  }
  get exploreActive() {
    if (isFeedbackPath(this.router.currentURL, feedbackCategory(this.site, settings.feedback_category_id))) {
      return false;
    }
    return /^\/(search|categories|c|tag|tags)(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get notificationsActive() {
    return /\/notifications(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get calendarActive() {
    return (this.router.currentURL ?? "").startsWith("/isbf/calendar");
  }
  get workbenchActive() {
    return /^\/isbf\/(workbench|learning|alumni)(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get bookmarksActive() {
    return /\/activity\/bookmarks(\/|\?|$)/.test(this.router.currentURL ?? "");
  }
  get profileActive() {
    const path = this.router.currentURL ?? "";
    return /^\/u\//.test(path) && !this.notificationsActive && !this.bookmarksActive;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <aside
      aria-label={{i18n (themePrefix "isbf_v2.navigation_label")}}
      class="isbf-v2-side"
    >
      <ISBFV2Brand />
    
      <nav class="isbf-v2-side__links">
        <a
          aria-current={{if this.homeActive "page"}}
          class={{if this.homeActive "is-active"}}
          href="/latest"
        >{{dIcon "house"}}<span>{{i18n (themePrefix "isbf_v2.home")}}</span></a>
        <a
          aria-current={{if this.exploreActive "page"}}
          class={{if this.exploreActive "is-active"}}
          href="/categories"
        >{{dIcon "magnifying-glass"}}<span>{{i18n
              (themePrefix "isbf_v2.explore")
            }}</span></a>
        <a
          aria-current={{if this.notificationsActive "page"}}
          aria-label={{this.isbfNotifications.linkLabel}}
          class={{if this.notificationsActive "is-active"}}
          href={{this.notificationsHref}}
        ><ISBFNotificationBell /><span>{{i18n
              (themePrefix "isbf_v2.notifications")
            }}</span></a>
        <a
          aria-current={{if this.calendarActive "page"}}
          class={{if this.calendarActive "is-active"}}
          href="/isbf/calendar"
        >{{dIcon "calendar-days"}}<span>{{i18n
              (themePrefix "isbf_v2.calendar")
            }}</span></a>
        <a
          aria-current={{if this.workbenchActive "page"}}
          class={{if this.workbenchActive "is-active"}}
          href="/isbf/workbench"
        >{{dIcon "table-cells-large"}}<span>{{i18n
              (themePrefix "isbf_v2.workbench")
            }}</span></a>
        <a
          aria-current={{if this.bookmarksActive "page"}}
          class={{if this.bookmarksActive "is-active"}}
          href={{this.bookmarksHref}}
        >{{dIcon "bookmark"}}<span>{{i18n
              (themePrefix "isbf_v2.bookmarks")
            }}</span></a>
        <a
          aria-current={{if this.profileActive "page"}}
          class={{if this.profileActive "is-active"}}
          href={{this.profileHref}}
        >{{dIcon "user"}}<span>{{i18n
              (themePrefix "isbf_v2.profile")
            }}</span></a>
        <ISBFV2MoreMenu />
      </nav>
    
      <a class="isbf-v2-side__compose" href={{this.composeHref}}>{{i18n
          (themePrefix "isbf_v2.compose")
        }}</a>
    
      {{#if this.currentUser.can_review}}
        <a
          aria-label={{i18n (themePrefix "isbf_v2.review")}}
          class="isbf-v2-side__review"
          href="/review"
        >{{i18n (themePrefix "isbf_v2.review")}}</a>
      {{/if}}
    
      {{#if this.currentUser}}
        <ISBFV2AccountMenu />
      {{/if}}
    </aside>
    */
    {
      "id": null,
      "block": "[[[10,\"aside\"],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.navigation_label\"],null]],null]],[14,0,\"isbf-v2-side\"],[12],[1,\"\\n  \"],[8,[32,2],null,null,null],[1,\"\\n\\n  \"],[10,\"nav\"],[14,0,\"isbf-v2-side__links\"],[12],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"homeActive\"]],\"page\"]],[15,0,[52,[30,0,[\"homeActive\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,3],[\"house\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.home\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"exploreActive\"]],\"page\"]],[15,0,[52,[30,0,[\"exploreActive\"]],\"is-active\"]],[14,6,\"/categories\"],[12],[1,[28,[32,3],[\"magnifying-glass\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.explore\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"notificationsActive\"]],\"page\"]],[15,\"aria-label\",[30,0,[\"isbfNotifications\",\"linkLabel\"]]],[15,0,[52,[30,0,[\"notificationsActive\"]],\"is-active\"]],[15,6,[30,0,[\"notificationsHref\"]]],[12],[8,[32,4],null,null,null],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"calendarActive\"]],\"page\"]],[15,0,[52,[30,0,[\"calendarActive\"]],\"is-active\"]],[14,6,\"/isbf/calendar\"],[12],[1,[28,[32,3],[\"calendar-days\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"workbenchActive\"]],\"page\"]],[15,0,[52,[30,0,[\"workbenchActive\"]],\"is-active\"]],[14,6,\"/isbf/workbench\"],[12],[1,[28,[32,3],[\"table-cells-large\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.workbench\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"bookmarksActive\"]],\"page\"]],[15,0,[52,[30,0,[\"bookmarksActive\"]],\"is-active\"]],[15,6,[30,0,[\"bookmarksHref\"]]],[12],[1,[28,[32,3],[\"bookmark\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.bookmarks\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"profileActive\"]],\"page\"]],[15,0,[52,[30,0,[\"profileActive\"]],\"is-active\"]],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,3],[\"user\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.profile\"],null]],null]],[13],[13],[1,\"\\n    \"],[8,[32,5],null,null,null],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,3],[14,0,\"isbf-v2-side__compose\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.compose\"],null]],null]],[13],[1,\"\\n\\n\"],[41,[30,0,[\"currentUser\",\"can_review\"]],[[[1,\"    \"],[10,3],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.review\"],null]],null]],[14,0,\"isbf-v2-side__review\"],[14,6,\"/review\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.review\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"    \"],[8,[32,6],null,null,null],[1,\"\\n\"]],[]],null],[13]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        ISBFV2Brand,
        dIcon,
        ISBFNotificationBell,
        ISBFV2MoreMenu,
        ISBFV2AccountMenu
      }),
      "isStrictMode": true
    }), this);
  }
}