import { tracked } from "@glimmer/tracking";
import { scheduleOnce } from "@ember/runloop";
import Service, { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

export default class ISBFNotifications extends Service {
  @service a11y;
  @service appEvents;
  @service currentUser;
  @service messageBus;
  @service siteSettings;

  @tracked filterError = false;
  @tracked savingFilter = false;
  @tracked savingStyle = false;
  @tracked styleError = false;

  version = 0;

  #channel;
  #requestedFilter;
  #requestedStyle;

  constructor() {
    super(...arguments);
    if (this.currentUser && this.siteSettings.isbf_notifications_enabled) {
      this.#channel = `/notification/${this.currentUser.id}`;
      this.messageBus.subscribe(this.#channel, this.onNotification);
      this.appEvents.on(
        "user-menu:notification-click",
        this,
        this.onNotificationClick
      );
    }
  }

  willDestroy() {
    if (this.#channel) {
      this.messageBus.unsubscribe(this.#channel, this.onNotification);
      this.appEvents.off(
        "user-menu:notification-click",
        this,
        this.onNotificationClick
      );
    }
    super.willDestroy(...arguments);
  }

  get displayCount() {
    return this.unreadCount > 99 ? "99+" : this.unreadCount;
  }

  get dotStyle() {
    return this.currentUser?.get("isbf_notification_badge_style") === "dot";
  }

  get filter() {
    return this.currentUser?.get("isbf_notification_filter") === "unread"
      ? "unread"
      : "all";
  }

  get linkLabel() {
    if (!this.unreadCount) {
      return i18n(themePrefix("isbf_v2.notifications"));
    }
    return i18n(
      themePrefix(
        this.unreadCount > 99
          ? "isbf_v2.notifications_badge_many"
          : "isbf_v2.notifications_badge_count"
      ),
      { count: this.unreadCount }
    );
  }

  get numberStyle() {
    return !this.dotStyle;
  }

  get unreadCount() {
    if (!this.currentUser || !this.siteSettings.isbf_notifications_enabled) {
      return 0;
    }
    // The header's counters exclude notices seen in a menu but still unread.
    return Object.values(
      this.currentUser.get("grouped_unread_notifications") || {}
    ).reduce((total, count) => total + Math.max(0, Number(count) || 0), 0);
  }

  @bind
  onNotification(data) {
    this.version++;
    this.currentUser.set(
      "grouped_unread_notifications",
      data.grouped_unread_notifications
    );
    this.appEvents.trigger("isbf:notifications-updated", data);
  }

  onNotificationClick() {
    scheduleOnce("actions", this, this.#notifyLocalChange);
  }

  @bind
  retryBadgeStyle() {
    return this.saveBadgeStyle(this.#requestedStyle);
  }

  @bind
  retryFilter() {
    return this.saveFilter(this.#requestedFilter);
  }

  @bind
  async saveBadgeStyle(style) {
    if (
      !this.currentUser ||
      this.savingStyle ||
      !["number", "dot"].includes(style)
    ) {
      return;
    }
    const userId = this.currentUser.id;
    this.#requestedStyle = style;
    this.savingStyle = true;
    this.styleError = false;
    try {
      await ajax(`/u/${encodeURIComponent(this.currentUser.username)}.json`, {
        type: "PUT",
        data: { custom_fields: { isbf_notification_badge_style: style } },
      });
      if (!this.isDestroying && this.currentUser?.id === userId) {
        this.currentUser.set("isbf_notification_badge_style", style);
      }
    } catch {
      if (!this.isDestroying) {
        this.styleError = true;
        this.a11y.announce(
          i18n(themePrefix("isbf_v2.notifications_badge_error")),
          "assertive"
        );
      }
    } finally {
      if (!this.isDestroying) {
        this.savingStyle = false;
      }
    }
  }

  @bind
  async saveFilter(filter) {
    if (
      !this.currentUser ||
      this.savingFilter ||
      !["all", "unread"].includes(filter)
    ) {
      return;
    }
    const userId = this.currentUser.id;
    this.#requestedFilter = filter;
    this.savingFilter = true;
    this.filterError = false;
    try {
      await ajax(`/u/${encodeURIComponent(this.currentUser.username)}.json`, {
        type: "PUT",
        data: { custom_fields: { isbf_notification_filter: filter } },
      });
      if (!this.isDestroying && this.currentUser?.id === userId) {
        this.currentUser.set("isbf_notification_filter", filter);
        this.appEvents.trigger("isbf:notification-filter-changed");
      }
    } catch {
      if (!this.isDestroying && this.currentUser?.id === userId) {
        this.filterError = true;
        this.a11y.announce(
          i18n(themePrefix("isbf_v2.notifications_filter_error")),
          "assertive"
        );
      }
    } finally {
      if (!this.isDestroying) {
        this.savingFilter = false;
      }
    }
  }

  #notifyLocalChange() {
    if (!this.isDestroying) {
      this.appEvents.trigger("isbf:notifications-updated");
    }
  }
}
