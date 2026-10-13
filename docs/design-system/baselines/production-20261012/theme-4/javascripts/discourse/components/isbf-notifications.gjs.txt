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
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { consumeInitialNotificationTab } from "../lib/notification-groups";
import { isUntitledTopicTitle } from "../lib/optional-topic-title";
import ISBFNotificationAction from "./isbf-notification-action";
import ISBFNotificationEntry from "./isbf-notification-entry";

export default class ISBFNotifications extends Component {
  @service appEvents;
  @service currentUser;
  @service modal;
  @service site;
  @service siteSettings;

  @tracked error = false;
  @tracked groups = [];
  @tracked loaded = false;
  @tracked loading = false;
  @tracked markingRead = false;
  @tracked markReadError = false;
  @tracked nextCursor = null;
  @tracked tab = "all";

  #generation = 0;
  #models = new Map();
  #markedReadAt = 0;

  constructor() {
    super(...arguments);
    this.tab = consumeInitialNotificationTab();
    this.appEvents.on("isbf:notification-tab", this, this.selectTab);
    scheduleOnce("afterRender", this, this.loadMore);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:notification-tab", this, this.selectTab);
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
        `isbf_v2.notification_${known.includes(actionName) ? actionName : "activity"}`,
      ),
    );
  }

  @action
  async loadMore() {
    if (this.loading || (this.loaded && !this.nextCursor)) {
      return;
    }
    const generation = this.#generation;
    this.loading = true;
    this.error = false;
    try {
      const response = await ajax("/isbf/notifications/groups.json", {
        data: { tab: this.tab, cursor: this.nextCursor, limit: 20 },
      });
      const raw = response.groups.flatMap((group) =>
        group.kind === "topic"
          ? group.actions.map((item) => item.latest.notification)
          : [group.latest.notification],
      );
      await this.#initializeModels(raw);
      if (this.#stale(generation)) {
        return;
      }
      const existing = new Set(this.groups.map((group) => group.key));
      const groups = response.groups
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
      this.groups = [...this.groups, ...groups];
      this.nextCursor = response.next_cursor;
      this.loaded = true;
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

  @action
  async prepareEntries(entries) {
    await this.#initializeModels(entries.map((entry) => entry.notification));
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
    this.#generation++;
    this.tab = tab;
    this.groups = [];
    this.nextCursor = null;
    this.loaded = false;
    this.loading = false;
    this.error = false;
    this.loadMore();
  }

  @action
  dismissNotifications() {
    const count = this.currentUser.unread_high_priority_notifications;
    if (count > 0) {
      this.modal.show(DismissNotificationConfirmationModal, {
        model: {
          confirmationMessage: i18n(
            "notifications.dismiss_confirmation.body.default",
            { count },
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
    try {
      await ajax("/notifications/mark-read", { type: "PUT" });
      if (this.isDestroying) {
        return;
      }
      this.#markedReadAt = Date.now();
      this.#models.forEach((notification) => notification.set("read", true));
      this.currentUser.set("grouped_unread_notifications", {});
      this.currentUser.set("unread_high_priority_notifications", 0);
      this.currentUser.set("unread_notifications", 0);
      this.markReadError = false;
    } catch {
      if (!this.isDestroying) {
        this.markReadError = true;
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

  async #initializeModels(raw) {
    const missing = [
      ...new Map(
        raw
          .filter((notification) => !this.#models.has(notification.id))
          .map((notification) => [notification.id, notification]),
      ).values(),
    ];
    const models = await Notification.initializeNotifications(missing);
    for (const model of models) {
      if (Date.parse(model.created_at) <= this.#markedReadAt) {
        model.set("read", true);
      }
      if (!this.#models.has(model.id)) {
        this.#models.set(model.id, model);
      }
    }
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
      {{#each this.groups key="key" as |group|}}
        {{#if group.topic}}
          <article class="isbf-notifications__topic">
            <h2><a href={{group.topic.url}}>{{this.topicTitle
                  group.topic.title
                }}</a></h2>
            {{#each group.actions key="key" as |item|}}
              <ISBFNotificationAction
                @actionLabel={{this.actionLabel}}
                @group={{item}}
                @prepareEntries={{this.prepareEntries}}
              />
            {{/each}}
          </article>
        {{else}}
          <article class="isbf-notifications__standalone"><ISBFNotificationEntry
              @entry={{group.latest}}
              @standalone={{true}}
            /></article>
        {{/if}}
      {{/each}}
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
            (themePrefix "isbf_v2.notifications_empty")
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
