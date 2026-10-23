import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { mergeEntries } from "../lib/notification-groups";
import ISBFNotificationEntry from "./isbf-notification-entry";
import ISBFNotificationUnread from "./isbf-notification-unread";

export default class ISBFNotificationAction extends Component {
  @tracked entries = [];
  @tracked error = false;
  @tracked expanded = false;
  @tracked loaded = false;
  @tracked loading = false;
  @tracked nextCursor = null;

  #generation = 0;

  get extraEntries() {
    return this.entries.filter(
      (entry) => entry.key !== this.args.group.latest.key
    );
  }

  get label() {
    const actionName = this.args.group.key;
    return i18n(themePrefix("isbf_v2.notification_action_count"), {
      action: this.args.actionLabel(actionName),
      count: this.args.group.count,
    });
  }

  get showDetails() {
    return (
      this.expanded &&
      (this.extraEntries.length > 0 || this.error || Boolean(this.nextCursor))
    );
  }

  @action
  async loadMore() {
    if (this.loading || (this.loaded && !this.nextCursor)) {
      return;
    }
    this.loading = true;
    this.error = false;
    const generation = this.#generation;
    try {
      const response = await ajax(this.args.group.detail_url, {
        data: { cursor: this.nextCursor, limit: 20 },
      });
      if (this.isDestroying || generation !== this.#generation) {
        return;
      }
      const entries = await this.args.prepareEntries(response.entries);
      if (this.isDestroying || generation !== this.#generation) {
        return;
      }
      this.entries = mergeEntries(this.entries, entries);
      this.nextCursor = response.next_cursor;
      this.loaded = true;
    } catch {
      if (!this.isDestroying && generation === this.#generation) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying && generation === this.#generation) {
        this.loading = false;
      }
    }
  }

  @action
  refresh() {
    this.#generation++;
    this.entries = [];
    this.nextCursor = null;
    this.loaded = false;
    this.loading = false;
    this.error = false;
    if (this.expanded) {
      this.loadMore();
    }
  }

  @action
  toggle() {
    this.expanded = !this.expanded;
    if (this.expanded && !this.loaded) {
      this.loadMore();
    }
  }

  <template>
    <section
      class="isbf-notification-action"
      {{didUpdate this.refresh @revision}}
    >
      <button
        aria-busy={{if this.loading "true" "false"}}
        aria-expanded={{if this.expanded "true" "false"}}
        class="isbf-notification-action__toggle"
        type="button"
        {{on "click" this.toggle}}
      >
        <span class="isbf-notification-action__label">
          {{#if @group.latest.item.icon}}
            {{dIcon @group.latest.item.icon}}
          {{/if}}
          <span>{{this.label}}</span>
          <ISBFNotificationUnread @unread={{@group.unread}} />
        </span>
        {{dIcon (if this.expanded "chevron-down" "chevron-right")}}
      </button>
      <ISBFNotificationEntry @entry={{@group.latest}} />
      <span class="sr-only" role="status">{{#if this.loading}}{{i18n
            (themePrefix "isbf_v2.notifications_loading")
          }}{{/if}}</span>
      {{#if this.showDetails}}
        <div class="isbf-notification-action__details">
          {{#each this.extraEntries key="key" as |entry|}}
            <ISBFNotificationEntry @entry={{entry}} />
          {{/each}}
          {{#if this.error}}
            <p role="alert">{{i18n
                (themePrefix "isbf_v2.notifications_error")
              }}</p>
            <DButton
              @action={{this.loadMore}}
              @label={{themePrefix "isbf_v2.notifications_retry"}}
            />
          {{else if this.nextCursor}}
            <DButton
              @action={{this.loadMore}}
              @isLoading={{this.loading}}
              @label={{themePrefix "isbf_v2.load_more"}}
            />
          {{/if}}
        </div>
      {{/if}}
    </section>
  </template>
}
