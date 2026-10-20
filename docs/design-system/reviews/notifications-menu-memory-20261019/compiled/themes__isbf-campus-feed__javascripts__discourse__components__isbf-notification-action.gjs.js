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
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFNotificationAction extends Component {
  static {
    g(this.prototype, "entries", [tracked], function () {
      return [];
    });
  }
  #entries = (i(this, "entries"), void 0);
  static {
    g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (i(this, "error"), void 0);
  static {
    g(this.prototype, "expanded", [tracked], function () {
      return false;
    });
  }
  #expanded = (i(this, "expanded"), void 0);
  static {
    g(this.prototype, "loaded", [tracked], function () {
      return false;
    });
  }
  #loaded = (i(this, "loaded"), void 0);
  static {
    g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (i(this, "loading"), void 0);
  static {
    g(this.prototype, "nextCursor", [tracked], function () {
      return null;
    });
  }
  #nextCursor = (i(this, "nextCursor"), void 0);
  #generation = 0;
  get extraEntries() {
    return this.entries.filter(entry => entry.key !== this.args.group.latest.key);
  }
  get label() {
    const actionName = this.args.group.key;
    return i18n(themePrefix("isbf_v2.notification_action_count"), {
      action: this.args.actionLabel(actionName),
      count: this.args.group.count
    });
  }
  get showDetails() {
    return this.expanded && (this.extraEntries.length > 0 || this.error || Boolean(this.nextCursor));
  }
  async loadMore() {
    if (this.loading || this.loaded && !this.nextCursor) {
      return;
    }
    this.loading = true;
    this.error = false;
    const generation = this.#generation;
    try {
      const response = await ajax(this.args.group.detail_url, {
        data: {
          cursor: this.nextCursor,
          limit: 20
        }
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
  static {
    n(this.prototype, "loadMore", [action]);
  }
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
  static {
    n(this.prototype, "refresh", [action]);
  }
  toggle() {
    this.expanded = !this.expanded;
    if (this.expanded && !this.loaded) {
      this.loadMore();
    }
  }
  static {
    n(this.prototype, "toggle", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
    */
    {
      "id": null,
      "block": "[[[11,\"section\"],[24,0,\"isbf-notification-action\"],[4,[32,0],[[30,0,[\"refresh\"]],[30,1]],null],[12],[1,\"\\n  \"],[11,\"button\"],[16,\"aria-busy\",[52,[30,0,[\"loading\"]],\"true\",\"false\"]],[16,\"aria-expanded\",[52,[30,0,[\"expanded\"]],\"true\",\"false\"]],[24,0,\"isbf-notification-action__toggle\"],[24,4,\"button\"],[4,[32,1],[\"click\",[30,0,[\"toggle\"]]],null],[12],[1,\"\\n    \"],[10,1],[14,0,\"isbf-notification-action__label\"],[12],[1,\"\\n\"],[41,[30,2,[\"latest\",\"item\",\"icon\"]],[[[1,\"        \"],[1,[28,[32,2],[[30,2,[\"latest\",\"item\",\"icon\"]]],null]],[1,\"\\n\"]],[]],null],[1,\"      \"],[10,1],[12],[1,[30,0,[\"label\"]]],[13],[1,\"\\n      \"],[8,[32,3],null,[[\"@unread\"],[[30,2,[\"unread\"]]]],null],[1,\"\\n    \"],[13],[1,\"\\n    \"],[1,[28,[32,2],[[52,[30,0,[\"expanded\"]],\"chevron-down\",\"chevron-right\"]],null]],[1,\"\\n  \"],[13],[1,\"\\n  \"],[8,[32,4],null,[[\"@entry\"],[[30,2,[\"latest\"]]]],null],[1,\"\\n  \"],[10,1],[14,0,\"sr-only\"],[14,\"role\",\"status\"],[12],[41,[30,0,[\"loading\"]],[[[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.notifications_loading\"],null]],null]]],[]],null],[13],[1,\"\\n\"],[41,[30,0,[\"showDetails\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-notification-action__details\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"extraEntries\"]]],null]],null],\"key\",[[[1,\"        \"],[8,[32,4],null,[[\"@entry\"],[[30,3]]],null],[1,\"\\n\"]],[3]],null],[41,[30,0,[\"error\"]],[[[1,\"        \"],[10,2],[14,\"role\",\"alert\"],[12],[1,[28,[32,5],[[28,[32,6],[\"isbf_v2.notifications_error\"],null]],null]],[13],[1,\"\\n        \"],[8,[32,7],null,[[\"@action\",\"@label\"],[[30,0,[\"loadMore\"]],[28,[32,6],[\"isbf_v2.notifications_retry\"],null]]],null],[1,\"\\n\"]],[]],[[[41,[30,0,[\"nextCursor\"]],[[[1,\"        \"],[8,[32,7],null,[[\"@action\",\"@isLoading\",\"@label\"],[[30,0,[\"loadMore\"]],[30,0,[\"loading\"]],[28,[32,6],[\"isbf_v2.load_more\"],null]]],null],[1,\"\\n      \"]],[]],null]],[]]],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[13]],[\"@revision\",\"@group\",\"entry\"],[\"if\",\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        didUpdate,
        on,
        dIcon,
        ISBFNotificationUnread,
        ISBFNotificationEntry,
        i18n,
        themePrefix,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}