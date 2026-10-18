import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DismissNotificationConfirmationModal from "discourse/components/modal/dismiss-notification-confirmation";
import { ajax } from "discourse/lib/ajax";
import UserMenuNotificationItem from "discourse/lib/user-menu/notification-item";
import Notification from "discourse/models/notification";
import DButton from "discourse/ui-kit/d-button";
import DToggleSwitch from "discourse/ui-kit/d-toggle-switch";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { consumeInitialNotificationTab } from "../lib/notification-groups";
import { isUntitledTopicTitle } from "../lib/optional-topic-title";
import ISBFNotificationAction from "./isbf-notification-action";
import ISBFNotificationEntry from "./isbf-notification-entry";

export default class ISBFNotifications extends Component {
  @service a11y;
  @service appEvents;
  @service currentUser;
  @service isbfNotifications;
  @service modal;
  @service site;
  @service siteSettings;

  @tracked error = false;
  @tracked filter = "all";
  @tracked groups = [];
  @tracked loaded = false;
  @tracked loading = false;
  @tracked markingRead = false;
  @tracked markReadError = false;
  @tracked nextCursor = null;
  @tracked revision = 0;
  @tracked tab = "all";

  #generation = 0;
  #models = new Map();

  constructor() {
    super(...arguments);
    this.tab = consumeInitialNotificationTab();
    this.appEvents.on("isbf:notification-tab", this, this.selectTab);
    this.appEvents.on(
      "isbf:notifications-updated",
      this,
      this.onNotificationUpdate
    );
    scheduleOnce("afterRender", this, this.loadMore);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:notification-tab", this, this.selectTab);
    this.appEvents.off(
      "isbf:notifications-updated",
      this,
      this.onNotificationUpdate
    );
  }

  get allSelected() {
    return this.tab === "all";
  }

  get mentionsSelected() {
    return this.tab === "mentions";
  }

  get isEmpty() {
    return this.loaded && !this.groups.length;
  }

  get unreadOnly() {
    return this.filter === "unread";
  }

  @action
  actionLabel(actionName) {
    const known = [
      "liked",
      "reaction",
      "replied",
      "mentioned",
      "group_mentioned",
    ];
    return i18n(
      themePrefix(
        `isbf_v2.notification_${known.includes(actionName) ? actionName : "activity"}`
      )
    );
  }

  @action
  loadMore() {
    return this.#loadGroups(false);
  }

  @action
  refresh() {
    return this.#loadGroups(true);
  }

  @action
  onNotificationUpdate(data) {
    for (const [id, read] of data?.recent || []) {
      this.#models.get(id)?.set("read", read);
    }
    scheduleOnce("afterRender", this, this.refresh);
  }

  @action
  async prepareEntries(entries) {
    const generation = this.#generation;
    await this.#initializeModels(
      entries.map((entry) => entry.notification),
      generation
    );
    if (this.#stale(generation)) {
      return [];
    }
    return entries.map((entry) => this.prepareEntry(entry));
  }

  @action
  prepareEntry(entry) {
    const notification = this.#models.get(entry.notification.id);
    const item = new UserMenuNotificationItem({
      notification,
      appEvents: this.appEvents,
      currentUser: this.currentUser,
      site: this.site,
      siteSettings: this.siteSettings,
    });
    return {
      ...entry,
      notification,
      item,
      actionLabel: this.actionLabel(entry.action),
    };
  }

  @action
  selectTab(tab) {
    if (this.tab === tab) {
      return;
    }
    this.tab = tab;
    this.#reset();
  }

  @action
  toggleUnreadOnly() {
    this.filter = this.unreadOnly ? "all" : "unread";
    this.#reset();
  }

  @action
  dismissNotifications() {
    const count = this.currentUser.unread_high_priority_notifications;
    if (count > 0) {
      this.modal.show(DismissNotificationConfirmationModal, {
        model: {
          confirmationMessage: i18n(
            "notifications.dismiss_confirmation.body.default",
            { count }
          ),
          dismissNotifications: this.markRead,
        },
      });
    } else {
      this.markRead();
    }
  }

  @action
  async markRead() {
    if (this.markingRead) {
      return;
    }
    this.markingRead = true;
    this.markReadError = false;
    const version = this.isbfNotifications.version;
    try {
      await ajax("/notifications/mark-read", { type: "PUT" });
      if (this.isDestroying) {
        return;
      }
      // A notification state received during this request may include a newer notice.
      if (this.isbfNotifications.version === version) {
        this.#models.forEach((notification) => notification.set("read", true));
        this.currentUser.setProperties({
          grouped_unread_notifications: {},
          unread_high_priority_notifications: 0,
          unread_notifications: 0,
          all_unread_notifications_count: 0,
        });
      }
      this.markReadError = false;
      this.refresh();
    } catch {
      if (!this.isDestroying) {
        this.markReadError = true;
        this.a11y.announce(
          i18n(themePrefix("isbf_v2.action_failed")),
          "assertive"
        );
      }
    } finally {
      if (!this.isDestroying) {
        this.markingRead = false;
      }
    }
  }

  @action
  onMenuKeydown(event) {
    if (event.key === "Escape") {
      event.currentTarget.open = false;
      event.currentTarget.querySelector("summary")?.focus();
      event.preventDefault();
    }
  }

  @action
  topicTitle(title) {
    return isUntitledTopicTitle(title)
      ? i18n(themePrefix("isbf_v2.untitled_topic"))
      : title;
  }

  async #initializeModels(raw, generation) {
    const missing = [
      ...new Map(
        raw
          .filter((notification) => !this.#models.has(notification.id))
          .map((notification) => [notification.id, notification])
      ).values(),
    ];
    const models = await Notification.initializeNotifications(missing);
    if (this.#stale(generation)) {
      return;
    }
    for (const model of models) {
      if (!this.#models.has(model.id)) {
        this.#models.set(model.id, model);
      }
    }
    for (const notification of raw) {
      this.#models.get(notification.id).setProperties(notification);
    }
  }

  async #loadGroups(refresh) {
    if (
      this.isDestroying ||
      (!refresh && (this.loading || (this.loaded && !this.nextCursor)))
    ) {
      return;
    }
    if (refresh) {
      this.#generation++;
    }
    const generation = this.#generation;
    const target = refresh ? Math.max(this.groups.length, 20) : 0;
    let cursor = refresh ? null : this.nextCursor;
    const incoming = [];
    this.loading = true;
    this.error = false;
    try {
      do {
        const response = await ajax("/isbf/notifications/groups.json", {
          data: { tab: this.tab, filter: this.filter, cursor, limit: 20 },
        });
        if (this.#stale(generation)) {
          return;
        }
        incoming.push(...response.groups);
        cursor = response.next_cursor;
      } while (refresh && cursor && incoming.length < target);
      await this.#initializeModels(
        incoming.flatMap((group) =>
          group.kind === "topic"
            ? group.actions.map((item) => item.latest.notification)
            : [group.latest.notification]
        ),
        generation
      );
      if (this.#stale(generation)) {
        return;
      }
      const existing = new Set(
        refresh ? [] : this.groups.map((group) => group.key)
      );
      const groups = incoming
        .filter((group) => !existing.has(group.key))
        .map((group) => ({
          ...group,
          ...(group.kind === "topic"
            ? {
                actions: group.actions.map((item) => ({
                  ...item,
                  latest: this.prepareEntry(item.latest),
                })),
              }
            : { latest: this.prepareEntry(group.latest) }),
        }));
      this.groups = refresh ? groups : [...this.groups, ...groups];
      this.nextCursor = cursor;
      this.loaded = true;
      if (this.unreadOnly && !this.groups.length) {
        this.a11y.announce(
          i18n(themePrefix("isbf_v2.notifications_unread_empty"))
        );
      }
      if (refresh) {
        this.revision++;
      }
    } catch {
      if (!this.#stale(generation)) {
        this.error = true;
      }
    } finally {
      if (!this.#stale(generation)) {
        this.loading = false;
      }
    }
  }

  #reset() {
    this.#generation++;
    this.groups = [];
    this.nextCursor = null;
    this.loaded = false;
    this.loading = false;
    this.error = false;
    this.loadMore();
  }

  #stale(generation) {
    return this.isDestroying || generation !== this.#generation;
  }

  <template>
    <main class="isbf-notifications">
      <header class="isbf-notifications__heading">
        <h1>{{i18n (themePrefix "isbf_v2.notifications")}}</h1>
        <details
          class="isbf-notifications__menu"
          {{on "keydown" this.onMenuKeydown}}
        >
          <summary
            aria-label={{i18n (themePrefix "isbf_v2.notifications_menu")}}
          >{{dIcon "ellipsis"}}</summary>
          <div class="isbf-notifications__menu-items">
            <DButton
              @action={{this.dismissNotifications}}
              @disabled={{this.markingRead}}
              @label={{themePrefix "isbf_v2.notifications_mark_read"}}
            />
            <a href="/my/preferences/notifications">{{i18n
                (themePrefix "isbf_v2.notifications_settings")
              }}</a>
            <div class="isbf-notifications__filter">
              <DToggleSwitch
                @label={{themePrefix "isbf_v2.notifications_unread_only"}}
                @state={{this.unreadOnly}}
                {{on "click" this.toggleUnreadOnly}}
              />
            </div>
            <div
              aria-label={{i18n
                (themePrefix "isbf_v2.notifications_badge_style")
              }}
              class="isbf-notifications__badge-options"
              role="group"
            >
              <p>{{i18n (themePrefix "isbf_v2.notifications_badge_style")}}</p>
              <DButton
                @action={{fn this.isbfNotifications.saveBadgeStyle "number"}}
                @ariaPressed={{this.isbfNotifications.numberStyle}}
                @disabled={{this.isbfNotifications.savingStyle}}
                @label={{themePrefix "isbf_v2.notifications_badge_number"}}
              />
              <DButton
                @action={{fn this.isbfNotifications.saveBadgeStyle "dot"}}
                @ariaPressed={{this.isbfNotifications.dotStyle}}
                @disabled={{this.isbfNotifications.savingStyle}}
                @label={{themePrefix "isbf_v2.notifications_badge_dot"}}
              />
            </div>
            {{#if this.isbfNotifications.styleError}}
              <div class="isbf-notifications__preference-error" role="alert">
                <p>{{i18n
                    (themePrefix "isbf_v2.notifications_badge_error")
                  }}</p>
                <DButton
                  @action={{this.isbfNotifications.retryBadgeStyle}}
                  @disabled={{this.isbfNotifications.savingStyle}}
                  @label={{themePrefix "isbf_v2.notifications_retry"}}
                />
              </div>
            {{/if}}
          </div>
        </details>
      </header>
      <div
        aria-label={{i18n (themePrefix "isbf_v2.notifications_tabs")}}
        class="isbf-notifications__tabs"
        role="group"
      >
        <button
          aria-pressed={{if this.allSelected "true" "false"}}
          class={{if this.allSelected "is-active"}}
          type="button"
          {{on "click" (fn this.selectTab "all")}}
        >{{i18n (themePrefix "isbf_v2.notifications_all")}}</button>
        <button
          aria-pressed={{if this.mentionsSelected "true" "false"}}
          class={{if this.mentionsSelected "is-active"}}
          type="button"
          {{on "click" (fn this.selectTab "mentions")}}
        >{{i18n (themePrefix "isbf_v2.notifications_mentions")}}</button>
      </div>
      {{#if this.markReadError}}<div
          class="isbf-notifications__status"
          role="alert"
        ><p>{{i18n (themePrefix "isbf_v2.action_failed")}}</p><DButton
            @action={{this.markRead}}
            @label={{themePrefix "isbf_v2.notifications_retry"}}
          /></div>{{/if}}
      {{#if this.groups.length}}
        <div class="isbf-notifications__groups">
          {{#each this.groups key="key" as |group|}}
            {{#if group.topic}}
              <article class="isbf-notifications__topic">
                <h2 class="isbf-notifications__topic-title"><a
                    href={{group.topic.url}}
                  >{{this.topicTitle group.topic.title}}</a></h2>
                {{#each group.actions key="key" as |item|}}
                  <ISBFNotificationAction
                    @actionLabel={{this.actionLabel}}
                    @group={{item}}
                    @prepareEntries={{this.prepareEntries}}
                    @revision={{this.revision}}
                  />
                {{/each}}
              </article>
            {{else}}
              <article
                class="isbf-notifications__standalone"
              ><ISBFNotificationEntry
                  @entry={{group.latest}}
                  @standalone={{true}}
                /></article>
            {{/if}}
          {{/each}}
        </div>
      {{/if}}
      {{#if this.loading}}<p
          class="isbf-notifications__status"
          role="status"
        >{{i18n (themePrefix "isbf_v2.notifications_loading")}}</p>{{/if}}
      {{#if this.error}}
        <div class="isbf-notifications__status" role="alert"><p>{{i18n
              (themePrefix "isbf_v2.notifications_error")
            }}</p><DButton
            @action={{this.loadMore}}
            @label={{themePrefix "isbf_v2.notifications_retry"}}
          /></div>
      {{else if this.isEmpty}}<p class="isbf-notifications__status">{{i18n
            (themePrefix
              (if
                this.unreadOnly
                "isbf_v2.notifications_unread_empty"
                "isbf_v2.notifications_empty"
              )
            )
          }}</p>{{/if}}
      {{#if this.nextCursor}}<DButton
          class="isbf-notifications__more"
          @action={{this.loadMore}}
          @isLoading={{this.loading}}
          @label={{themePrefix "isbf_v2.load_more"}}
        />{{/if}}
    </main>
  </template>
}
