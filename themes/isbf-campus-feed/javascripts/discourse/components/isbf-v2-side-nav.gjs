import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  feedbackCategory,
  feedbackComposeHref,
  isFeedbackPath,
} from "../lib/feedback-category";
import ISBFV2AccountMenu from "./isbf-v2-account-menu";
import ISBFV2Brand from "./isbf-v2-brand";
import ISBFV2MoreMenu from "./isbf-v2-more-menu";

export default class ISBFV2SideNav extends Component {
  @service currentUser;
  @service router;
  @service site;

  get composeHref() {
    const category = feedbackCategory(this.site, settings.feedback_category_id);
    return isFeedbackPath(this.router.currentURL, category)
      ? feedbackComposeHref(category)
      : "/new-topic";
  }

  get bookmarksHref() {
    return this.currentUser
      ? `/u/${this.currentUser.username}/activity/bookmarks`
      : "/login";
  }

  get notificationsHref() {
    return this.currentUser
      ? `/u/${this.currentUser.username}/notifications`
      : "/login";
  }

  get profileHref() {
    return this.currentUser ? `/u/${this.currentUser.username}` : "/login";
  }

  get homeActive() {
    const path = this.router.currentURL ?? "";
    const officialPath = settings.official_path.split("/l/")[0];
    if (
      isFeedbackPath(
        path,
        feedbackCategory(this.site, settings.feedback_category_id)
      )
    ) {
      return false;
    }

    return (
      path === "/" ||
      path.startsWith("/latest") ||
      path === officialPath ||
      path.startsWith(`${officialPath}/`)
    );
  }

  get exploreActive() {
    if (
      isFeedbackPath(
        this.router.currentURL,
        feedbackCategory(this.site, settings.feedback_category_id)
      )
    ) {
      return false;
    }
    return /^\/(search|categories|c|tag|tags)(\/|\?|$)/.test(
      this.router.currentURL ?? ""
    );
  }

  get notificationsActive() {
    return /\/notifications(\/|\?|$)/.test(this.router.currentURL ?? "");
  }

  get calendarActive() {
    return (this.router.currentURL ?? "").startsWith("/isbf/calendar");
  }

  get workbenchActive() {
    return /^\/isbf\/(workbench|learning|alumni)(\/|\?|$)/.test(
      this.router.currentURL ?? ""
    );
  }

  get bookmarksActive() {
    return /\/activity\/bookmarks(\/|\?|$)/.test(this.router.currentURL ?? "");
  }

  get profileActive() {
    const path = this.router.currentURL ?? "";
    return (
      /^\/u\//.test(path) && !this.notificationsActive && !this.bookmarksActive
    );
  }

  <template>
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
          class={{if this.notificationsActive "is-active"}}
          href={{this.notificationsHref}}
        >{{dIcon "bell"}}<span>{{i18n
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
  </template>
}
