import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import I18n, { i18n } from "discourse-i18n";
import { calendarEntryKind, calendarEntryTime } from "../lib/calendar-entry";
import { calendarMonthAnchor, calendarWindow } from "../lib/calendar-window";
import { officialDateKey, officialOccursOn } from "../lib/official-calendar";
import ISBFCalendarEntryEditor from "./isbf-calendar-entry-editor";
import ISBFCalendarNoteEditor from "./isbf-calendar-note-editor";
import ISBFCalendarSubscribe from "./isbf-calendar-subscribe";
import ISBFCalendarUpdateDialog from "./isbf-calendar-update-dialog";

const WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];

function dateKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function localDate(key) {
  return new Date(`${key}T12:00:00`);
}

export default class ISBFV2Calendar extends Component {
  @service appEvents;
  @service currentUser;
  @service dialog;
  @service modal;
  @service router;
  @service site;

  @tracked visibleMonth;
  @tracked selectedDate;
  @tracked filter = "all";
  @tracked personalEntries = [];
  @tracked officialEntries = [];
  @tracked pendingUpdates = [];
  @tracked updatesError = false;
  @tracked focusedEntryId = null;
  @tracked isLoading = false;
  @tracked loadError = false;
  @tracked isCompact = false;
  @tracked mobileAnchorDay;
  @tracked mobileFocusDate = null;
  @tracked todayKey;

  weekdays = WEEKDAYS.map((day) => i18n(themePrefix(`isbf_v2.week_${day}`)));
  #actor;
  #actorId;
  #requestNumber = 0;
  #updatesRequestNumber = 0;
  #focusRequestNumber = 0;
  #queryEntryId;
  #disposed = false;
  #followingToday = true;
  #mediaQuery;
  #midnightTimer;

  constructor() {
    super(...arguments);
    const today = new Date();
    this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    this.selectedDate = dateKey(today);
    this.todayKey = this.selectedDate;
    this.mobileAnchorDay = today.getDate();
    this.#mediaQuery = window.matchMedia("(max-width: 600px)");
    this.isCompact = this.#mediaQuery.matches;
    this.#mediaQuery.addEventListener("change", this.onViewportChange);
    window.addEventListener("focus", this.refreshToday);
    document.addEventListener("visibilitychange", this.refreshToday);
    this.#scheduleDayRefresh();
    this.appEvents.on("isbf:calendar-entry-changed", this.reloadEntries);
    this.router.on("routeDidChange", this.focusFromRoute);
    void this.reloadEntries();
    void this.focusFromRoute();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#disposed = true;
    this.#requestNumber++;
    this.#updatesRequestNumber++;
    this.#focusRequestNumber++;
    clearTimeout(this.#midnightTimer);
    this.#mediaQuery.removeEventListener("change", this.onViewportChange);
    window.removeEventListener("focus", this.refreshToday);
    document.removeEventListener("visibilitychange", this.refreshToday);
    this.appEvents.off("isbf:calendar-entry-changed", this.reloadEntries);
    this.router.off("routeDidChange", this.focusFromRoute);
  }

  get monthLabel() {
    return new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
      year: "numeric",
      month: "long",
    }).format(this.visibleMonth);
  }

  get selectedLabel() {
    return new Intl.DateTimeFormat(I18n.currentLocale().replace("_", "-"), {
      month: "long",
      day: "numeric",
      weekday: "long",
    }).format(localDate(this.selectedDate));
  }

  get canCreateOfficial() {
    return Boolean(
      this.currentUser?.academy_official_member &&
      this.officialCategory?.canCreateTopic
    );
  }

  get officialCategory() {
    const id =
      this.site?.isbf_calendar?.official_category_id ??
      Number(settings.official_path?.split("/")[3]);
    return this.site?.categories?.find(
      (category) => Number(category.id) === Number(id)
    );
  }

  get officialComposeHref() {
    return `/new-topic?category=${encodeURIComponent(this.officialCategory?.id || "")}`;
  }

  get allEntries() {
    return this.currentUser === this.#actor &&
      this.currentUser?.id === this.#actorId
      ? [...this.personalEntries, ...this.officialEntries]
      : [];
  }

  get viewRange() {
    return calendarWindow(
      this.visibleMonth,
      this.isCompact,
      this.mobileFocusDate
        ? localDate(this.mobileFocusDate).getDate()
        : this.mobileAnchorDay
    );
  }

  get monthCells() {
    const { from, dayCount } = this.viewRange;
    const cells = [];

    for (let index = 0; index < dayCount; index++) {
      const date = new Date(
        from.getFullYear(),
        from.getMonth(),
        from.getDate() + index
      );
      const key = dateKey(date);
      cells.push({
        day: date.getDate(),
        key,
        inMonth:
          date.getFullYear() === this.visibleMonth.getFullYear() &&
          date.getMonth() === this.visibleMonth.getMonth(),
        isSelected: key === this.selectedDate,
        isToday: key === this.todayKey,
        hasPersonal: this.allEntries.some(
          (entry) => entry.kind === "personal" && this.#occursOn(entry, key)
        ),
        hasOfficial: this.allEntries.some(
          (entry) => entry.kind === "official" && this.#occursOn(entry, key)
        ),
      });
    }

    return cells;
  }

  get selectedItems() {
    return this.allEntries
      .filter(
        (item) =>
          (this.filter === "all" || this.filter === item.kind) &&
          this.#occursOn(item, this.selectedDate)
      )
      .sort((a, b) => a.starts_at.localeCompare(b.starts_at))
      .map((item) => ({ ...item, isFocused: item.id === this.focusedEntryId }));
  }

  get currentPendingUpdates() {
    return this.currentUser === this.#actor &&
      this.currentUser?.id === this.#actorId
      ? this.pendingUpdates
      : [];
  }

  get updatesLabel() {
    return i18n(themePrefix("isbf_v2.schedule_pending_count"), {
      count: this.currentPendingUpdates.length,
    });
  }

  @action
  reloadEntries() {
    return Promise.all([this.loadMonth(), this.loadUpdates()]);
  }

  @action
  async loadUpdates() {
    const request = ++this.#updatesRequestNumber;
    const actor = this.currentUser;
    const actorId = actor?.id;
    if (!actor) {
      this.pendingUpdates = [];
      this.updatesError = false;
      return;
    }
    const current = () =>
      request === this.#updatesRequestNumber &&
      !this.isDestroying &&
      actor === this.currentUser &&
      actorId === this.currentUser?.id;
    try {
      const { entries } = await ajax("/isbf/api/entry-updates.json");
      if (current()) {
        this.pendingUpdates = entries;
        this.updatesError = false;
      }
    } catch {
      if (current()) {
        this.updatesError = true;
      }
    }
  }

  @action
  async focusFromRoute() {
    const id = new URLSearchParams(this.router.currentURL?.split("?")[1]).get(
      "entry_id"
    );
    if (
      !id ||
      !/^\d+$/.test(id) ||
      Number(id) <= 0 ||
      id === this.#queryEntryId ||
      !this.currentUser
    ) {
      return;
    }
    this.#queryEntryId = id;
    const request = ++this.#focusRequestNumber;
    const actor = this.currentUser;
    const actorId = actor?.id;
    try {
      const { entry } = await ajax(`/isbf/api/entries/${id}.json`);
      if (
        request !== this.#focusRequestNumber ||
        this.isDestroying ||
        actor !== this.currentUser ||
        actorId !== this.currentUser?.id
      ) {
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

  @action
  entryUpdated(entry, accepted = false) {
    if (accepted) {
      this.#selectEntry(entry);
    }
    this.appEvents.trigger("isbf:calendar-entry-changed", entry);
  }

  @action
  reviewUpdate(entry) {
    this.modal.show(ISBFCalendarUpdateDialog, {
      model: {
        entry,
        onChanged: this.entryUpdated,
        onRemove: this.deleteEntry,
      },
    });
  }

  @action
  async loadMonth() {
    const request = ++this.#requestNumber;
    const actor = this.currentUser;
    const actorId = actor?.id;
    if (actor !== this.#actor || actorId !== this.#actorId) {
      this.personalEntries = [];
      this.officialEntries = [];
      this.pendingUpdates = [];
      this.updatesError = false;
    }
    this.#actor = actor;
    this.#actorId = actorId;
    const { from, to } = this.viewRange;
    const data = {
      from: new Date(from.getTime() - 86400000).toISOString(),
      to: new Date(to.getTime() + 86400000).toISOString(),
    };
    const current = () =>
      request === this.#requestNumber &&
      !this.isDestroying &&
      actor === this.currentUser &&
      actorId === this.currentUser?.id;
    this.isLoading = true;
    this.loadError = false;
    try {
      const { entries } = actor
        ? await ajax("/isbf/api/entries.json", { data })
        : { entries: [] };
      if (current()) {
        const classified = entries.map((entry) => ({
          ...entry,
          kind: calendarEntryKind(entry),
        }));
        this.personalEntries = classified.filter(
          (entry) => entry.kind === "personal"
        );
        this.officialEntries = classified.filter(
          (entry) => entry.kind === "official"
        );
      }
    } catch {
      if (current()) {
        this.loadError = true;
      }
    } finally {
      if (current()) {
        this.isLoading = false;
      }
    }
  }

  @action
  previousMonth() {
    this.#changeMonth(-1);
  }

  @action
  nextMonth() {
    this.#changeMonth(1);
  }

  @action
  goToday() {
    const today = new Date();
    this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    this.selectedDate = dateKey(today);
    this.todayKey = this.selectedDate;
    this.mobileAnchorDay = today.getDate();
    this.mobileFocusDate = null;
    this.#followingToday = true;
    this.#scheduleDayRefresh();
    void this.loadMonth();
  }

  @action
  onViewportChange(event) {
    if (
      this.#disposed ||
      this.isDestroying ||
      this.isCompact === event.matches
    ) {
      return;
    }
    const previous = this.viewRange;
    this.isCompact = event.matches;
    const selected = localDate(this.selectedDate);
    const range = this.viewRange;
    if (selected < range.from || selected >= range.to) {
      if (this.isCompact) {
        this.mobileFocusDate = this.selectedDate;
        this.visibleMonth = new Date(
          selected.getFullYear(),
          selected.getMonth(),
          1
        );
      } else {
        this.visibleMonth = new Date(
          selected.getFullYear(),
          selected.getMonth(),
          1
        );
      }
    }
    if (
      previous.from.getTime() !== this.viewRange.from.getTime() ||
      previous.to.getTime() !== this.viewRange.to.getTime()
    ) {
      void this.loadMonth();
    }
  }

  @action
  refreshToday() {
    if (
      this.#disposed ||
      this.isDestroying ||
      document.visibilityState === "hidden"
    ) {
      return;
    }
    const today = new Date();
    const key = dateKey(today);
    if (key !== this.todayKey) {
      const selectedToday = this.selectedDate === this.todayKey;
      this.todayKey = key;
      if (this.#followingToday) {
        this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        this.mobileAnchorDay = today.getDate();
        this.mobileFocusDate = null;
        if (selectedToday) {
          this.selectedDate = key;
        }
        void this.loadMonth();
      }
    }
    this.#scheduleDayRefresh();
  }

  @action
  selectDate(key) {
    this.selectedDate = key;
    if (key !== this.todayKey) {
      this.#followingToday = false;
    }
    if (this.isCompact) {
      return;
    }
    const date = localDate(key);
    if (
      date.getMonth() !== this.visibleMonth.getMonth() ||
      date.getFullYear() !== this.visibleMonth.getFullYear()
    ) {
      this.visibleMonth = new Date(date.getFullYear(), date.getMonth(), 1);
      void this.loadMonth();
    }
  }

  @action
  setFilter(filter) {
    this.filter = filter;
  }

  @action
  newEntry() {
    this.modal.show(ISBFCalendarEntryEditor, {
      model: { selectedDate: this.selectedDate, onSaved: this.loadMonth },
    });
  }

  @action
  editEntry(entry) {
    if (entry.source_item_id) {
      this.modal.show(ISBFCalendarNoteEditor, {
        model: { entry, onChanged: this.entryUpdated },
      });
      return;
    }
    this.modal.show(ISBFCalendarEntryEditor, {
      model: { entry, onSaved: this.loadMonth },
    });
  }

  @action
  async deleteEntry(entry) {
    if (
      !(await this.dialog.confirm({
        message: i18n(themePrefix("isbf_v2.calendar_delete_confirm")),
      }))
    ) {
      return;
    }

    try {
      await ajax(`/isbf/api/entries/${entry.id}.json`, { type: "DELETE" });
      this.appEvents.trigger("isbf:calendar-entry-changed", {
        ...entry,
        removed: true,
      });
      return true;
    } catch {
      this.loadError = true;
      return false;
    }
  }

  #selectEntry(entry) {
    const key = entry.source_item_id
      ? officialDateKey(entry.starts_at)
      : entry.all_day
        ? entry.starts_at.slice(0, 10)
        : dateKey(new Date(entry.starts_at));
    const date = localDate(key);
    this.visibleMonth = new Date(date.getFullYear(), date.getMonth(), 1);
    this.selectedDate = key;
    this.mobileFocusDate = key;
    this.#followingToday = false;
    this.focusedEntryId = entry.id;
    this.filter = "all";
  }

  #focusEntry() {
    document.querySelector(".isbf-v2-calendar__item.is-focused")?.focus();
  }

  #changeMonth(amount) {
    this.visibleMonth = new Date(
      this.visibleMonth.getFullYear(),
      this.visibleMonth.getMonth() + amount,
      1
    );
    this.mobileFocusDate = null;
    this.#followingToday = false;
    this.mobileAnchorDay = localDate(this.todayKey).getDate();
    this.selectedDate = dateKey(
      this.isCompact
        ? calendarMonthAnchor(this.visibleMonth, this.mobileAnchorDay)
        : this.visibleMonth
    );
    void this.loadMonth();
  }

  #scheduleDayRefresh() {
    clearTimeout(this.#midnightTimer);
    const now = new Date();
    const midnight = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() + 1
    );
    this.#midnightTimer = setTimeout(
      this.refreshToday,
      midnight.getTime() - now.getTime() + 50
    );
  }

  #occursOn(item, key) {
    if (item.source_item_id) {
      return officialOccursOn(item, key);
    }
    if (item.all_day) {
      return (
        item.starts_at.slice(0, 10) <= key && key < item.ends_at.slice(0, 10)
      );
    }

    const dayStart = new Date(`${key}T00:00:00`).getTime();
    const nextDay = new Date(
      localDate(key).getFullYear(),
      localDate(key).getMonth(),
      localDate(key).getDate() + 1
    ).getTime();
    return (
      new Date(item.starts_at).getTime() < nextDay &&
      new Date(item.ends_at).getTime() > dayStart
    );
  }

  <template>
    <main class="isbf-v2-feature isbf-v2-calendar">
      <div class="isbf-v2-calendar__heading">
        <div>
          <h1>{{i18n (themePrefix "isbf_v2.calendar")}}</h1>
        </div>
        <div class="isbf-v2-calendar__heading-actions">
          {{#if this.currentUser}}<button
              class="isbf-v2-calendar__primary"
              type="button"
              {{on "click" this.newEntry}}
            >{{dIcon "plus"}}
              {{i18n
                (themePrefix "isbf_v2.calendar_add_personal")
              }}</button>{{/if}}
        </div>
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
          class={{if (eq this.filter "official") "is-active"}}
          type="button"
          {{on "click" (fn this.setFilter "official")}}
        >{{i18n (themePrefix "isbf_v2.calendar_official")}}</button>
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
      {{#if this.currentPendingUpdates.length}}
        <section aria-label={{this.updatesLabel}} class="isbf-calendar-updates">
          <h2>{{this.updatesLabel}}</h2>
          <p>{{i18n (themePrefix "isbf_v2.schedule_pending_hint")}}</p>
          {{#each this.currentPendingUpdates key="id" as |entry|}}
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
                    cell.hasOfficial
                  }}<i class="is-official"></i>{{/if}}</span>
              </button>
            {{/each}}
          </div>
          <div class="isbf-v2-calendar__month-footer">
            <div class="isbf-v2-calendar__legend"><span><i
                  class="is-personal"
                ></i>{{i18n
                  (themePrefix "isbf_v2.calendar_personal")
                }}</span><span><i class="is-official"></i>{{i18n
                  (themePrefix "isbf_v2.calendar_official")
                }}</span></div>
            <ISBFCalendarSubscribe />
          </div>
        </section>

        <section
          aria-label={{this.selectedLabel}}
          class="isbf-v2-calendar__agenda"
        >
          <div class="isbf-v2-calendar__agenda-heading"><div><small>{{i18n
                  (themePrefix "isbf_v2.calendar_selected")
                }}</small><h2>{{this.selectedLabel}}</h2></div>{{#if
              this.canCreateOfficial
            }}<a href={{this.officialComposeHref}}>{{i18n
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
                      (i18n (themePrefix "isbf_v2.calendar_official"))
                    }}</span><time>{{calendarEntryTime item}}</time></div>
                {{#if item.href}}<h3><a
                      href={{item.href}}
                    >{{item.title}}</a></h3>{{else}}<h3
                  >{{item.title}}</h3>{{/if}}
                {{#if item.location}}<p
                    class="isbf-v2-calendar__item-location"
                  >{{item.location}}</p>{{/if}}
                {{#if item.note}}<p>{{item.note}}</p>{{/if}}
                {{#if item.cancelled}}<strong>{{i18n
                      (themePrefix "isbf_v2.schedule_cancelled")
                    }}</strong>{{/if}}
                {{#if item.source_unavailable}}<small>{{i18n
                      (themePrefix "isbf_v2.schedule_unavailable")
                    }}</small>{{/if}}
                {{#if item.needs_update}}<DButton
                    @action={{fn this.reviewUpdate item}}
                    @label={{themePrefix "isbf_v2.schedule_review"}}
                  />{{/if}}
                <div class="isbf-v2-calendar__item-actions">
                  {{#if item.source_url}}<a href={{item.source_url}}>{{i18n
                        (themePrefix "isbf_v2.schedule_source")
                      }}</a>{{/if}}
                  <button
                    type="button"
                    {{on "click" (fn this.editEntry item)}}
                  >{{i18n
                      (themePrefix
                        (if
                          item.source_item_id
                          "isbf_v2.calendar_note_action"
                          "isbf_v2.calendar_edit"
                        )
                      )
                    }}</button>
                  <button
                    type="button"
                    {{on "click" (fn this.deleteEntry item)}}
                  >{{i18n (themePrefix "isbf_v2.calendar_delete")}}</button>
                </div>
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
  </template>
}
