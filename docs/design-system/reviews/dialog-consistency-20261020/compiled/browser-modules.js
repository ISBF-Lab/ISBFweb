define("dialog-review/decorators", ["exports", "./runtime--fcdnjmJ.js"], function (_exports, _runtimeFcdnjmJ) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  Object.defineProperty(_exports, "c", {
    enumerable: true,
    get: function () {
      return _runtimeFcdnjmJ.d;
    }
  });
  Object.defineProperty(_exports, "f", {
    enumerable: true,
    get: function () {
      return _runtimeFcdnjmJ.a;
    }
  });
  Object.defineProperty(_exports, "g", {
    enumerable: true,
    get: function () {
      return _runtimeFcdnjmJ.b;
    }
  });
  Object.defineProperty(_exports, "i", {
    enumerable: true,
    get: function () {
      return _runtimeFcdnjmJ.i;
    }
  });
  Object.defineProperty(_exports, "m", {
    enumerable: true,
    get: function () {
      return _runtimeFcdnjmJ.c;
    }
  });
  Object.defineProperty(_exports, "n", {
    enumerable: true,
    get: function () {
      return _runtimeFcdnjmJ.e;
    }
  });
  Object.defineProperty(_exports, "p", {
    enumerable: true,
    get: function () {
      return _runtimeFcdnjmJ.f;
    }
  });
});
define("dialog-review/runtime--fcdnjmJ.js", ["exports"], function (_exports) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.a = decorateFieldV1;
  _exports.b = decorateFieldV2;
  _exports.c = decorateMethodV1;
  _exports.d = decorateClass;
  _exports.e = decorateMethodV2;
  _exports.f = decoratePOJO;
  _exports.i = initializeDeferredDecorator;
  _exports.r = void 0;
  const deferred = /* @__PURE__ */new WeakMap();
  function deferDecorator(proto, prop, desc) {
    let map = deferred.get(proto);
    if (!map) {
      map = /* @__PURE__ */new Map();
      deferred.set(proto, map);
    }
    map.set(prop, desc);
  }
  function findDeferredDecorator(target, prop) {
    var _a;
    let cursor = target.prototype;
    while (cursor) {
      let desc = (_a = deferred.get(cursor)) == null ? void 0 : _a.get(prop);
      if (desc) {
        return desc;
      }
      cursor = Object.getPrototypeOf(cursor);
    }
  }
  function decorateFieldV1(target, prop, decorators, initializer) {
    return decorateFieldV2(target.prototype, prop, decorators, initializer);
  }
  function decorateFieldV2(prototype, prop, decorators, initializer) {
    let desc = {
      configurable: true,
      enumerable: true,
      writable: true,
      initializer: null
    };
    if (initializer) {
      desc.initializer = initializer;
    }
    for (let decorator of decorators) {
      desc = decorator(prototype, prop, desc) || desc;
    }
    if (desc.initializer === void 0) {
      Object.defineProperty(prototype, prop, desc);
    } else {
      deferDecorator(prototype, prop, desc);
    }
  }
  function decorateMethodV1({
    prototype
  }, prop, decorators) {
    return decorateMethodV2(prototype, prop, decorators);
  }
  function decorateMethodV2(prototype, prop, decorators) {
    const origDesc = Object.getOwnPropertyDescriptor(prototype, prop);
    let desc = {
      ...origDesc
    };
    for (let decorator of decorators) {
      desc = decorator(prototype, prop, desc) || desc;
    }
    if (desc.initializer !== void 0) {
      desc.value = desc.initializer ? desc.initializer.call(prototype) : void 0;
      desc.initializer = void 0;
    }
    Object.defineProperty(prototype, prop, desc);
  }
  function initializeDeferredDecorator(target, prop) {
    let desc = findDeferredDecorator(target.constructor, prop);
    if (desc) {
      Object.defineProperty(target, prop, {
        enumerable: desc.enumerable,
        configurable: desc.configurable,
        writable: desc.writable,
        value: desc.initializer ? desc.initializer.call(target) : void 0
      });
    }
  }
  function decorateClass(target, decorators) {
    return decorators.reduce((accum, decorator) => decorator(accum) || accum, target);
  }
  function decoratePOJO(pojo, decorated) {
    for (let [type, prop, decorators] of decorated) {
      if (type === "field") {
        decoratePojoField(pojo, prop, decorators);
      } else {
        decorateMethodV2(pojo, prop, decorators);
      }
    }
    return pojo;
  }
  function decoratePojoField(pojo, prop, decorators) {
    let desc = {
      configurable: true,
      enumerable: true,
      writable: true,
      initializer: () => {
        var _a;
        return (_a = Object.getOwnPropertyDescriptor(pojo, prop)) == null ? void 0 : _a.value;
      }
    };
    for (let decorator of decorators) {
      desc = decorator(pojo, prop, desc) || desc;
    }
    if (desc.initializer) {
      desc.value = desc.initializer.call(pojo);
      delete desc.initializer;
    }
    Object.defineProperty(pojo, prop, desc);
  }
  const runtime = _exports.r = /* @__PURE__ */Object.freeze(/* @__PURE__ */Object.defineProperty({
    __proto__: null,
    c: decorateClass,
    f: decorateFieldV1,
    g: decorateFieldV2,
    i: initializeDeferredDecorator,
    m: decorateMethodV1,
    n: decorateMethodV2,
    p: decoratePOJO
  }, Symbol.toStringTag, {
    value: "Module"
  }));
});

define("dialog-review/theme", [], function () {
  return { themePrefix: (key) => "theme_translations.4." + key,
    get settings() { return window.moduleBroker.lookup("discourse/lib/theme-settings-store").getObjectForTheme(4); } };
});
for (const [name, exports] of Object.entries(window.isbfUnreadCachedTheme)) {
  if (!["dialog-review/discourse/components/isbf-frontend-scope","dialog-review/discourse/components/isbf-v2-calendar","dialog-review/discourse/components/isbf-calendar-entry-editor","dialog-review/discourse/components/isbf-learning-course-dialog","dialog-review/discourse/components/isbf-resource-directory-dialog","dialog-review/discourse/components/isbf-learning-grade-picker","dialog-review/discourse/components/isbf-resource-parent-picker","dialog-review/fixtures"].includes("dialog-review/" + name)) {
    define("dialog-review/" + name, [], function () { return exports; });
  }
}

define("dialog-review/discourse/components/isbf-frontend-scope", ["exports", "@glimmer/component", "@ember/service", "discourse/helpers/body-class", "../lib/frontend-consistency-scope", "@ember/component", "@ember/template-factory", "dialog-review/decorators"], function (_exports, _component, _service, _bodyClass, _frontendConsistencyScope, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFFrontendScope extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "_router", [(0, _service.service)("router")]);
    }
    #_router = ((0, _decorators.i)(this, "_router"), void 0);
    get bodyClasses() {
      const scope = (0, _frontendConsistencyScope.frontendConsistencyScope)(this._router.currentRouteName);
      if (!scope) {
        return null;
      }
      const classes = ["isbf-frontend", `is-frontend-${scope.id}`];
      if (scope.layout === "feature") {
        classes.push("has-frontend-feature");
      }
      classes.push(scope.userContent ? "has-frontend-user-content" : "has-frontend-page");
      return classes.join(" ");
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        {{bodyClass this.bodyClasses}}
      */
      {
        "id": null,
        "block": "[[[1,[28,[32,0],[[30,0,[\"bodyClasses\"]]],null]]],[],[]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          bodyClass: _bodyClass.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFFrontendScope;
});
define("dialog-review/discourse/components/isbf-v2-calendar", ["exports", "@glimmer/component", "@glimmer/tracking", "@ember/object", "@ember/runloop", "@ember/service", "dialog-review/theme", "discourse/lib/ajax", "discourse/ui-kit/d-button", "discourse/ui-kit/helpers/d-icon", "discourse-i18n", "../lib/official-calendar", "./isbf-calendar-entry-editor", "./isbf-calendar-note-editor", "./isbf-calendar-update-dialog", "@ember/modifier", "@ember/helper", "@ember/component", "@ember/template-factory", "dialog-review/decorators"], function (_exports, _component, _tracking, _object, _runloop, _service, _theme, _ajax, _dButton, _dIcon, _discourseI18n, _officialCalendar, _isbfCalendarEntryEditor, _isbfCalendarNoteEditor, _isbfCalendarUpdateDialog, _modifier, _helper, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  const WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
  function dateKey(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
  }
  function localDate(key) {
    return new Date(`${key}T12:00:00`);
  }
  function displayTime(value, allDay) {
    return allDay ? (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.calendar_all_day")) : new Intl.DateTimeFormat(_discourseI18n.default.currentLocale().replace("_", "-"), {
      hour: "2-digit",
      minute: "2-digit"
    }).format(new Date(value));
  }
  class ISBFV2Calendar extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "appEvents", [_service.service]);
    }
    #appEvents = ((0, _decorators.i)(this, "appEvents"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "currentUser", [_service.service]);
    }
    #currentUser = ((0, _decorators.i)(this, "currentUser"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "dialog", [_service.service]);
    }
    #dialog = ((0, _decorators.i)(this, "dialog"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "modal", [_service.service]);
    }
    #modal = ((0, _decorators.i)(this, "modal"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "router", [_service.service]);
    }
    #router = ((0, _decorators.i)(this, "router"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "visibleMonth", [_tracking.tracked]);
    }
    #visibleMonth = ((0, _decorators.i)(this, "visibleMonth"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "selectedDate", [_tracking.tracked]);
    }
    #selectedDate = ((0, _decorators.i)(this, "selectedDate"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "filter", [_tracking.tracked], function () {
        return "all";
      });
    }
    #filter = ((0, _decorators.i)(this, "filter"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "personalEntries", [_tracking.tracked], function () {
        return [];
      });
    }
    #personalEntries = ((0, _decorators.i)(this, "personalEntries"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "communityEvents", [_tracking.tracked], function () {
        return [];
      });
    }
    #communityEvents = ((0, _decorators.i)(this, "communityEvents"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "pendingUpdates", [_tracking.tracked], function () {
        return [];
      });
    }
    #pendingUpdates = ((0, _decorators.i)(this, "pendingUpdates"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "updatesError", [_tracking.tracked], function () {
        return false;
      });
    }
    #updatesError = ((0, _decorators.i)(this, "updatesError"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "focusedEntryId", [_tracking.tracked], function () {
        return null;
      });
    }
    #focusedEntryId = ((0, _decorators.i)(this, "focusedEntryId"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "isLoading", [_tracking.tracked], function () {
        return false;
      });
    }
    #isLoading = ((0, _decorators.i)(this, "isLoading"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "loadError", [_tracking.tracked], function () {
        return false;
      });
    }
    #loadError = ((0, _decorators.i)(this, "loadError"), void 0);
    weekdays = WEEKDAYS.map(day => (0, _discourseI18n.i18n)((0, _theme.themePrefix)(`isbf_v2.week_${day}`)));
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
      return new Intl.DateTimeFormat(_discourseI18n.default.currentLocale().replace("_", "-"), {
        year: "numeric",
        month: "long"
      }).format(this.visibleMonth);
    }
    get selectedLabel() {
      return new Intl.DateTimeFormat(_discourseI18n.default.currentLocale().replace("_", "-"), {
        month: "long",
        day: "numeric",
        weekday: "long"
      }).format(localDate(this.selectedDate));
    }
    get canCreateCommunity() {
      return Boolean((this.currentUser?.admin || this.currentUser?.academy_moderator_permissions?.publish_activities) && this.currentUser?.can_create_discourse_post_event && Number(_theme.settings.calendar_category_id) > 0);
    }
    get communityComposeHref() {
      const slug = _theme.settings.calendar_category_path.split("/").filter(Boolean)[1];
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
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.schedule_pending_count"), {
        count: this.pendingUpdates.length
      });
    }
    reloadEntries() {
      return Promise.all([this.loadMonth(), this.loadUpdates()]);
    }
    static {
      (0, _decorators.n)(this.prototype, "reloadEntries", [_object.action]);
    }
    async loadUpdates() {
      const request = ++this.#updatesRequestNumber;
      if (!this.currentUser) {
        return;
      }
      try {
        const {
          entries
        } = await (0, _ajax.ajax)("/isbf/api/entry-updates.json");
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
      (0, _decorators.n)(this.prototype, "loadUpdates", [_object.action]);
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
        } = await (0, _ajax.ajax)(`/isbf/api/entries/${id}.json`);
        if (request !== this.#focusRequestNumber || this.isDestroying) {
          return;
        }
        this.#selectEntry(entry);
        await this.loadMonth();
        (0, _runloop.scheduleOnce)("afterRender", this, this.#focusEntry);
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
      (0, _decorators.n)(this.prototype, "focusFromRoute", [_object.action]);
    }
    entryUpdated(entry, accepted = false) {
      if (accepted) {
        this.#selectEntry(entry);
      }
      this.appEvents.trigger("isbf:calendar-entry-changed", entry);
    }
    static {
      (0, _decorators.n)(this.prototype, "entryUpdated", [_object.action]);
    }
    reviewUpdate(entry) {
      this.modal.show(_isbfCalendarUpdateDialog.default, {
        model: {
          entry,
          onChanged: this.entryUpdated,
          onRemove: this.deleteEntry
        }
      });
    }
    static {
      (0, _decorators.n)(this.prototype, "reviewUpdate", [_object.action]);
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
      const [personal, community] = await Promise.allSettled([this.currentUser ? (0, _ajax.ajax)("/isbf/api/entries.json", {
        data: personalData
      }) : Promise.resolve({
        entries: []
      }), Number(_theme.settings.calendar_category_id) > 0 ? (0, _ajax.ajax)("/discourse-post-event/events.json", {
        data: {
          after: data.from,
          before: data.to,
          category_id: _theme.settings.calendar_category_id,
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
      (0, _decorators.n)(this.prototype, "loadMonth", [_object.action]);
    }
    previousMonth() {
      this.#changeMonth(-1);
    }
    static {
      (0, _decorators.n)(this.prototype, "previousMonth", [_object.action]);
    }
    nextMonth() {
      this.#changeMonth(1);
    }
    static {
      (0, _decorators.n)(this.prototype, "nextMonth", [_object.action]);
    }
    goToday() {
      const today = new Date();
      this.visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1);
      this.selectedDate = dateKey(today);
      void this.loadMonth();
    }
    static {
      (0, _decorators.n)(this.prototype, "goToday", [_object.action]);
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
      (0, _decorators.n)(this.prototype, "selectDate", [_object.action]);
    }
    setFilter(filter) {
      this.filter = filter;
    }
    static {
      (0, _decorators.n)(this.prototype, "setFilter", [_object.action]);
    }
    newEntry() {
      this.modal.show(_isbfCalendarEntryEditor.default, {
        model: {
          selectedDate: this.selectedDate,
          onSaved: this.loadMonth
        }
      });
    }
    static {
      (0, _decorators.n)(this.prototype, "newEntry", [_object.action]);
    }
    editEntry(entry) {
      if (entry.source_item_id) {
        this.modal.show(_isbfCalendarNoteEditor.default, {
          model: {
            entry,
            onChanged: this.entryUpdated
          }
        });
        return;
      }
      this.modal.show(_isbfCalendarEntryEditor.default, {
        model: {
          entry,
          onSaved: this.loadMonth
        }
      });
    }
    static {
      (0, _decorators.n)(this.prototype, "editEntry", [_object.action]);
    }
    async deleteEntry(entry) {
      if (!(await this.dialog.confirm({
        message: (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.calendar_delete_confirm"))
      }))) {
        return;
      }
      try {
        await (0, _ajax.ajax)(`/isbf/api/entries/${entry.id}.json`, {
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
      (0, _decorators.n)(this.prototype, "deleteEntry", [_object.action]);
    }
    #selectEntry(entry) {
      const key = entry.source_item_id ? (0, _officialCalendar.officialDateKey)(entry.starts_at) : entry.all_day ? entry.starts_at.slice(0, 10) : dateKey(new Date(entry.starts_at));
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
        return (0, _officialCalendar.officialOccursOn)(item, key);
      }
      if (item.all_day) {
        return item.starts_at.slice(0, 10) <= key && key < item.ends_at.slice(0, 10);
      }
      const dayStart = new Date(`${key}T00:00:00`).getTime();
      const nextDay = new Date(localDate(key).getFullYear(), localDate(key).getMonth(), localDate(key).getDate() + 1).getTime();
      return new Date(item.starts_at).getTime() < nextDay && new Date(item.ends_at).getTime() > dayStart;
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
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
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          __keyword__on: _modifier.on,
          dIcon: _dIcon.default,
          __keyword__eq: _helper.eq,
          __keyword__fn: _helper.fn,
          DButton: _dButton.default,
          officialTimeLabel: _officialCalendar.officialTimeLabel,
          displayTime
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFV2Calendar;
});
define("dialog-review/discourse/components/isbf-calendar-entry-editor", ["exports", "@glimmer/component", "@glimmer/tracking", "@ember/object", "dialog-review/theme", "discourse/components/form", "discourse/lib/ajax", "discourse/truth-helpers", "discourse/ui-kit/d-button", "discourse/ui-kit/d-modal", "discourse/ui-kit/helpers/d-unique-id", "discourse-i18n", "@ember/component", "@ember/template-factory", "dialog-review/decorators"], function (_exports, _component, _tracking, _object, _theme, _form, _ajax, _truthHelpers, _dButton, _dModal, _dUniqueId, _discourseI18n, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFCalendarEntryEditor extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "error", [_tracking.tracked], function () {
        return false;
      });
    }
    #error = ((0, _decorators.i)(this, "error"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "saving", [_tracking.tracked], function () {
        return false;
      });
    }
    #saving = ((0, _decorators.i)(this, "saving"), void 0);
    formId = (0, _dUniqueId.default)();
    #formApi;
    get formData() {
      const entry = this.args.model.entry;
      const selectedDate = this.args.model.selectedDate;
      return {
        title: entry?.title || "",
        note: entry?.note || "",
        allDay: entry?.all_day || false,
        start: entry ? entry.all_day ? entry.starts_at.slice(0, 10) : this.#localInput(entry.starts_at) : `${selectedDate}T09:00`,
        end: entry ? entry.all_day ? new Date(new Date(entry.ends_at).getTime() - 86400000).toISOString().slice(0, 10) : this.#localInput(entry.ends_at) : `${selectedDate}T10:00`
      };
    }
    static {
      (0, _decorators.n)(this.prototype, "formData", [_tracking.cached]);
    }
    beforeClose() {
      return !this.saving;
    }
    static {
      (0, _decorators.n)(this.prototype, "beforeClose", [_object.action]);
    }
    async formChanged(name, value) {
      if (name === "allDay") {
        const start = this.#formApi.get("start").slice(0, 10);
        const end = this.#formApi.get("end").slice(0, 10);
        await this.#formApi.set("start", value ? start : `${start}T09:00`);
        await this.#formApi.set("end", value ? end : `${end}T10:00`);
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "formChanged", [_object.action]);
    }
    registerForm(api) {
      this.#formApi = api;
    }
    static {
      (0, _decorators.n)(this.prototype, "registerForm", [_object.action]);
    }
    async save(data) {
      if (this.saving) {
        return;
      }
      this.error = false;
      let startsAt;
      let endsAt;
      try {
        startsAt = data.allDay ? `${data.start}T00:00:00.000Z` : new Date(data.start).toISOString();
        endsAt = data.allDay ? new Date(new Date(`${data.end}T00:00:00.000Z`).getTime() + 86400000).toISOString() : new Date(data.end).toISOString();
        if (!data.title.trim() || endsAt <= startsAt) {
          this.error = true;
          return;
        }
      } catch {
        this.error = true;
        return;
      }
      this.saving = true;
      const entry = this.args.model.entry;
      try {
        await (0, _ajax.ajax)(entry ? `/isbf/api/entries/${entry.id}.json` : "/isbf/api/entries.json", {
          type: entry ? "PATCH" : "POST",
          data: {
            entry: {
              title: data.title.trim(),
              note: data.note.trim(),
              starts_at: startsAt,
              ends_at: endsAt,
              all_day: data.allDay
            }
          }
        });
        if (!this.isDestroying) {
          this.args.closeModal();
          await this.args.model.onSaved();
        }
      } catch {
        if (!this.isDestroying) {
          this.error = true;
        }
      } finally {
        if (!this.isDestroying) {
          this.saving = false;
        }
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "save", [_object.action]);
    }
    #localInput(value) {
      const date = new Date(value);
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}T${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <DModal
        class="isbf-calendar-entry-editor"
        ...attributes
        @beforeClose={{this.beforeClose}}
        @closeModal={{@closeModal}}
        @dismissable={{not this.saving}}
        @title={{i18n (themePrefix "isbf_v2.calendar_personal")}}
      >
        <:body>
          <Form
            id={{this.formId}}
            @data={{this.formData}}
            @onRegisterApi={{this.registerForm}}
            @onSet={{this.formChanged}}
            @onSubmit={{this.save}}
            as |form data|
          >
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="title"
              @title={{i18n (themePrefix "isbf_v2.calendar_title")}}
              @type="input-text"
              @validation="required"
              as |field|
            >
              <field.Control maxlength="120" />
            </form.Field>
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="allDay"
              @title={{i18n (themePrefix "isbf_v2.calendar_all_day")}}
              @type="checkbox"
              as |field|
            >
              <field.Control />
            </form.Field>
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="start"
              @title={{i18n (themePrefix "isbf_v2.calendar_start")}}
              @type={{if data.allDay "input-date" "input-datetime-local"}}
              @validation="required"
              as |field|
            >
              <field.Control />
            </form.Field>
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="end"
              @title={{i18n (themePrefix "isbf_v2.calendar_end")}}
              @type={{if data.allDay "input-date" "input-datetime-local"}}
              @validation="required"
              as |field|
            >
              <field.Control />
            </form.Field>
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="note"
              @title={{i18n (themePrefix "isbf_v2.calendar_note")}}
              @type="textarea"
              as |field|
            >
              <field.Control maxlength="2000" rows="3" />
            </form.Field>
            {{#if this.error}}
              <form.Alert @type="error">{{i18n
                  (themePrefix "isbf_v2.calendar_save_error")
                }}</form.Alert>
            {{/if}}
          </Form>
        </:body>
        <:footer>
          <DButton
            class="btn-primary"
            @disabled={{this.saving}}
            @form={{this.formId}}
            @label={{themePrefix "isbf_v2.calendar_save"}}
            @type="submit"
          />
          <DButton
            class="btn-default"
            @action={{@closeModal}}
            @disabled={{this.saving}}
            @label={{themePrefix "isbf_v2.calendar_cancel"}}
          />
        </:footer>
      </DModal>
      */
      {
        "id": null,
        "block": "[[[8,[32,0],[[24,0,\"isbf-calendar-entry-editor\"],[17,1]],[[\"@beforeClose\",\"@closeModal\",\"@dismissable\",\"@title\"],[[30,0,[\"beforeClose\"]],[30,2],[28,[32,1],[[30,0,[\"saving\"]]],null],[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_personal\"],null]],null]]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[8,[32,4],[[16,1,[30,0,[\"formId\"]]]],[[\"@data\",\"@onRegisterApi\",\"@onSet\",\"@onSubmit\"],[[30,0,[\"formData\"]],[30,0,[\"registerForm\"]],[30,0,[\"formChanged\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"title\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_title\"],null]],null],\"input-text\",\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,5,[\"Control\"]],[[24,\"maxlength\",\"120\"]],null,null],[1,\"\\n      \"]],[5]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\"],[[30,0,[\"saving\"]],\"full\",\"allDay\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_all_day\"],null]],null],\"checkbox\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,6,[\"Control\"]],null,null,null],[1,\"\\n      \"]],[6]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"start\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_start\"],null]],null],[52,[30,4,[\"allDay\"]],\"input-date\",\"input-datetime-local\"],\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,7,[\"Control\"]],null,null,null],[1,\"\\n      \"]],[7]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"end\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_end\"],null]],null],[52,[30,4,[\"allDay\"]],\"input-date\",\"input-datetime-local\"],\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,8,[\"Control\"]],null,null,null],[1,\"\\n      \"]],[8]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\"],[[30,0,[\"saving\"]],\"full\",\"note\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_note\"],null]],null],\"textarea\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,9,[\"Control\"]],[[24,\"maxlength\",\"2000\"],[24,\"rows\",\"3\"]],null,null],[1,\"\\n      \"]],[9]]]]],[1,\"\\n\"],[41,[30,0,[\"error\"]],[[[1,\"        \"],[8,[30,3,[\"Alert\"]],null,[[\"@type\"],[\"error\"]],[[\"default\"],[[[[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_save_error\"],null]],null]]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"    \"]],[3,4]]]]],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,5],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@form\",\"@label\",\"@type\"],[[30,0,[\"saving\"]],[30,0,[\"formId\"]],[28,[32,3],[\"isbf_v2.calendar_save\"],null],\"submit\"]],null],[1,\"\\n    \"],[8,[32,5],[[24,0,\"btn-default\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,2],[30,0,[\"saving\"]],[28,[32,3],[\"isbf_v2.calendar_cancel\"],null]]],null],[1,\"\\n  \"]],[]]]]]],[\"&attrs\",\"@closeModal\",\"form\",\"data\",\"field\",\"field\",\"field\",\"field\",\"field\"],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          DModal: _dModal.default,
          not: _truthHelpers.not,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          Form: _form.default,
          DButton: _dButton.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFCalendarEntryEditor;
});
define("dialog-review/discourse/components/isbf-learning-course-dialog", ["exports", "@glimmer/component", "@glimmer/tracking", "@ember/object", "dialog-review/theme", "discourse/components/form", "discourse/lib/ajax", "discourse/truth-helpers", "discourse/ui-kit/d-button", "discourse/ui-kit/d-modal", "discourse/ui-kit/helpers/d-unique-id", "discourse-i18n", "./isbf-learning-grade-picker", "@ember/component", "@ember/template-factory", "dialog-review/decorators"], function (_exports, _component, _tracking, _object, _theme, _form, _ajax, _truthHelpers, _dButton, _dModal, _dUniqueId, _discourseI18n, _isbfLearningGradePicker, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFLearningCourseDialog extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "error", [_tracking.tracked], function () {
        return null;
      });
    }
    #error = ((0, _decorators.i)(this, "error"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "grade", [_tracking.tracked]);
    }
    #grade = ((0, _decorators.i)(this, "grade"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "name", [_tracking.tracked], function () {
        return "";
      });
    }
    #name = ((0, _decorators.i)(this, "name"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "saving", [_tracking.tracked], function () {
        return false;
      });
    }
    #saving = ((0, _decorators.i)(this, "saving"), void 0);
    formData = {
      name: "",
      grade: this.args.grade
    };
    formId = (0, _dUniqueId.default)();
    #closed = false;
    constructor() {
      super(...arguments);
      this.grade = this.args.grade;
    }
    willDestroy() {
      super.willDestroy(...arguments);
      this.#closed = true;
    }
    get title() {
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.args.request ? "isbf_v2.learning_request_course" : "isbf_v2.learning_add_course"));
    }
    get submitLabel() {
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.args.request ? "isbf_v2.learning_submit_request" : "isbf_v2.learning_save"));
    }
    get saveDisabled() {
      const length = [...this.name.trim()].length;
      return this.saving || !length || length > 80;
    }
    formChanged(name, value) {
      if (name === "name") {
        this.name = value;
      } else if (name === "grade") {
        this.grade = value;
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "formChanged", [_object.action]);
    }
    close() {
      if (this.saving) {
        return;
      }
      this.#closed = true;
      this.args.onClose();
    }
    static {
      (0, _decorators.n)(this.prototype, "close", [_object.action]);
    }
    async save() {
      if (this.#closed || this.saveDisabled) {
        return;
      }
      this.error = null;
      this.saving = true;
      try {
        let response = await (0, _ajax.ajax)("/isbf/learning/courses", {
          type: "POST",
          data: {
            name: this.name.trim(),
            grade: this.grade
          }
        });
        if (this.#closed || this.isDestroying) {
          return;
        }
        if (!this.args.request && response?.course?.id && response.success === undefined && response.pending === undefined) {
          response = {
            ...response,
            success: true,
            pending: false
          };
        }
        if (response?.success !== true || typeof response.pending !== "boolean" || (response.pending ? !response.reviewable_id : !response.course?.id)) {
          throw new Error("Unexpected learning course response");
        }
        this.#closed = true;
        this.args.onSubmitted(response, this.grade);
      } catch (error) {
        if (!this.#closed && !this.isDestroying) {
          this.error = error?.jqXHR?.responseJSON?.errors?.[0] || (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.learning_course_save_error"));
        }
      } finally {
        if (!this.#closed && !this.isDestroying) {
          this.saving = false;
        }
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "save", [_object.action]);
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <DModal
        class="isbf-learning-course-dialog"
        ...attributes
        @closeModal={{this.close}}
        @dismissable={{not this.saving}}
        @title={{this.title}}
      >
        <:body>
          <Form
            id={{this.formId}}
            @data={{this.formData}}
            @onSet={{this.formChanged}}
            @onSubmit={{this.save}}
            as |form|
          >
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="name"
              @title={{i18n (themePrefix "isbf_v2.learning_course_name")}}
              @type="input-text"
              @validation="required"
              as |field|
            >
              <field.Control maxlength="80" />
            </form.Field>
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="grade"
              @title={{i18n (themePrefix "isbf_v2.learning_grade")}}
              @type="custom"
              as |field|
            >
              <field.Control>
                <ISBFLearningGradePicker
                  @disabled={{this.saving}}
                  @grades={{@grades}}
                  @onChange={{field.set}}
                  @value={{field.value}}
                />
              </field.Control>
            </form.Field>
            {{#if this.error}}
              <form.Alert @type="error">{{this.error}}</form.Alert>
            {{/if}}
          </Form>
        </:body>
        <:footer>
          <DButton
            class="btn-primary"
            @disabled={{this.saveDisabled}}
            @form={{this.formId}}
            @translatedLabel={{this.submitLabel}}
            @type="submit"
          />
          <DButton
            class="btn-default"
            @action={{this.close}}
            @disabled={{this.saving}}
            @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
          />
        </:footer>
      </DModal>
      */
      {
        "id": null,
        "block": "[[[8,[32,0],[[24,0,\"isbf-learning-course-dialog\"],[17,1]],[[\"@closeModal\",\"@dismissable\",\"@title\"],[[30,0,[\"close\"]],[28,[32,1],[[30,0,[\"saving\"]]],null],[30,0,[\"title\"]]]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[8,[32,2],[[16,1,[30,0,[\"formId\"]]]],[[\"@data\",\"@onSet\",\"@onSubmit\"],[[30,0,[\"formData\"]],[30,0,[\"formChanged\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[8,[30,2,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"name\",[28,[32,3],[[28,[32,4],[\"isbf_v2.learning_course_name\"],null]],null],\"input-text\",\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,3,[\"Control\"]],[[24,\"maxlength\",\"80\"]],null,null],[1,\"\\n      \"]],[3]]]]],[1,\"\\n      \"],[8,[30,2,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\"],[[30,0,[\"saving\"]],\"full\",\"grade\",[28,[32,3],[[28,[32,4],[\"isbf_v2.learning_grade\"],null]],null],\"custom\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,4,[\"Control\"]],null,null,[[\"default\"],[[[[1,\"\\n          \"],[8,[32,5],null,[[\"@disabled\",\"@grades\",\"@onChange\",\"@value\"],[[30,0,[\"saving\"]],[30,5],[30,4,[\"set\"]],[30,4,[\"value\"]]]],null],[1,\"\\n        \"]],[]]]]],[1,\"\\n      \"]],[4]]]]],[1,\"\\n\"],[41,[30,0,[\"error\"]],[[[1,\"        \"],[8,[30,2,[\"Alert\"]],null,[[\"@type\"],[\"error\"]],[[\"default\"],[[[[1,[30,0,[\"error\"]]]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"    \"]],[2]]]]],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,6],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@form\",\"@translatedLabel\",\"@type\"],[[30,0,[\"saveDisabled\"]],[30,0,[\"formId\"]],[30,0,[\"submitLabel\"]],\"submit\"]],null],[1,\"\\n    \"],[8,[32,6],[[24,0,\"btn-default\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"close\"]],[30,0,[\"saving\"]],[28,[32,3],[[28,[32,4],[\"isbf_v2.compose_cancel\"],null]],null]]],null],[1,\"\\n  \"]],[]]]]]],[\"&attrs\",\"form\",\"field\",\"field\",\"@grades\"],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          DModal: _dModal.default,
          not: _truthHelpers.not,
          Form: _form.default,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          ISBFLearningGradePicker: _isbfLearningGradePicker.default,
          DButton: _dButton.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFLearningCourseDialog;
});
define("dialog-review/discourse/components/isbf-resource-directory-dialog", ["exports", "@glimmer/component", "@glimmer/tracking", "@ember/object", "dialog-review/theme", "discourse/components/form", "discourse/lib/ajax", "discourse/truth-helpers", "discourse/ui-kit/d-button", "discourse/ui-kit/d-modal", "discourse/ui-kit/helpers/d-unique-id", "discourse-i18n", "./isbf-resource-parent-picker", "@ember/component", "@ember/template-factory", "dialog-review/decorators"], function (_exports, _component, _tracking, _object, _theme, _form, _ajax, _truthHelpers, _dButton, _dModal, _dUniqueId, _discourseI18n, _isbfResourceParentPicker, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFResourceDirectoryDialog extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "error", [_tracking.tracked], function () {
        return null;
      });
    }
    #error = ((0, _decorators.i)(this, "error"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "grade", [_tracking.tracked]);
    }
    #grade = ((0, _decorators.i)(this, "grade"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "name", [_tracking.tracked], function () {
        return "";
      });
    }
    #name = ((0, _decorators.i)(this, "name"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "saving", [_tracking.tracked], function () {
        return false;
      });
    }
    #saving = ((0, _decorators.i)(this, "saving"), void 0);
    formData = {
      name: "",
      grade: this.args.grade
    };
    formId = (0, _dUniqueId.default)();
    #closed = false;
    constructor() {
      super(...arguments);
      this.grade = this.args.grade;
    }
    willDestroy() {
      super.willDestroy(...arguments);
      this.#closed = true;
    }
    get endpoint() {
      return this.args.library ? `/isbf/library/${this.args.kind === "category" ? "categories" : "groups"}` : "/isbf/learning/courses";
    }
    get title() {
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.args.library ? `isbf_v2.library_${this.args.request ? "request" : "add"}_${this.args.kind}` : this.args.request ? "isbf_v2.learning_request_course" : "isbf_v2.learning_add_course"));
    }
    get submitLabel() {
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.args.request ? "isbf_v2.learning_submit_request" : "isbf_v2.learning_save"));
    }
    get saveDisabled() {
      const length = [...this.name.trim()].length;
      return this.saving || !length || length > 80 || this.args.library && this.args.kind === "group" && !this.grade;
    }
    formChanged(name, value) {
      if (name === "name") {
        this.name = value;
      } else if (name === "grade") {
        this.grade = value;
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "formChanged", [_object.action]);
    }
    close() {
      if (this.saving) {
        return;
      }
      this.#closed = true;
      this.args.onClose();
    }
    static {
      (0, _decorators.n)(this.prototype, "close", [_object.action]);
    }
    async save() {
      if (this.#closed || this.saveDisabled) {
        return;
      }
      this.error = null;
      this.saving = true;
      try {
        let response = await (0, _ajax.ajax)(this.endpoint, {
          type: "POST",
          data: {
            name: this.name.trim(),
            ...(this.args.library ? this.args.kind === "group" ? {
              category_id: this.grade
            } : {} : {
              grade: this.grade
            })
          }
        });
        if (this.#closed || this.isDestroying) {
          return;
        }
        if (!this.args.request && !this.args.library && response?.course?.id && response.success === undefined && response.pending === undefined) {
          response = {
            ...response,
            success: true,
            pending: false
          };
        }
        if (response?.success !== true || typeof response.pending !== "boolean" || (response.pending ? !response.reviewable_id : !(this.args.library ? response[this.args.kind]?.id : response.course?.id))) {
          throw new Error("Unexpected learning course response");
        }
        this.#closed = true;
        this.args.onSubmitted(response, this.args.library && this.args.kind === "category" && !response.pending ? response.category.id : this.grade);
      } catch (error) {
        if (!this.#closed && !this.isDestroying) {
          this.error = error?.jqXHR?.responseJSON?.errors?.[0] || (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.args.library ? "isbf_v2.library_directory_error" : "isbf_v2.learning_course_save_error"));
        }
      } finally {
        if (!this.#closed && !this.isDestroying) {
          this.saving = false;
        }
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "save", [_object.action]);
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <DModal
        class="isbf-learning-course-dialog"
        ...attributes
        @closeModal={{this.close}}
        @dismissable={{not this.saving}}
        @title={{this.title}}
      >
        <:body>
          <Form
            id={{this.formId}}
            @data={{this.formData}}
            @onSet={{this.formChanged}}
            @onSubmit={{this.save}}
            as |form|
          >
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="name"
              @title={{i18n
                (themePrefix
                  (if
                    @library
                    "isbf_v2.library_directory_name"
                    "isbf_v2.learning_course_name"
                  )
                )
              }}
              @type="input-text"
              @validation="required"
              as |field|
            >
              <field.Control maxlength="80" />
            </form.Field>
            {{#unless @library}}
              <form.Field
                @disabled={{this.saving}}
                @format="full"
                @name="grade"
                @title={{i18n (themePrefix "isbf_v2.learning_grade")}}
                @type="custom"
                as |field|
              >
                <field.Control>
                  <ISBFResourceParentPicker
                    @disabled={{this.saving}}
                    @grades={{@grades}}
                    @onChange={{field.set}}
                    @value={{field.value}}
                  />
                </field.Control>
              </form.Field>
            {{/unless}}
            {{#if this.error}}
              <form.Alert @type="error">{{this.error}}</form.Alert>
            {{/if}}
          </Form>
        </:body>
        <:footer>
          <DButton
            class="btn-primary"
            @disabled={{this.saveDisabled}}
            @form={{this.formId}}
            @translatedLabel={{this.submitLabel}}
            @type="submit"
          />
          <DButton
            class="btn-default"
            @action={{this.close}}
            @disabled={{this.saving}}
            @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
          />
        </:footer>
      </DModal>
      */
      {
        "id": null,
        "block": "[[[8,[32,0],[[24,0,\"isbf-learning-course-dialog\"],[17,1]],[[\"@closeModal\",\"@dismissable\",\"@title\"],[[30,0,[\"close\"]],[28,[32,1],[[30,0,[\"saving\"]]],null],[30,0,[\"title\"]]]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[8,[32,2],[[16,1,[30,0,[\"formId\"]]]],[[\"@data\",\"@onSet\",\"@onSubmit\"],[[30,0,[\"formData\"]],[30,0,[\"formChanged\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[8,[30,2,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"name\",[28,[32,3],[[28,[32,4],[[52,[30,3],\"isbf_v2.library_directory_name\",\"isbf_v2.learning_course_name\"]],null]],null],\"input-text\",\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,4,[\"Control\"]],[[24,\"maxlength\",\"80\"]],null,null],[1,\"\\n      \"]],[4]]]]],[1,\"\\n\"],[41,[51,[30,3]],[[[1,\"        \"],[8,[30,2,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\"],[[30,0,[\"saving\"]],\"full\",\"grade\",[28,[32,3],[[28,[32,4],[\"isbf_v2.learning_grade\"],null]],null],\"custom\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,5,[\"Control\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[8,[32,5],null,[[\"@disabled\",\"@grades\",\"@onChange\",\"@value\"],[[30,0,[\"saving\"]],[30,6],[30,5,[\"set\"]],[30,5,[\"value\"]]]],null],[1,\"\\n          \"]],[]]]]],[1,\"\\n        \"]],[5]]]]],[1,\"\\n\"]],[]],null],[41,[30,0,[\"error\"]],[[[1,\"        \"],[8,[30,2,[\"Alert\"]],null,[[\"@type\"],[\"error\"]],[[\"default\"],[[[[1,[30,0,[\"error\"]]]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"    \"]],[2]]]]],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,6],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@form\",\"@translatedLabel\",\"@type\"],[[30,0,[\"saveDisabled\"]],[30,0,[\"formId\"]],[30,0,[\"submitLabel\"]],\"submit\"]],null],[1,\"\\n    \"],[8,[32,6],[[24,0,\"btn-default\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"close\"]],[30,0,[\"saving\"]],[28,[32,3],[[28,[32,4],[\"isbf_v2.compose_cancel\"],null]],null]]],null],[1,\"\\n  \"]],[]]]]]],[\"&attrs\",\"form\",\"@library\",\"field\",\"field\",\"@grades\"],[\"if\",\"unless\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          DModal: _dModal.default,
          not: _truthHelpers.not,
          Form: _form.default,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          ISBFResourceParentPicker: _isbfResourceParentPicker.default,
          DButton: _dButton.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFResourceDirectoryDialog;
});
define("dialog-review/discourse/components/isbf-learning-grade-picker", ["exports", "@glimmer/component", "@ember/helper", "@ember/object", "dialog-review/theme", "discourse/float-kit/components/d-menu", "discourse/ui-kit/d-button", "discourse/ui-kit/d-dropdown-menu", "discourse-i18n", "@ember/component", "@ember/template-factory", "dialog-review/decorators"], function (_exports, _component, _helper, _object, _theme, _dMenu, _dButton, _dDropdownMenu, _discourseI18n, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFLearningGradePicker extends _component.default {
    get label() {
      return this.args.grades.find(grade => grade.id === this.args.value)?.label;
    }
    configureMenu(menu) {
      menu.options = {
        ...menu.options,
        constrainHeightToViewport: true,
        crossAxisShift: false,
        strategy: "fixed"
      };
    }
    static {
      (0, _decorators.n)(this.prototype, "configureMenu", [_object.action]);
    }
    async select(menu, id) {
      this.args.onChange(id);
      await menu.close();
    }
    static {
      (0, _decorators.n)(this.prototype, "select", [_object.action]);
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <DMenu
        @ariaLabel={{i18n (themePrefix "isbf_v2.learning_grade")}}
        @contentClass="isbf-learning-grade-menu"
        @disabled={{@disabled}}
        @icon="chevron-down"
        @label={{this.label}}
        @matchTriggerMinWidth={{true}}
        @modalForMobile={{false}}
        @onRegisterApi={{this.configureMenu}}
        @placement="bottom-start"
        @triggerClass="btn-flat isbf-learning__grade"
        @visibilityOptimizer="none"
      >
        <:content as |menu|>
          <DDropdownMenu as |dropdown|>
            {{#each @grades as |grade|}}
              <dropdown.item>
                <DButton
                  @action={{fn this.select menu grade.id}}
                  @translatedLabel={{grade.label}}
                />
              </dropdown.item>
            {{/each}}
          </DDropdownMenu>
        </:content>
      </DMenu>
      */
      {
        "id": null,
        "block": "[[[8,[32,0],null,[[\"@ariaLabel\",\"@contentClass\",\"@disabled\",\"@icon\",\"@label\",\"@matchTriggerMinWidth\",\"@modalForMobile\",\"@onRegisterApi\",\"@placement\",\"@triggerClass\",\"@visibilityOptimizer\"],[[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_grade\"],null]],null],\"isbf-learning-grade-menu\",[30,1],\"chevron-down\",[30,0,[\"label\"]],true,false,[30,0,[\"configureMenu\"]],\"bottom-start\",\"btn-flat isbf-learning__grade\",\"none\"]],[[\"content\"],[[[[1,\"\\n    \"],[8,[32,3],null,null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,4]],null]],null],null,[[[1,\"        \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n          \"],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[28,[32,5],[[30,0,[\"select\"]],[30,2],[30,5,[\"id\"]]],null],[30,5,[\"label\"]]]],null],[1,\"\\n        \"]],[]]]]],[1,\"\\n\"]],[5]],null],[1,\"    \"]],[3]]]]],[1,\"\\n  \"]],[2]]]]]],[\"@disabled\",\"menu\",\"dropdown\",\"@grades\",\"grade\"],[\"each\",\"-track-array\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          DMenu: _dMenu.default,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          DDropdownMenu: _dDropdownMenu.default,
          DButton: _dButton.default,
          fn: _helper.fn
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFLearningGradePicker;
});
define("dialog-review/discourse/components/isbf-resource-parent-picker", ["exports", "@glimmer/component", "@ember/helper", "@ember/object", "dialog-review/theme", "discourse/float-kit/components/d-menu", "discourse/ui-kit/d-button", "discourse/ui-kit/d-dropdown-menu", "discourse-i18n", "@ember/component", "@ember/template-factory", "dialog-review/decorators"], function (_exports, _component, _helper, _object, _theme, _dMenu, _dButton, _dDropdownMenu, _discourseI18n, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFResourceParentPicker extends _component.default {
    get ariaLabel() {
      return this.args.label || (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.learning_grade"));
    }
    get label() {
      return this.args.grades.find(grade => grade.id === this.args.value)?.label || this.args.label;
    }
    configureMenu(menu) {
      menu.options = {
        ...menu.options,
        constrainHeightToViewport: true,
        crossAxisShift: false,
        strategy: "fixed"
      };
    }
    static {
      (0, _decorators.n)(this.prototype, "configureMenu", [_object.action]);
    }
    async select(menu, id) {
      this.args.onChange(id);
      await menu.close();
    }
    static {
      (0, _decorators.n)(this.prototype, "select", [_object.action]);
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <DMenu
        @ariaLabel={{this.ariaLabel}}
        @contentClass="isbf-learning-grade-menu"
        @disabled={{@disabled}}
        @icon="chevron-down"
        @label={{this.label}}
        @matchTriggerMinWidth={{true}}
        @modalForMobile={{false}}
        @onRegisterApi={{this.configureMenu}}
        @placement="bottom-start"
        @title={{this.label}}
        @triggerClass="btn-flat isbf-learning__grade"
        @visibilityOptimizer="none"
      >
        <:content as |menu|>
          <DDropdownMenu as |dropdown|>
            {{#each @grades as |grade|}}
              <dropdown.item>
                <DButton
                  @action={{fn this.select menu grade.id}}
                  @translatedLabel={{grade.label}}
                />
              </dropdown.item>
            {{/each}}
          </DDropdownMenu>
        </:content>
      </DMenu>
      */
      {
        "id": null,
        "block": "[[[8,[32,0],null,[[\"@ariaLabel\",\"@contentClass\",\"@disabled\",\"@icon\",\"@label\",\"@matchTriggerMinWidth\",\"@modalForMobile\",\"@onRegisterApi\",\"@placement\",\"@title\",\"@triggerClass\",\"@visibilityOptimizer\"],[[30,0,[\"ariaLabel\"]],\"isbf-learning-grade-menu\",[30,1],\"chevron-down\",[30,0,[\"label\"]],true,false,[30,0,[\"configureMenu\"]],\"bottom-start\",[30,0,[\"label\"]],\"btn-flat isbf-learning__grade\",\"none\"]],[[\"content\"],[[[[1,\"\\n    \"],[8,[32,1],null,null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,4]],null]],null],null,[[[1,\"        \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n          \"],[8,[32,2],null,[[\"@action\",\"@translatedLabel\"],[[28,[32,3],[[30,0,[\"select\"]],[30,2],[30,5,[\"id\"]]],null],[30,5,[\"label\"]]]],null],[1,\"\\n        \"]],[]]]]],[1,\"\\n\"]],[5]],null],[1,\"    \"]],[3]]]]],[1,\"\\n  \"]],[2]]]]]],[\"@disabled\",\"menu\",\"dropdown\",\"@grades\",\"grade\"],[\"each\",\"-track-array\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          DMenu: _dMenu.default,
          DDropdownMenu: _dDropdownMenu.default,
          DButton: _dButton.default,
          fn: _helper.fn
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFResourceParentPicker;
});
define("dialog-review/fixtures", ["exports", "discourse/ui-kit/d-button", "discourse/ui-kit/d-modal", "dialog-review/discourse/components/isbf-learning-course-dialog", "dialog-review/discourse/components/isbf-resource-directory-dialog", "@ember/component", "@ember/template-factory", "@ember/component/template-only"], function (_exports, _dButton, _dModal, _isbfLearningCourseDialog, _isbfResourceDirectoryDialog, _component, _templateFactory, _templateOnly) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.Resource = _exports.Generic = _exports.Course = void 0;
  const Resource = _exports.Resource = (0, _component.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
  /*
    <ISBFResourceDirectoryDialog
    @grade={{@model.grade}}
    @grades={{@model.grades}}
    @kind={{@model.kind}}
    @library={{@model.library}}
    @onClose={{@closeModal}}
    @onSubmitted={{@model.onSubmitted}}
    @request={{@model.request}}
  />
  */
  {
    "id": null,
    "block": "[[[8,[32,0],null,[[\"@grade\",\"@grades\",\"@kind\",\"@library\",\"@onClose\",\"@onSubmitted\",\"@request\"],[[30,1,[\"grade\"]],[30,1,[\"grades\"]],[30,1,[\"kind\"]],[30,1,[\"library\"]],[30,2],[30,1,[\"onSubmitted\"]],[30,1,[\"request\"]]]],null]],[\"@model\",\"@closeModal\"],[]]",
    "moduleName": "(unknown template module)",
    "scope": () => ({
      ISBFResourceDirectoryDialog: _isbfResourceDirectoryDialog.default
    }),
    "isStrictMode": true
  }), (0, _templateOnly.default)());
  const Course = _exports.Course = (0, _component.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
  /*
    <ISBFLearningCourseDialog
    @grade={{@model.grade}}
    @grades={{@model.grades}}
    @onClose={{@closeModal}}
    @onSubmitted={{@model.onSubmitted}}
    @request={{@model.request}}
  />
  */
  {
    "id": null,
    "block": "[[[8,[32,0],null,[[\"@grade\",\"@grades\",\"@onClose\",\"@onSubmitted\",\"@request\"],[[30,1,[\"grade\"]],[30,1,[\"grades\"]],[30,2],[30,1,[\"onSubmitted\"]],[30,1,[\"request\"]]]],null]],[\"@model\",\"@closeModal\"],[]]",
    "moduleName": "(unknown template module)",
    "scope": () => ({
      ISBFLearningCourseDialog: _isbfLearningCourseDialog.default
    }),
    "isStrictMode": true
  }), (0, _templateOnly.default)());
  const Generic = _exports.Generic = (0, _component.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
  /*
    <DModal
    class={{@model.class}}
    @closeModal={{@closeModal}}
    @title="弹窗样式与长内容检查"
  >
    <:body>
      {{#each @model.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}
    </:body>
    <:footer>
      <DButton class="btn-primary" @translatedLabel="保存变更" />
      <DButton class="btn-default" @action={{@closeModal}} @translatedLabel="取消" />
    </:footer>
  </DModal>
  */
  {
    "id": null,
    "block": "[[[8,[32,0],[[16,0,[30,1,[\"class\"]]]],[[\"@closeModal\",\"@title\"],[[30,2],\"弹窗样式与长内容检查\"]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[42,[28,[31,1],[[28,[31,1],[[30,1,[\"paragraphs\"]]],null]],null],null,[[[10,2],[12],[1,[30,3]],[13]],[3]],null],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,1],[[24,0,\"btn-primary\"]],[[\"@translatedLabel\"],[\"保存变更\"]],null],[1,\"\\n    \"],[8,[32,1],[[24,0,\"btn-default\"]],[[\"@action\",\"@translatedLabel\"],[[30,2],\"取消\"]],null],[1,\"\\n  \"]],[]]]]]],[\"@model\",\"@closeModal\",\"paragraph\"],[\"each\",\"-track-array\"]]",
    "moduleName": "(unknown template module)",
    "scope": () => ({
      DModal: _dModal.default,
      DButton: _dButton.default
    }),
    "isStrictMode": true
  }), (0, _templateOnly.default)());
});

window.dialogReviewModules = Object.fromEntries(["dialog-review/discourse/components/isbf-frontend-scope","dialog-review/discourse/components/isbf-v2-calendar","dialog-review/discourse/components/isbf-calendar-entry-editor","dialog-review/discourse/components/isbf-learning-course-dialog","dialog-review/discourse/components/isbf-resource-directory-dialog","dialog-review/discourse/components/isbf-learning-grade-picker","dialog-review/discourse/components/isbf-resource-parent-picker","dialog-review/fixtures"].map(name => [name.slice("dialog-review/".length), window.moduleBroker.lookup(name)]));
