import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import ISBFV2AccountMenu from "./isbf-v2-account-menu";
import ISBFV2AnonymousPosts from "./isbf-v2-anonymous-posts";
import ISBFV2Calendar from "./isbf-v2-calendar";
import ISBFV2RightRail from "./isbf-v2-right-rail";
import ISBFV2SideNav from "./isbf-v2-side-nav";
import ISBFV2Workbench from "./isbf-v2-workbench";

export default class ISBFV2Shell extends Component {
  @service currentUser;
  @service router;

  get path() {
    return (this.router.currentURL ?? "").split("?")[0];
  }

  get pageKind() {
    const path = this.path;

    if (/^\/(admin|login|signup|session)(\/|$)/.test(path)) {
      return null;
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
    if (path === "/isbf/workbench") {
      return "workbench";
    }
    if (/^\/u\/[^/]+\/notifications(\/|$)/.test(path)) {
      return "notifications";
    }
    if (/^\/u\/[^/]+\/activity\/bookmarks(\/|$)/.test(path)) {
      return "bookmarks";
    }
    if (/^\/u\//.test(path)) {
      return "profile";
    }
    if (this.#isOfficialPath(path)) {
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

  get isNotifications() {
    return this.pageKind === "notifications";
  }

  get isAnonymousPosts() {
    return this.pageKind === "anonymous-posts";
  }

  get isCalendar() {
    return this.pageKind === "calendar";
  }

  get isWorkbench() {
    return this.pageKind === "workbench";
  }

  get showRightRail() {
    return (
      settings.show_right_rail &&
      !this.isCalendar &&
      !this.isWorkbench &&
      !this.isAnonymousPosts
    );
  }

  get isOwnProfile() {
    if (this.pageKind !== "profile" || !this.currentUser) {
      return false;
    }

    const profilePath =
      `/u/${encodeURIComponent(this.currentUser.username)}`.toLowerCase();
    const path = this.path.toLowerCase();
    return path === profilePath || path.startsWith(`${profilePath}/`);
  }

  get pageTitle() {
    const titles = {
      "anonymous-posts": "my_anonymous_posts",
      bookmarks: "bookmarks",
      calendar: "calendar",
      explore: "explore",
      notifications: "notifications",
      profile: "profile",
      topic: "topic",
      workbench: "workbench",
    };

    return i18n(themePrefix("isbf_v2." + titles[this.pageKind]));
  }

  get latestActive() {
    return this.path === "/" || this.path.startsWith("/latest");
  }

  get officialActive() {
    return this.#isOfficialPath(this.path);
  }

  get canCompose() {
    return !this.officialActive || Boolean(this.currentUser?.staff);
  }

  get composeHref() {
    const categorySlug = settings.official_path.split("/")[2];
    return this.officialActive
      ? `/new-topic?category=${encodeURIComponent(categorySlug)}`
      : "/new-topic";
  }

  get shellClass() {
    const classes = ["isbf-v2-shell", `isbf-v2-shell--${this.pageKind}`];

    if (!this.canCompose) {
      classes.push("isbf-v2-shell--no-compose");
    }

    return classes.join(" ");
  }

  get profileHref() {
    return this.currentUser ? "/u/" + this.currentUser.username : "/login";
  }

  get notificationsHref() {
    return this.currentUser
      ? "/u/" + this.currentUser.username + "/notifications"
      : "/login";
  }

  #isOfficialPath(path) {
    const categoryPath = settings.official_path.split("/l/")[0];
    return path === categoryPath || path.startsWith(`${categoryPath}/`);
  }

  <template>
    {{#if this.pageKind}}
      <div class={{this.shellClass}}>
        <ISBFV2SideNav />
        {{#if this.showRightRail}}<ISBFV2RightRail />{{/if}}

        {{#if this.isFeed}}
          <header class="isbf-v2-feed-header">
            <div class="isbf-v2-feed-header__title">
              {{#if this.currentUser}}
                <a
                  aria-label={{i18n (themePrefix "isbf_v2.profile")}}
                  class="isbf-v2-feed-header__avatar"
                  href={{this.profileHref}}
                >{{dAvatar this.currentUser imageSize="small"}}</a>
              {{/if}}
              <span>{{i18n (themePrefix "isbf_v2.home")}}</span>
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

          {{#if this.canCompose}}
            <div class="isbf-v2-compose">
              {{#if this.currentUser}}
                <a
                  aria-label={{this.currentUser.username}}
                  class="isbf-v2-compose__avatar"
                  href={{this.profileHref}}
                >{{dAvatar this.currentUser imageSize="large"}}</a>
              {{/if}}
              <a
                class="isbf-v2-compose__prompt"
                href={{this.composeHref}}
              >{{i18n (themePrefix "isbf_v2.compose_prompt")}}</a>
              <a
                class="isbf-v2-compose__button"
                href={{this.composeHref}}
              >{{i18n (themePrefix "isbf_v2.compose")}}</a>
            </div>
          {{/if}}
        {{else}}
          <header class="isbf-v2-page-header">
            <a
              aria-label={{i18n (themePrefix "isbf_v2.back_home")}}
              class="isbf-v2-page-header__back"
              href="/latest"
            >{{dIcon "arrow-left"}}</a>
            <span>{{this.pageTitle}}</span>
            {{#if this.isOwnProfile}}<ISBFV2AccountMenu
                @mobile={{true}}
              />{{/if}}
          </header>
        {{/if}}

        {{#if this.isAnonymousPosts}}<ISBFV2AnonymousPosts />{{/if}}
        {{#if this.isCalendar}}<ISBFV2Calendar />{{/if}}
        {{#if this.isWorkbench}}<ISBFV2Workbench />{{/if}}

        {{#if this.canCompose}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.compose")}}
            class="isbf-v2-mobile-compose"
            href={{this.composeHref}}
          >{{dIcon "plus"}}</a>
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
            class={{if this.isNotifications "is-active"}}
            href={{this.notificationsHref}}
          >{{dIcon "bell"}}<span>{{i18n
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
  </template>
}
