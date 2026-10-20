import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import I18n, { i18n } from "discourse-i18n";
import { officialDateKey, officialOccursOn, officialTimeLabel } from "../lib/official-calendar";
import ISBFCalendarEntryEditor from "./isbf-calendar-entry-editor";
import ISBFCalendarNoteEditor from "./isbf-calendar-note-editor";
import ISBFCalendarUpdateDialog from "./isbf-calendar-update-dialog";
import { on as __keyword__on } from "@ember/modifier";
import { eq as __keyword__eq, fn as __keyword__fn } from "@ember/helper";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
const WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
function dateKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
function localDate(key) {
  return new Date(`${key}T12:00:00`);
}
function displayTime(value, allDay) {
  return allDay ? i18n(themePrefix("isbf_v2.calendar_all_day")) : new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
    hour: "2-digit",
    minute: "2-digit"
  }).format(new Date(value));
}
export default class ISBFV2Calendar extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
  static {
    g(this.prototype, "dialog", [service]);
  }
  #dialog = (i(this, "dialog"), void 0);
  static {
    g(this.prototype, "modal", [service]);
  }
  #modal = (i(this, "modal"), void 0);
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "visibleMonth", [tracked]);
  }
  #visibleMonth = (i(this, "visibleMonth"), void 0);
  static {
    g(this.prototype, "selectedDate", [tracked]);
  }
  #selectedDate = (i(this, "selectedDate"), void 0);
  static {
    g(this.prototype, "filter", [tracked], function () {
      return "all";
    });
  }
  #filter = (i(this, "filter"), void 0);
  static {
    g(this.prototype, "personalEntries", [tracked], function () {
      return [];
    });
  }
  #personalEntries = (i(this, "personalEntries"), void 0);
  static {
    g(this.prototype, "communityEvents", [tracked], function () {
      return [];
    });
  }
  #communityEvents = (i(this, "communityEvents"), void 0);
  static {
    g(this.prototype, "pendingUpdates", [tracked], function () {
      return [];
    });
  }
  #pendingUpdates = (i(this, "pendingUpdates"), void 0);
  static {
    g(this.prototype, "updatesError", [tracked], function () {
      return false;
    });
  }
  #updatesError = (i(this, "updatesError"), void 0);
  static {
    g(this.prototype, "focusedEntryId", [tracked], function () {
      return null;
    });
  }
  #focusedEntryId = (i(this, "focusedEntryId"), void 0);
  static {
    g(this.prototype, "isLoading", [tracked], function () {
      return false;
    });
  }
  #isLoading = (i(this, "isLoading"), void 0);
  static {
    g(this.prototype, "loadError", [tracked], function () {
      return false;
    });
  }
  #loadError = (i(this, "loadError"), void 0);
  weekdays = WEEKDAYS.map(day => i18n(themePrefix(`isbf_v2.week_${day}`)));
  #requestNumber = 0;
  #updatesRequestNumber = 0;
  #focusRequestNumber = 0;
  #queryEntryId;
  constructor() {
    super(...arguments);
    const today = new Date();
    this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    this.selectedDate = dateKey(today);
    this.appEvents.on("isbf:calendar-entry-changed", this.reloadEntries);
    this.router.on("routeDidChange", this.focusFromRoute);
    void this.reloadEntries();
    void this.focusFromRoute();
  }
  willDestroy() {
    super.willDestroy(...arguments);
    this.appEvents.off("isbf:calendar-entry-changed", this.reloadEntries);
    this.router.off("routeDidChange", this.focusFromRoute);
  }
  get monthLabel() {
    return new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
      year: "numeric",
      month: "long"
    }).format(this.visibleMonth);
  }
  get selectedLabel() {
    return new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
      month: "long",
      day: "numeric",
      weekday: "long"
    }).format(localDate(this.selectedDate));
  }
  get canCreateCommunity() {
    return Boolean((this.currentUser?.admin || this.currentUser?.academy_moderator_permissions?.publish_activities) && this.currentUser?.can_create_discourse_post_event && Number(settings.calendar_category_id) > 0);
  }
  get communityComposeHref() {
    const slug = settings.calendar_category_path.split("/").filter(Boolean)[1];
    return `/new-topic?category=${encodeURIComponent(slug || "campus-events")}`;
  }
  get monthCells() {
    const first = new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth(), 1);
    const offset = (first.getDay() + 6) % 7;
    const cells = [];
    for (let index = 0; index < 42; index++) {
      const date = new Date(first.getFullYear(), first.getMonth(), index + 1 - offset);
      const key = dateKey(date);
      cells.push({
        day: date.getDate(),
        key,
        inMonth: date.getMonth() === first.getMonth(),
        isSelected: key === this.selectedDate,
        isToday: key === dateKey(new Date()),
        hasPersonal: this.personalEntries.some(entry => this.#occursOn(entry, key)),
        hasCommunity: this.communityEvents.some(event => this.#occursOn(event, key))
      });
    }
    return cells;
  }
  get selectedItems() {
    const entries = this.filter === "community" ? [] : this.personalEntries;
    const events = this.filter === "personal" ? [] : this.communityEvents;
    return [...entries, ...events].filter(item => this.#occursOn(item, this.selectedDate)).sort((a, b) => a.starts_at.localeCompare(b.starts_at)).map(item => ({
      ...item,
      isFocused: item.id === this.focusedEntryId && item.kind === "personal"
    }));
  }
  get updatesLabel() {
    return i18n(themePrefix("isbf_v2.schedule_pending_count"), {
      count: this.pendingUpdates.length
    });
  }
  reloadEntries() {
    return Promise.all([this.loadMonth(), this.loadUpdates()]);
  }
  static {
    n(this.prototype, "reloadEntries", [action]);
  }
  async loadUpdates() {
    const request = ++this.#updatesRequestNumber;
    if (!this.currentUser) {
      return;
    }
    try {
      const {
        entries
      } = await ajax("/isbf/api/entry-updates.json");
      if (request === this.#updatesRequestNumber && !this.isDestroying) {
        this.pendingUpdates = entries;
        this.updatesError = false;
      }
    } catch {
      if (request === this.#updatesRequestNumber && !this.isDestroying) {
        this.updatesError = true;
      }
    }
  }
  static {
    n(this.prototype, "loadUpdates", [action]);
  }
  async focusFromRoute() {
    const id = new URLSearchParams(this.router.currentURL?.split("?")[1]).get("entry_id");
    if (!id || !/^\d+$/.test(id) || Number(id) <= 0 || id === this.#queryEntryId || !this.currentUser) {
      return;
    }
    this.#queryEntryId = id;
    const request = ++this.#focusRequestNumber;
    try {
      const {
        entry
      } = await ajax(`/isbf/api/entries/${id}.json`);
      if (request !== this.#focusRequestNumber || this.isDestroying) {
        return;
      }
      this.#selectEntry(entry);
      await this.loadMonth();
      scheduleOnce("afterRender", this, this.#focusEntry);
      if (entry.needs_update) {
        this.reviewUpdate(entry);
      }
    } catch {
      if (!this.isDestroying) {
        this.loadError = true;
      }
    }
  }
  static {
    n(this.prototype, "focusFromRoute", [action]);
  }
  entryUpdated(entry, accepted = false) {
    if (accepted) {
      this.#selectEntry(entry);
    }
    this.appEvents.trigger("isbf:calendar-entry-changed", entry);
  }
  static {
    n(this.prototype, "entryUpdated", [action]);
  }
  reviewUpdate(entry) {
    this.modal.show(ISBFCalendarUpdateDialog, {
      model: {
        entry,
        onChanged: this.entryUpdated,
        onRemove: this.deleteEntry
      }
    });
  }
  static {
    n(this.prototype, "reviewUpdate", [action]);
  }
  async loadMonth() {
    const request = ++this.#requestNumber;
    const first = new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth(), 1);
    const offset = (first.getDay() + 6) % 7;
    const from = new Date(first.getFullYear(), first.getMonth(), 1 - offset);
    const to = new Date(from.getFullYear(), from.getMonth(), from.getDate() + 42);
    const data = {
      from: from.toISOString(),
      to: to.toISOString()
    };
    const personalData = {
      from: new Date(from.getTime() - 86400000).toISOString(),
      to: new Date(to.getTime() + 86400000).toISOString()
    };
    this.isLoading = true;
    this.loadError = false;
    const [personal, community] = await Promise.allSettled([this.currentUser ? ajax("/isbf/api/entries.json", {
      data: personalData
    }) : Promise.resolve({
      entries: []
    }), Number(settings.calendar_category_id) > 0 ? ajax("/discourse-post-event/events.json", {
      data: {
        after: data.from,
        before: data.to,
        category_id: settings.calendar_category_id,
        limit: 200
      }
    }) : Promise.resolve({
      events: []
    })]);
    if (request !== this.#requestNumber || this.isDestroying) {
      return;
    }
    this.personalEntries = personal.status === "fulfilled" ? personal.value.entries.map(entry => ({
      ...entry,
      kind: "personal"
    })) : [];
    this.communityEvents = community.status === "fulfilled" ? community.value.events.flatMap(event => (event.occurrences || []).map(occurrence => {
      const end = occurrence.ends_at || (event.all_day ? occurrence.starts_at : new Date(new Date(occurrence.starts_at).getTime() + 3600000).toISOString());
      return {
        id: event.id,
        title: event.name || event.post?.topic?.title,
        starts_at: occurrence.starts_at,
        ends_at: event.all_day ? new Date(new Date(`${end.slice(0, 10)}T00:00:00.000Z`).getTime() + 86400000).toISOString() : end,
        all_day: event.all_day,
        href: event.post?.url,
        kind: "community"
      };
    })) : [];
    this.loadError = personal.status === "rejected" || community.status === "rejected";
    this.isLoading = false;
  }
  static {
    n(this.prototype, "loadMonth", [action]);
  }
  previousMonth() {
    this.#changeMonth(-1);
  }
  static {
    n(this.prototype, "previousMonth", [action]);
  }
  nextMonth() {
    this.#changeMonth(1);
  }
  static {
    n(this.prototype, "nextMonth", [action]);
  }
  goToday() {
    const today = new Date();
    this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    this.selectedDate = dateKey(today);
    void this.loadMonth();
  }
  static {
    n(this.prototype, "goToday", [action]);
  }
  selectDate(key) {
    this.selectedDate = key;
    const date = localDate(key);
    if (date.getMonth() !== this.visibleMonth.getMonth() || date.getFullYear() !== this.visibleMonth.getFullYear()) {
      this.visibleMonth = new Date(date.getFullYear(), date.getMonth(), 1);
      void this.loadMonth();
    }
  }
  static {
    n(this.prototype, "selectDate", [action]);
  }
  setFilter(filter) {
    this.filter = filter;
  }
  static {
    n(this.prototype, "setFilter", [action]);
  }
  newEntry() {
    this.modal.show(ISBFCalendarEntryEditor, {
      model: {
        selectedDate: this.selectedDate,
        onSaved: this.loadMonth
      }
    });
  }
  static {
    n(this.prototype, "newEntry", [action]);
  }
  editEntry(entry) {
    if (entry.source_item_id) {
      this.modal.show(ISBFCalendarNoteEditor, {
        model: {
          entry,
          onChanged: this.entryUpdated
        }
      });
      return;
    }
    this.modal.show(ISBFCalendarEntryEditor, {
      model: {
        entry,
        onSaved: this.loadMonth
      }
    });
  }
  static {
    n(this.prototype, "editEntry", [action]);
  }
  async deleteEntry(entry) {
    if (!(await this.dialog.confirm({
      message: i18n(themePrefix("isbf_v2.calendar_delete_confirm"))
    }))) {
      return;
    }
    try {
      await ajax(`/isbf/api/entries/${entry.id}.json`, {
        type: "DELETE"
      });
      this.appEvents.trigger("isbf:calendar-entry-changed", {
        ...entry,
        removed: true
      });
      return true;
    } catch {
      this.loadError = true;
      return false;
    }
  }
  static {
    n(this.prototype, "deleteEntry", [action]);
  }
  #selectEntry(entry) {
    const key = entry.source_item_id ? officialDateKey(entry.starts_at) : entry.all_day ? entry.starts_at.slice(0, 10) : dateKey(new Date(entry.starts_at));
    const date = localDate(key);
    this.visibleMonth = new Date(date.getFullYear(), date.getMonth(), 1);
    this.selectedDate = key;
    this.focusedEntryId = entry.id;
    this.filter = "all";
  }
  #focusEntry() {
    document.querySelector(".isbf-v2-calendar__item.is-focused")?.focus();
  }
  #changeMonth(amount) {
    this.visibleMonth = new Date(this.visibleMonth.getFullYear(), this.visibleMonth.getMonth() + amount, 1);
    this.selectedDate = dateKey(this.visibleMonth);
    void this.loadMonth();
  }
  #occursOn(item, key) {
    if (item.source_item_id) {
      return officialOccursOn(item, key);
    }
    if (item.all_day) {
      return item.starts_at.slice(0, 10) <= key && key < item.ends_at.slice(0, 10);
    }
    const dayStart = new Date(`${key}T00:00:00`).getTime();
    const nextDay = new Date(localDate(key).getFullYear(), localDate(key).getMonth(), localDate(key).getDate() + 1).getTime();
    return new Date(item.starts_at).getTime() < nextDay && new Date(item.ends_at).getTime() > dayStart;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <main class="isbf-v2-feature isbf-v2-calendar">
      <div class="isbf-v2-calendar__heading">
        <div>
          <h1>{{i18n (themePrefix "isbf_v2.calendar")}}</h1>
        </div>
        {{#if this.currentUser}}<button
            class="isbf-v2-calendar__primary"
            type="button"
            {{on "click" this.newEntry}}
          >{{dIcon "plus"}}
            {{i18n
              (themePrefix "isbf_v2.calendar_add_personal")
            }}</button>{{/if}}
      </div>
    
      <div
        aria-label={{i18n (themePrefix "isbf_v2.calendar_filter_label")}}
        class="isbf-v2-calendar__filters"
        role="group"
      >
        <button
          class={{if (eq this.filter "all") "is-active"}}
          type="button"
          {{on "click" (fn this.setFilter "all")}}
        >{{i18n (themePrefix "isbf_v2.calendar_all")}}</button>
        {{#if this.currentUser}}<button
            class={{if (eq this.filter "personal") "is-active"}}
            type="button"
            {{on "click" (fn this.setFilter "personal")}}
          >{{i18n (themePrefix "isbf_v2.calendar_personal")}}</button>{{/if}}
        <button
          class={{if (eq this.filter "community") "is-active"}}
          type="button"
          {{on "click" (fn this.setFilter "community")}}
        >{{i18n (themePrefix "isbf_v2.calendar_community")}}</button>
      </div>
    
      {{#if this.updatesError}}
        <p class="isbf-calendar-updates__error" role="alert">{{i18n
            (themePrefix "isbf_v2.schedule_updates_error")
          }}</p>
        <DButton
          @action={{this.loadUpdates}}
          @label={{themePrefix "isbf_v2.official_retry"}}
        />
      {{/if}}
      {{#if this.pendingUpdates.length}}
        <section aria-label={{this.updatesLabel}} class="isbf-calendar-updates">
          <h2>{{this.updatesLabel}}</h2>
          <p>{{i18n (themePrefix "isbf_v2.schedule_pending_hint")}}</p>
          {{#each this.pendingUpdates key="id" as |entry|}}
            <div class="isbf-calendar-updates__item" data-entry-id={{entry.id}}>
              <span>{{entry.title}}
                ·
                {{i18n
                  (themePrefix
                    (if
                      entry.cancelled
                      "isbf_v2.schedule_cancelled"
                      "isbf_v2.schedule_changed"
                    )
                  )
                }}</span>
              <DButton
                @action={{fn this.reviewUpdate entry}}
                @label={{themePrefix "isbf_v2.schedule_review"}}
              />
            </div>
          {{/each}}
        </section>
      {{/if}}
    
      <div class="isbf-v2-calendar__layout">
        <section aria-label={{this.monthLabel}} class="isbf-v2-calendar__month">
          <div class="isbf-v2-calendar__month-toolbar">
            <h2>{{this.monthLabel}}</h2>
            <div>
              <button type="button" {{on "click" this.goToday}}>{{i18n
                  (themePrefix "isbf_v2.calendar_today")
                }}</button>
              <button
                aria-label={{i18n (themePrefix "isbf_v2.calendar_previous")}}
                type="button"
                {{on "click" this.previousMonth}}
              >{{dIcon "chevron-left"}}</button>
              <button
                aria-label={{i18n (themePrefix "isbf_v2.calendar_next")}}
                type="button"
                {{on "click" this.nextMonth}}
              >{{dIcon "chevron-right"}}</button>
            </div>
          </div>
          <div class="isbf-v2-calendar__weekdays">{{#each
              this.weekdays
              as |day|
            }}<span>{{day}}</span>{{/each}}</div>
          <div class="isbf-v2-calendar__days">
            {{#each this.monthCells as |cell|}}
              <button
                aria-label={{cell.key}}
                aria-pressed={{if cell.isSelected "true" "false"}}
                class="isbf-v2-calendar__day
                  {{if cell.inMonth '' 'is-outside'}}
                  {{if cell.isSelected 'is-selected'}}
                  {{if cell.isToday 'is-today'}}"
                type="button"
                {{on "click" (fn this.selectDate cell.key)}}
              >
                <span>{{cell.day}}</span><span
                  aria-hidden="true"
                  class="isbf-v2-calendar__dots"
                >{{#if cell.hasPersonal}}<i class="is-personal"></i>{{/if}}{{#if
                    cell.hasCommunity
                  }}<i class="is-community"></i>{{/if}}</span>
              </button>
            {{/each}}
          </div>
          <div class="isbf-v2-calendar__legend"><span><i
                class="is-personal"
              ></i>{{i18n
                (themePrefix "isbf_v2.calendar_personal")
              }}</span><span><i class="is-community"></i>{{i18n
                (themePrefix "isbf_v2.calendar_community")
              }}</span></div>
        </section>
    
        <section
          aria-label={{this.selectedLabel}}
          class="isbf-v2-calendar__agenda"
        >
          <div class="isbf-v2-calendar__agenda-heading"><div><small>{{i18n
                  (themePrefix "isbf_v2.calendar_selected")
                }}</small><h2>{{this.selectedLabel}}</h2></div>{{#if
              this.canCreateCommunity
            }}<a href={{this.communityComposeHref}}>{{i18n
                  (themePrefix "isbf_v2.calendar_publish_event")
                }}</a>{{/if}}</div>
          {{#if this.isLoading}}<p class="isbf-v2-calendar__empty">{{i18n
                (themePrefix "isbf_v2.calendar_loading")
              }}</p>{{/if}}
          {{#if this.loadError}}<p
              class="isbf-v2-calendar__error"
              role="alert"
            >{{i18n (themePrefix "isbf_v2.calendar_load_error")}}</p>{{/if}}
          {{#unless this.isLoading}}
            {{#each this.selectedItems as |item|}}
              <article
                class="isbf-v2-calendar__item isbf-v2-calendar__item--{{item.kind}}
                  {{if item.isFocused 'is-focused'}}"
                data-entry-id={{item.id}}
                tabindex={{if item.isFocused "-1"}}
              >
                <div class="isbf-v2-calendar__item-top"><span>{{if
                      (eq item.kind "personal")
                      (i18n (themePrefix "isbf_v2.calendar_personal"))
                      (i18n (themePrefix "isbf_v2.calendar_community"))
                    }}</span><time>{{#if
                      item.source_item_id
                    }}{{officialTimeLabel item}}{{else}}{{displayTime
                        item.starts_at
                        item.all_day
                      }}{{/if}}</time></div>
                {{#if item.href}}<h3><a
                      href={{item.href}}
                    >{{item.title}}</a></h3>{{else}}<h3
                  >{{item.title}}</h3>{{/if}}
                {{#if item.note}}<p>{{item.note}}</p>{{/if}}
                {{#if item.source_item_id}}
                  <div class="isbf-v2-calendar__official">
                    <span>{{i18n
                        (themePrefix "isbf_v2.schedule_imported")
                      }}</span>
                    {{#if item.cancelled}}<strong>{{i18n
                          (themePrefix "isbf_v2.schedule_cancelled")
                        }}</strong>{{/if}}
                    {{#if item.source_url}}<a href={{item.source_url}}>{{i18n
                          (themePrefix "isbf_v2.schedule_source")
                        }}</a>{{else if item.source_unavailable}}<span>{{i18n
                          (themePrefix "isbf_v2.schedule_unavailable")
                        }}</span>{{/if}}
                    {{#if item.needs_update}}<DButton
                        @action={{fn this.reviewUpdate item}}
                        @label={{themePrefix "isbf_v2.schedule_review"}}
                      />{{/if}}
                  </div>
                {{/if}}
                {{#if (eq item.kind "personal")}}<div
                    class="isbf-v2-calendar__item-actions"
                  ><button
                      type="button"
                      {{on "click" (fn this.editEntry item)}}
                    >{{i18n
                        (themePrefix
                          (if
                            item.source_item_id
                            "isbf_v2.schedule_edit_note"
                            "isbf_v2.calendar_edit"
                          )
                        )
                      }}</button><button
                      type="button"
                      {{on "click" (fn this.deleteEntry item)}}
                    >{{i18n
                        (themePrefix "isbf_v2.calendar_delete")
                      }}</button></div>{{/if}}
              </article>
            {{else}}
              <p class="isbf-v2-calendar__empty">{{i18n
                  (themePrefix "isbf_v2.calendar_empty")
                }}</p>
            {{/each}}
          {{/unless}}
        </section>
      </div>
    
    </main>
    */
    {
      "id": null,
      "block": "[[[10,\"main\"],[14,0,\"isbf-v2-feature isbf-v2-calendar\"],[12],[1,\"\\n  \"],[10,0],[14,0,\"isbf-v2-calendar__heading\"],[12],[1,\"\\n    \"],[10,0],[12],[1,\"\\n      \"],[10,\"h1\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n    \"],[41,[30,0,[\"currentUser\"]],[[[11,\"button\"],[24,0,\"isbf-v2-calendar__primary\"],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"newEntry\"]]],null],[12],[1,[28,[32,3],[\"plus\"],null]],[1,\"\\n        \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_add_personal\"],null]],null]],[13]],[]],null],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,0],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_filter_label\"],null]],null]],[14,0,\"isbf-v2-calendar__filters\"],[14,\"role\",\"group\"],[12],[1,\"\\n    \"],[11,\"button\"],[16,0,[52,[28,[32,4],[[30,0,[\"filter\"]],\"all\"],null],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"setFilter\"]],\"all\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_all\"],null]],null]],[13],[1,\"\\n    \"],[41,[30,0,[\"currentUser\"]],[[[11,\"button\"],[16,0,[52,[28,[32,4],[[30,0,[\"filter\"]],\"personal\"],null],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"setFilter\"]],\"personal\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null]],[13]],[]],null],[1,\"\\n    \"],[11,\"button\"],[16,0,[52,[28,[32,4],[[30,0,[\"filter\"]],\"community\"],null],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"setFilter\"]],\"community\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_community\"],null]],null]],[13],[1,\"\\n  \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"updatesError\"]],[[[1,\"    \"],[10,2],[14,0,\"isbf-calendar-updates__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_updates_error\"],null]],null]],[13],[1,\"\\n    \"],[8,[32,6],null,[[\"@action\",\"@label\"],[[30,0,[\"loadUpdates\"]],[28,[32,1],[\"isbf_v2.official_retry\"],null]]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"pendingUpdates\",\"length\"]],[[[1,\"    \"],[10,\"section\"],[15,\"aria-label\",[30,0,[\"updatesLabel\"]]],[14,0,\"isbf-calendar-updates\"],[12],[1,\"\\n      \"],[10,\"h2\"],[12],[1,[30,0,[\"updatesLabel\"]]],[13],[1,\"\\n      \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_pending_hint\"],null]],null]],[13],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"pendingUpdates\"]]],null]],null],\"id\",[[[1,\"        \"],[10,0],[14,0,\"isbf-calendar-updates__item\"],[15,\"data-entry-id\",[30,1,[\"id\"]]],[12],[1,\"\\n          \"],[10,1],[12],[1,[30,1,[\"title\"]]],[1,\"\\n            ·\\n            \"],[1,[28,[32,0],[[28,[32,1],[[52,[30,1,[\"cancelled\"]],\"isbf_v2.schedule_cancelled\",\"isbf_v2.schedule_changed\"]],null]],null]],[13],[1,\"\\n          \"],[8,[32,6],null,[[\"@action\",\"@label\"],[[28,[32,5],[[30,0,[\"reviewUpdate\"]],[30,1]],null],[28,[32,1],[\"isbf_v2.schedule_review\"],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[1]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n  \"],[10,0],[14,0,\"isbf-v2-calendar__layout\"],[12],[1,\"\\n    \"],[10,\"section\"],[15,\"aria-label\",[30,0,[\"monthLabel\"]]],[14,0,\"isbf-v2-calendar__month\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__month-toolbar\"],[12],[1,\"\\n        \"],[10,\"h2\"],[12],[1,[30,0,[\"monthLabel\"]]],[13],[1,\"\\n        \"],[10,0],[12],[1,\"\\n          \"],[11,\"button\"],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"goToday\"]]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_today\"],null]],null]],[13],[1,\"\\n          \"],[11,\"button\"],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_previous\"],null]],null]],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"previousMonth\"]]],null],[12],[1,[28,[32,3],[\"chevron-left\"],null]],[13],[1,\"\\n          \"],[11,\"button\"],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_next\"],null]],null]],[24,4,\"button\"],[4,[32,2],[\"click\",[30,0,[\"nextMonth\"]]],null],[12],[1,[28,[32,3],[\"chevron-right\"],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__weekdays\"],[12],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"weekdays\"]]],null]],null],null,[[[10,1],[12],[1,[30,2]],[13]],[2]],null],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__days\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"monthCells\"]]],null]],null],null,[[[1,\"          \"],[11,\"button\"],[16,\"aria-label\",[30,3,[\"key\"]]],[16,\"aria-pressed\",[52,[30,3,[\"isSelected\"]],\"true\",\"false\"]],[16,0,[29,[\"isbf-v2-calendar__day\\n              \",[52,[30,3,[\"inMonth\"]],\"\",\"is-outside\"],\"\\n              \",[52,[30,3,[\"isSelected\"]],\"is-selected\"],\"\\n              \",[52,[30,3,[\"isToday\"]],\"is-today\"]]]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"selectDate\"]],[30,3,[\"key\"]]],null]],null],[12],[1,\"\\n            \"],[10,1],[12],[1,[30,3,[\"day\"]]],[13],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-v2-calendar__dots\"],[12],[41,[30,3,[\"hasPersonal\"]],[[[10,\"i\"],[14,0,\"is-personal\"],[12],[13]],[]],null],[41,[30,3,[\"hasCommunity\"]],[[[10,\"i\"],[14,0,\"is-community\"],[12],[13]],[]],null],[13],[1,\"\\n          \"],[13],[1,\"\\n\"]],[3]],null],[1,\"      \"],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__legend\"],[12],[10,1],[12],[10,\"i\"],[14,0,\"is-personal\"],[12],[13],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null]],[13],[10,1],[12],[10,\"i\"],[14,0,\"is-community\"],[12],[13],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_community\"],null]],null]],[13],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n    \"],[10,\"section\"],[15,\"aria-label\",[30,0,[\"selectedLabel\"]]],[14,0,\"isbf-v2-calendar__agenda\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"isbf-v2-calendar__agenda-heading\"],[12],[10,0],[12],[10,\"small\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_selected\"],null]],null]],[13],[10,\"h2\"],[12],[1,[30,0,[\"selectedLabel\"]]],[13],[13],[41,[30,0,[\"canCreateCommunity\"]],[[[10,3],[15,6,[30,0,[\"communityComposeHref\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_publish_event\"],null]],null]],[13]],[]],null],[13],[1,\"\\n      \"],[41,[30,0,[\"isLoading\"]],[[[10,2],[14,0,\"isbf-v2-calendar__empty\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_loading\"],null]],null]],[13]],[]],null],[1,\"\\n      \"],[41,[30,0,[\"loadError\"]],[[[10,2],[14,0,\"isbf-v2-calendar__error\"],[14,\"role\",\"alert\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_load_error\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[51,[30,0,[\"isLoading\"]]],[[[42,[28,[31,2],[[28,[31,2],[[30,0,[\"selectedItems\"]]],null]],null],null,[[[1,\"          \"],[10,\"article\"],[15,0,[29,[\"isbf-v2-calendar__item isbf-v2-calendar__item--\",[30,4,[\"kind\"]],\"\\n              \",[52,[30,4,[\"isFocused\"]],\"is-focused\"]]]],[15,\"data-entry-id\",[30,4,[\"id\"]]],[15,\"tabindex\",[52,[30,4,[\"isFocused\"]],\"-1\"]],[12],[1,\"\\n            \"],[10,0],[14,0,\"isbf-v2-calendar__item-top\"],[12],[10,1],[12],[1,[52,[28,[32,4],[[30,4,[\"kind\"]],\"personal\"],null],[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_personal\"],null]],null],[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_community\"],null]],null]]],[13],[10,\"time\"],[12],[41,[30,4,[\"source_item_id\"]],[[[1,[28,[32,7],[[30,4]],null]]],[]],[[[1,[28,[32,8],[[30,4,[\"starts_at\"]],[30,4,[\"all_day\"]]],null]]],[]]],[13],[13],[1,\"\\n            \"],[41,[30,4,[\"href\"]],[[[10,\"h3\"],[12],[10,3],[15,6,[30,4,[\"href\"]]],[12],[1,[30,4,[\"title\"]]],[13],[13]],[]],[[[10,\"h3\"],[12],[1,[30,4,[\"title\"]]],[13]],[]]],[1,\"\\n            \"],[41,[30,4,[\"note\"]],[[[10,2],[12],[1,[30,4,[\"note\"]]],[13]],[]],null],[1,\"\\n\"],[41,[30,4,[\"source_item_id\"]],[[[1,\"              \"],[10,0],[14,0,\"isbf-v2-calendar__official\"],[12],[1,\"\\n                \"],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_imported\"],null]],null]],[13],[1,\"\\n                \"],[41,[30,4,[\"cancelled\"]],[[[10,\"strong\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_cancelled\"],null]],null]],[13]],[]],null],[1,\"\\n                \"],[41,[30,4,[\"source_url\"]],[[[10,3],[15,6,[30,4,[\"source_url\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_source\"],null]],null]],[13]],[]],[[[41,[30,4,[\"source_unavailable\"]],[[[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.schedule_unavailable\"],null]],null]],[13]],[]],null]],[]]],[1,\"\\n                \"],[41,[30,4,[\"needs_update\"]],[[[8,[32,6],null,[[\"@action\",\"@label\"],[[28,[32,5],[[30,0,[\"reviewUpdate\"]],[30,4]],null],[28,[32,1],[\"isbf_v2.schedule_review\"],null]]],null]],[]],null],[1,\"\\n              \"],[13],[1,\"\\n\"]],[]],null],[1,\"            \"],[41,[28,[32,4],[[30,4,[\"kind\"]],\"personal\"],null],[[[10,0],[14,0,\"isbf-v2-calendar__item-actions\"],[12],[11,\"button\"],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"editEntry\"]],[30,4]],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[[52,[30,4,[\"source_item_id\"]],\"isbf_v2.schedule_edit_note\",\"isbf_v2.calendar_edit\"]],null]],null]],[13],[11,\"button\"],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,5],[[30,0,[\"deleteEntry\"]],[30,4]],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_delete\"],null]],null]],[13],[13]],[]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[4]],[[[1,\"          \"],[10,2],[14,0,\"isbf-v2-calendar__empty\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar_empty\"],null]],null]],[13],[1,\"\\n\"]],[]]]],[]],null],[1,\"    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\\n\"],[13]],[\"entry\",\"day\",\"cell\",\"item\"],[\"if\",\"each\",\"-track-array\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        __keyword__on,
        dIcon,
        __keyword__eq,
        __keyword__fn,
        DButton,
        officialTimeLabel,
        displayTime
      }),
      "isStrictMode": true
    }), this);
  }
}