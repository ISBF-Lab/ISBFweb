import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import {
  OFFICIAL_CALENDAR_FIELD,
  officialTimeLabel,
} from "../lib/official-calendar";

export default class ISBFOfficialCalendarItems extends Component {
  @service appEvents;
  @service currentUser;
  @service router;

  @tracked error = false;
  @tracked _busyId = null;
  @tracked _entryIds = {};
  @tracked _refreshedItems = null;

  constructor() {
    super(...arguments);
    this.appEvents.on("isbf:calendar-entry-changed", this.onEntryChanged);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:calendar-entry-changed", this.onEntryChanged);
  }

  get items() {
    const source =
      this._refreshedItems ??
      this.args.items ??
      this.args.outletArgs?.post?.[OFFICIAL_CALENDAR_FIELD] ??
      [];
    return source.map((item) => ({
      ...item,
      timeLabel: officialTimeLabel(item),
      added: Boolean(
        Object.hasOwn(this._entryIds, item.id)
          ? this._entryIds[item.id]
          : item.personal_entry_id
      ),
      busy: this._busyId === item.id,
    }));
  }

  @action
  onEntryChanged({ source_item_id, id, removed }) {
    if (source_item_id) {
      this._entryIds = {
        ...this._entryIds,
        [source_item_id]: removed ? null : id,
      };
    }
  }

  @action
  async add(item) {
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    if (this._busyId || item.added || item.cancelled) {
      return;
    }
    this._busyId = item.id;
    this.error = false;
    try {
      const { entry } = await ajax(
        `/isbf/api/official-items/${item.id}/add.json`,
        { type: "POST", data: { revision: item.revision } }
      );
      this.appEvents.trigger("isbf:calendar-entry-changed", entry);
    } catch (error) {
      if (!this.isDestroying) {
        this.error = true;
        if (error.jqXHR?.status === 409 && this.args.outletArgs?.post?.id) {
          try {
            const post = await ajax(
              `/posts/${this.args.outletArgs.post.id}.json`
            );
            if (!this.isDestroying) {
              this._refreshedItems = post[OFFICIAL_CALENDAR_FIELD] ?? [];
            }
          } catch {
            this.error = true;
          }
        }
      }
    } finally {
      if (!this.isDestroying) {
        this._busyId = null;
      }
    }
  }

  <template>
    {{#if this.items.length}}
      <section
        aria-label={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
        class="isbf-official-calendar-items"
      >
        {{#each this.items key="id" as |item|}}
          <div
            class="isbf-official-calendar-items__item"
            data-schedule-id={{item.id}}
          >
            <div class="isbf-official-calendar-items__information"><strong
              >{{item.title}}</strong><span>{{item.timeLabel}}</span></div>
            {{#unless @readOnly}}
              <DButton
                @action={{fn this.add item}}
                @disabled={{or item.added item.busy item.cancelled}}
                @icon={{if item.added "check" "calendar-days"}}
                @label={{themePrefix
                  (if
                    item.added "isbf_v2.schedule_added" "isbf_v2.schedule_add"
                  )
                }}
              />
            {{/unless}}
          </div>
        {{/each}}
        {{#if this.error}}<p
            class="isbf-official-calendar-items__error"
            role="alert"
          >{{i18n (themePrefix "isbf_v2.schedule_add_error")}}</p>{{/if}}
      </section>
    {{/if}}
  </template>
}
