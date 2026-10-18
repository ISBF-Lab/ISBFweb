define("isbf-unread-review/decorators", ["exports", "./runtime--fcdnjmJ.js"], function (_exports, _runtimeFcdnjmJ) {
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
define("isbf-unread-review/runtime--fcdnjmJ.js", ["exports"], function (_exports) {
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

define("isbf-unread-review/theme", [], function () {
  return { themePrefix: (key) => "theme_translations.4." + key,
    get settings() { return window.moduleBroker.lookup("discourse/lib/theme-settings-store").getObjectForTheme(4); } };
});
for (const [name, exports] of Object.entries(window.isbfUnreadCachedTheme)) {
  if (!["isbf-unread-review/discourse/components/isbf-notification-action","isbf-unread-review/discourse/components/isbf-notification-bell","isbf-unread-review/discourse/components/isbf-notification-unread","isbf-unread-review/discourse/components/isbf-notifications","isbf-unread-review/discourse/components/isbf-v2-shell","isbf-unread-review/discourse/components/isbf-v2-side-nav","isbf-unread-review/discourse/initializers/isbf-notifications","isbf-unread-review/discourse/services/isbf-notifications","isbf-unread-review/discourse/components/isbf-notification-entry"].includes("isbf-unread-review/" + name)) {
    define("isbf-unread-review/" + name, [], function () { return exports; });
  }
}

define("isbf-unread-review/discourse/components/isbf-notification-action", ["exports", "@glimmer/component", "@glimmer/tracking", "@ember/modifier", "@ember/object", "@ember/render-modifiers/modifiers/did-update", "isbf-unread-review/theme", "discourse/lib/ajax", "discourse/ui-kit/d-button", "discourse/ui-kit/helpers/d-icon", "discourse-i18n", "../lib/notification-groups", "./isbf-notification-entry", "./isbf-notification-unread", "@ember/component", "@ember/template-factory", "isbf-unread-review/decorators"], function (_exports, _component, _tracking, _modifier, _object, _didUpdate, _theme, _ajax, _dButton, _dIcon, _discourseI18n, _notificationGroups, _isbfNotificationEntry, _isbfNotificationUnread, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFNotificationAction extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "entries", [_tracking.tracked], function () {
        return [];
      });
    }
    #entries = ((0, _decorators.i)(this, "entries"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "error", [_tracking.tracked], function () {
        return false;
      });
    }
    #error = ((0, _decorators.i)(this, "error"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "expanded", [_tracking.tracked], function () {
        return false;
      });
    }
    #expanded = ((0, _decorators.i)(this, "expanded"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "loaded", [_tracking.tracked], function () {
        return false;
      });
    }
    #loaded = ((0, _decorators.i)(this, "loaded"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "loading", [_tracking.tracked], function () {
        return false;
      });
    }
    #loading = ((0, _decorators.i)(this, "loading"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "nextCursor", [_tracking.tracked], function () {
        return null;
      });
    }
    #nextCursor = ((0, _decorators.i)(this, "nextCursor"), void 0);
    #generation = 0;
    get extraEntries() {
      return this.entries.filter(entry => entry.key !== this.args.group.latest.key);
    }
    get label() {
      const actionName = this.args.group.key;
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.notification_action_count"), {
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
        const response = await (0, _ajax.ajax)(this.args.group.detail_url, {
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
        this.entries = (0, _notificationGroups.mergeEntries)(this.entries, entries);
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
      (0, _decorators.n)(this.prototype, "loadMore", [_object.action]);
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
      (0, _decorators.n)(this.prototype, "refresh", [_object.action]);
    }
    toggle() {
      this.expanded = !this.expanded;
      if (this.expanded && !this.loaded) {
        this.loadMore();
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "toggle", [_object.action]);
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
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
          didUpdate: _didUpdate.default,
          on: _modifier.on,
          dIcon: _dIcon.default,
          ISBFNotificationUnread: _isbfNotificationUnread.default,
          ISBFNotificationEntry: _isbfNotificationEntry.default,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          DButton: _dButton.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFNotificationAction;
});
define("isbf-unread-review/discourse/components/isbf-notification-bell", ["exports", "@glimmer/component", "@ember/service", "discourse/ui-kit/helpers/d-concat-class", "discourse/ui-kit/helpers/d-icon", "@ember/component", "@ember/template-factory", "isbf-unread-review/decorators"], function (_exports, _component, _service, _dConcatClass, _dIcon, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFNotificationBell extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "isbfNotifications", [_service.service]);
    }
    #isbfNotifications = ((0, _decorators.i)(this, "isbfNotifications"), void 0);
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <span aria-hidden="true" class="isbf-notification-bell" ...attributes>
        {{dIcon "bell"}}
        {{#if this.isbfNotifications.unreadCount}}
          <span
            class={{dConcatClass
              "isbf-notification-bell__badge"
              (if this.isbfNotifications.dotStyle "--dot")
            }}
          >{{#unless
              this.isbfNotifications.dotStyle
            }}{{this.isbfNotifications.displayCount}}{{/unless}}</span>
        {{/if}}
      </span>
      */
      {
        "id": null,
        "block": "[[[11,1],[24,\"aria-hidden\",\"true\"],[24,0,\"isbf-notification-bell\"],[17,1],[12],[1,\"\\n  \"],[1,[28,[32,0],[\"bell\"],null]],[1,\"\\n\"],[41,[30,0,[\"isbfNotifications\",\"unreadCount\"]],[[[1,\"    \"],[10,1],[15,0,[28,[32,1],[\"isbf-notification-bell__badge\",[52,[30,0,[\"isbfNotifications\",\"dotStyle\"]],\"--dot\"]],null]],[12],[41,[51,[30,0,[\"isbfNotifications\",\"dotStyle\"]]],[[[1,[30,0,[\"isbfNotifications\",\"displayCount\"]]]],[]],null],[13],[1,\"\\n\"]],[]],null],[13]],[\"&attrs\"],[\"if\",\"unless\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          dIcon: _dIcon.default,
          dConcatClass: _dConcatClass.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFNotificationBell;
});
define("isbf-unread-review/discourse/components/isbf-notification-unread", ["exports", "isbf-unread-review/theme", "discourse-i18n", "@ember/component", "@ember/template-factory", "@ember/component/template-only"], function (_exports, _theme, _discourseI18n, _component, _templateFactory, _templateOnly) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  var _default = _exports.default = (0, _component.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
  /*
    {{#if @unread}}
    <span aria-hidden="true" class="isbf-notification-unread"></span>
    <span class="sr-only">{{i18n
        (themePrefix "isbf_v2.notifications_unread")
      }}</span>
  {{/if}}
  */
  {
    "id": null,
    "block": "[[[41,[30,1],[[[1,\"  \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-notification-unread\"],[12],[13],[1,\"\\n  \"],[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_unread\"],null]],null]],[13],[1,\"\\n\"]],[]],null]],[\"@unread\"],[\"if\"]]",
    "moduleName": "(unknown template module)",
    "scope": () => ({
      i18n: _discourseI18n.i18n,
      themePrefix: _theme.themePrefix
    }),
    "isStrictMode": true
  }), (0, _templateOnly.default)());
});
define("isbf-unread-review/discourse/components/isbf-notifications", ["exports", "@glimmer/component", "@glimmer/tracking", "@ember/helper", "@ember/modifier", "@ember/object", "@ember/runloop", "@ember/service", "isbf-unread-review/theme", "discourse/components/modal/dismiss-notification-confirmation", "discourse/lib/ajax", "discourse/lib/user-menu/notification-item", "discourse/models/notification", "discourse/ui-kit/d-button", "discourse/ui-kit/d-toggle-switch", "discourse/ui-kit/helpers/d-icon", "discourse-i18n", "../lib/notification-groups", "../lib/optional-topic-title", "./isbf-notification-action", "./isbf-notification-entry", "@ember/component", "@ember/template-factory", "isbf-unread-review/decorators"], function (_exports, _component, _tracking, _helper, _modifier, _object, _runloop, _service, _theme, _dismissNotificationConfirmation, _ajax, _notificationItem, _notification, _dButton, _dToggleSwitch, _dIcon, _discourseI18n, _notificationGroups, _optionalTopicTitle, _isbfNotificationAction, _isbfNotificationEntry, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFNotifications extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "a11y", [_service.service]);
    }
    #a11y = ((0, _decorators.i)(this, "a11y"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "appEvents", [_service.service]);
    }
    #appEvents = ((0, _decorators.i)(this, "appEvents"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "currentUser", [_service.service]);
    }
    #currentUser = ((0, _decorators.i)(this, "currentUser"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "isbfNotifications", [_service.service]);
    }
    #isbfNotifications = ((0, _decorators.i)(this, "isbfNotifications"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "modal", [_service.service]);
    }
    #modal = ((0, _decorators.i)(this, "modal"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "site", [_service.service]);
    }
    #site = ((0, _decorators.i)(this, "site"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "siteSettings", [_service.service]);
    }
    #siteSettings = ((0, _decorators.i)(this, "siteSettings"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "error", [_tracking.tracked], function () {
        return false;
      });
    }
    #error = ((0, _decorators.i)(this, "error"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "filter", [_tracking.tracked], function () {
        return "all";
      });
    }
    #filter = ((0, _decorators.i)(this, "filter"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "groups", [_tracking.tracked], function () {
        return [];
      });
    }
    #groups = ((0, _decorators.i)(this, "groups"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "loaded", [_tracking.tracked], function () {
        return false;
      });
    }
    #loaded = ((0, _decorators.i)(this, "loaded"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "loading", [_tracking.tracked], function () {
        return false;
      });
    }
    #loading = ((0, _decorators.i)(this, "loading"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "markingRead", [_tracking.tracked], function () {
        return false;
      });
    }
    #markingRead = ((0, _decorators.i)(this, "markingRead"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "markReadError", [_tracking.tracked], function () {
        return false;
      });
    }
    #markReadError = ((0, _decorators.i)(this, "markReadError"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "nextCursor", [_tracking.tracked], function () {
        return null;
      });
    }
    #nextCursor = ((0, _decorators.i)(this, "nextCursor"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "revision", [_tracking.tracked], function () {
        return 0;
      });
    }
    #revision = ((0, _decorators.i)(this, "revision"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "tab", [_tracking.tracked], function () {
        return "all";
      });
    }
    #tab = ((0, _decorators.i)(this, "tab"), void 0);
    #generation = 0;
    #models = new Map();
    constructor() {
      super(...arguments);
      this.tab = (0, _notificationGroups.consumeInitialNotificationTab)();
      this.appEvents.on("isbf:notification-tab", this, this.selectTab);
      this.appEvents.on("isbf:notifications-updated", this, this.onNotificationUpdate);
      (0, _runloop.scheduleOnce)("afterRender", this, this.loadMore);
    }
    willDestroy() {
      super.willDestroy(...arguments);
      this.appEvents.off("isbf:notification-tab", this, this.selectTab);
      this.appEvents.off("isbf:notifications-updated", this, this.onNotificationUpdate);
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
    actionLabel(actionName) {
      const known = ["liked", "reaction", "replied", "mentioned", "group_mentioned"];
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)(`isbf_v2.notification_${known.includes(actionName) ? actionName : "activity"}`));
    }
    static {
      (0, _decorators.n)(this.prototype, "actionLabel", [_object.action]);
    }
    loadMore() {
      return this.#loadGroups(false);
    }
    static {
      (0, _decorators.n)(this.prototype, "loadMore", [_object.action]);
    }
    refresh() {
      return this.#loadGroups(true);
    }
    static {
      (0, _decorators.n)(this.prototype, "refresh", [_object.action]);
    }
    onNotificationUpdate(data) {
      for (const [id, read] of data?.recent || []) {
        this.#models.get(id)?.set("read", read);
      }
      (0, _runloop.scheduleOnce)("afterRender", this, this.refresh);
    }
    static {
      (0, _decorators.n)(this.prototype, "onNotificationUpdate", [_object.action]);
    }
    async prepareEntries(entries) {
      const generation = this.#generation;
      await this.#initializeModels(entries.map(entry => entry.notification), generation);
      if (this.#stale(generation)) {
        return [];
      }
      return entries.map(entry => this.prepareEntry(entry));
    }
    static {
      (0, _decorators.n)(this.prototype, "prepareEntries", [_object.action]);
    }
    prepareEntry(entry) {
      const notification = this.#models.get(entry.notification.id);
      const item = new _notificationItem.default({
        notification,
        appEvents: this.appEvents,
        currentUser: this.currentUser,
        site: this.site,
        siteSettings: this.siteSettings
      });
      return {
        ...entry,
        notification,
        item,
        actionLabel: this.actionLabel(entry.action)
      };
    }
    static {
      (0, _decorators.n)(this.prototype, "prepareEntry", [_object.action]);
    }
    selectTab(tab) {
      if (this.tab === tab) {
        return;
      }
      this.tab = tab;
      this.#reset();
    }
    static {
      (0, _decorators.n)(this.prototype, "selectTab", [_object.action]);
    }
    toggleUnreadOnly() {
      this.filter = this.unreadOnly ? "all" : "unread";
      this.#reset();
    }
    static {
      (0, _decorators.n)(this.prototype, "toggleUnreadOnly", [_object.action]);
    }
    dismissNotifications() {
      const count = this.currentUser.unread_high_priority_notifications;
      if (count > 0) {
        this.modal.show(_dismissNotificationConfirmation.default, {
          model: {
            confirmationMessage: (0, _discourseI18n.i18n)("notifications.dismiss_confirmation.body.default", {
              count
            }),
            dismissNotifications: this.markRead
          }
        });
      } else {
        this.markRead();
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "dismissNotifications", [_object.action]);
    }
    async markRead() {
      if (this.markingRead) {
        return;
      }
      this.markingRead = true;
      this.markReadError = false;
      const version = this.isbfNotifications.version;
      try {
        await (0, _ajax.ajax)("/notifications/mark-read", {
          type: "PUT"
        });
        if (this.isDestroying) {
          return;
        }
        // A notification state received during this request may include a newer notice.
        if (this.isbfNotifications.version === version) {
          this.#models.forEach(notification => notification.set("read", true));
          this.currentUser.setProperties({
            grouped_unread_notifications: {},
            unread_high_priority_notifications: 0,
            unread_notifications: 0,
            all_unread_notifications_count: 0
          });
        }
        this.markReadError = false;
        this.refresh();
      } catch {
        if (!this.isDestroying) {
          this.markReadError = true;
          this.a11y.announce((0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.action_failed")), "assertive");
        }
      } finally {
        if (!this.isDestroying) {
          this.markingRead = false;
        }
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "markRead", [_object.action]);
    }
    onMenuKeydown(event) {
      if (event.key === "Escape") {
        event.currentTarget.open = false;
        event.currentTarget.querySelector("summary")?.focus();
        event.preventDefault();
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "onMenuKeydown", [_object.action]);
    }
    topicTitle(title) {
      return (0, _optionalTopicTitle.isUntitledTopicTitle)(title) ? (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.untitled_topic")) : title;
    }
    static {
      (0, _decorators.n)(this.prototype, "topicTitle", [_object.action]);
    }
    async #initializeModels(raw, generation) {
      const missing = [...new Map(raw.filter(notification => !this.#models.has(notification.id)).map(notification => [notification.id, notification])).values()];
      const models = await _notification.default.initializeNotifications(missing);
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
      if (this.isDestroying || !refresh && (this.loading || this.loaded && !this.nextCursor)) {
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
          const response = await (0, _ajax.ajax)("/isbf/notifications/groups.json", {
            data: {
              tab: this.tab,
              filter: this.filter,
              cursor,
              limit: 20
            }
          });
          if (this.#stale(generation)) {
            return;
          }
          incoming.push(...response.groups);
          cursor = response.next_cursor;
        } while (refresh && cursor && incoming.length < target);
        await this.#initializeModels(incoming.flatMap(group => group.kind === "topic" ? group.actions.map(item => item.latest.notification) : [group.latest.notification]), generation);
        if (this.#stale(generation)) {
          return;
        }
        const existing = new Set(refresh ? [] : this.groups.map(group => group.key));
        const groups = incoming.filter(group => !existing.has(group.key)).map(group => ({
          ...group,
          ...(group.kind === "topic" ? {
            actions: group.actions.map(item => ({
              ...item,
              latest: this.prepareEntry(item.latest)
            }))
          } : {
            latest: this.prepareEntry(group.latest)
          })
        }));
        this.groups = refresh ? groups : [...this.groups, ...groups];
        this.nextCursor = cursor;
        this.loaded = true;
        if (this.unreadOnly && !this.groups.length) {
          this.a11y.announce((0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.notifications_unread_empty")));
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
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
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
      */
      {
        "id": null,
        "block": "[[[10,\"main\"],[14,0,\"isbf-notifications\"],[12],[1,\"\\n  \"],[10,\"header\"],[14,0,\"isbf-notifications__heading\"],[12],[1,\"\\n    \"],[10,\"h1\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications\"],null]],null]],[13],[1,\"\\n    \"],[11,\"details\"],[24,0,\"isbf-notifications__menu\"],[4,[32,2],[\"keydown\",[30,0,[\"onMenuKeydown\"]]],null],[12],[1,\"\\n      \"],[10,\"summary\"],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_menu\"],null]],null]],[12],[1,[28,[32,3],[\"ellipsis\"],null]],[13],[1,\"\\n      \"],[10,0],[14,0,\"isbf-notifications__menu-items\"],[12],[1,\"\\n        \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"dismissNotifications\"]],[30,0,[\"markingRead\"]],[28,[32,1],[\"isbf_v2.notifications_mark_read\"],null]]],null],[1,\"\\n        \"],[10,3],[14,6,\"/my/preferences/notifications\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_settings\"],null]],null]],[13],[1,\"\\n        \"],[10,0],[14,0,\"isbf-notifications__filter\"],[12],[1,\"\\n          \"],[8,[32,5],[[4,[32,2],[\"click\",[30,0,[\"toggleUnreadOnly\"]]],null]],[[\"@label\",\"@state\"],[[28,[32,1],[\"isbf_v2.notifications_unread_only\"],null],[30,0,[\"unreadOnly\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n        \"],[10,0],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_badge_style\"],null]],null]],[14,0,\"isbf-notifications__badge-options\"],[14,\"role\",\"group\"],[12],[1,\"\\n          \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_badge_style\"],null]],null]],[13],[1,\"\\n          \"],[8,[32,4],null,[[\"@action\",\"@ariaPressed\",\"@disabled\",\"@label\"],[[28,[32,6],[[30,0,[\"isbfNotifications\",\"saveBadgeStyle\"]],\"number\"],null],[30,0,[\"isbfNotifications\",\"numberStyle\"]],[30,0,[\"isbfNotifications\",\"savingStyle\"]],[28,[32,1],[\"isbf_v2.notifications_badge_number\"],null]]],null],[1,\"\\n          \"],[8,[32,4],null,[[\"@action\",\"@ariaPressed\",\"@disabled\",\"@label\"],[[28,[32,6],[[30,0,[\"isbfNotifications\",\"saveBadgeStyle\"]],\"dot\"],null],[30,0,[\"isbfNotifications\",\"dotStyle\"]],[30,0,[\"isbfNotifications\",\"savingStyle\"]],[28,[32,1],[\"isbf_v2.notifications_badge_dot\"],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"],[41,[30,0,[\"isbfNotifications\",\"styleError\"]],[[[1,\"          \"],[10,0],[14,0,\"isbf-notifications__preference-error\"],[14,\"role\",\"alert\"],[12],[1,\"\\n            \"],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_badge_error\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,4],null,[[\"@action\",\"@disabled\",\"@label\"],[[30,0,[\"isbfNotifications\",\"retryBadgeStyle\"]],[30,0,[\"isbfNotifications\",\"savingStyle\"]],[28,[32,1],[\"isbf_v2.notifications_retry\"],null]]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n  \"],[10,0],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_tabs\"],null]],null]],[14,0,\"isbf-notifications__tabs\"],[14,\"role\",\"group\"],[12],[1,\"\\n    \"],[11,\"button\"],[16,\"aria-pressed\",[52,[30,0,[\"allSelected\"]],\"true\",\"false\"]],[16,0,[52,[30,0,[\"allSelected\"]],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,6],[[30,0,[\"selectTab\"]],\"all\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_all\"],null]],null]],[13],[1,\"\\n    \"],[11,\"button\"],[16,\"aria-pressed\",[52,[30,0,[\"mentionsSelected\"]],\"true\",\"false\"]],[16,0,[52,[30,0,[\"mentionsSelected\"]],\"is-active\"]],[24,4,\"button\"],[4,[32,2],[\"click\",[28,[32,6],[[30,0,[\"selectTab\"]],\"mentions\"],null]],null],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_mentions\"],null]],null]],[13],[1,\"\\n  \"],[13],[1,\"\\n  \"],[41,[30,0,[\"markReadError\"]],[[[10,0],[14,0,\"isbf-notifications__status\"],[14,\"role\",\"alert\"],[12],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.action_failed\"],null]],null]],[13],[8,[32,4],null,[[\"@action\",\"@label\"],[[30,0,[\"markRead\"]],[28,[32,1],[\"isbf_v2.notifications_retry\"],null]]],null],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"groups\",\"length\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-notifications__groups\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"groups\"]]],null]],null],\"key\",[[[41,[30,1,[\"topic\"]],[[[1,\"          \"],[10,\"article\"],[14,0,\"isbf-notifications__topic\"],[12],[1,\"\\n            \"],[10,\"h2\"],[14,0,\"isbf-notifications__topic-title\"],[12],[10,3],[15,6,[30,1,[\"topic\",\"url\"]]],[12],[1,[28,[30,0,[\"topicTitle\"]],[[30,1,[\"topic\",\"title\"]]],null]],[13],[13],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,1,[\"actions\"]]],null]],null],\"key\",[[[1,\"              \"],[8,[32,7],null,[[\"@actionLabel\",\"@group\",\"@prepareEntries\",\"@revision\"],[[30,0,[\"actionLabel\"]],[30,2],[30,0,[\"prepareEntries\"]],[30,0,[\"revision\"]]]],null],[1,\"\\n\"]],[2]],null],[1,\"          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,\"article\"],[14,0,\"isbf-notifications__standalone\"],[12],[8,[32,8],null,[[\"@entry\",\"@standalone\"],[[30,1,[\"latest\"]],true]],null],[13],[1,\"\\n\"]],[]]]],[1]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[41,[30,0,[\"loading\"]],[[[10,2],[14,0,\"isbf-notifications__status\"],[14,\"role\",\"status\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_loading\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"error\"]],[[[1,\"    \"],[10,0],[14,0,\"isbf-notifications__status\"],[14,\"role\",\"alert\"],[12],[10,2],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_error\"],null]],null]],[13],[8,[32,4],null,[[\"@action\",\"@label\"],[[30,0,[\"loadMore\"]],[28,[32,1],[\"isbf_v2.notifications_retry\"],null]]],null],[13],[1,\"\\n  \"]],[]],[[[41,[30,0,[\"isEmpty\"]],[[[10,2],[14,0,\"isbf-notifications__status\"],[12],[1,[28,[32,0],[[28,[32,1],[[52,[30,0,[\"unreadOnly\"]],\"isbf_v2.notifications_unread_empty\",\"isbf_v2.notifications_empty\"]],null]],null]],[13]],[]],null]],[]]],[1,\"\\n  \"],[41,[30,0,[\"nextCursor\"]],[[[8,[32,4],[[24,0,\"isbf-notifications__more\"]],[[\"@action\",\"@isLoading\",\"@label\"],[[30,0,[\"loadMore\"]],[30,0,[\"loading\"]],[28,[32,1],[\"isbf_v2.load_more\"],null]]],null]],[]],null],[1,\"\\n\"],[13]],[\"group\",\"item\"],[\"if\",\"each\",\"-track-array\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          on: _modifier.on,
          dIcon: _dIcon.default,
          DButton: _dButton.default,
          DToggleSwitch: _dToggleSwitch.default,
          fn: _helper.fn,
          ISBFNotificationAction: _isbfNotificationAction.default,
          ISBFNotificationEntry: _isbfNotificationEntry.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFNotifications;
});
define("isbf-unread-review/discourse/components/isbf-v2-shell", ["exports", "@glimmer/component", "@ember/modifier", "@ember/object", "@ember/owner", "@ember/service", "isbf-unread-review/theme", "discourse/components/plugin-outlet", "discourse/helpers/lazy-hash", "discourse/ui-kit/helpers/d-avatar", "discourse/ui-kit/helpers/d-icon", "discourse-i18n", "../lib/feedback-category", "../lib/frontend-consistency-scope", "../lib/notification-groups", "../lib/official-filters", "../lib/topic-card-scope", "./isbf-alumni", "./isbf-explore", "./isbf-learning", "./isbf-marketplace", "./isbf-notification-bell", "./isbf-notifications", "./isbf-official-feed", "./isbf-v2-account-menu", "./isbf-v2-anonymous-posts", "./isbf-v2-brand", "./isbf-v2-calendar", "./isbf-v2-right-rail", "./isbf-v2-side-nav", "./isbf-v2-workbench", "@ember/component", "@ember/template-factory", "isbf-unread-review/decorators"], function (_exports, _component, _modifier, _object, _owner, _service, _theme, _pluginOutlet, _lazyHash, _dAvatar, _dIcon, _discourseI18n, _feedbackCategory, _frontendConsistencyScope, _notificationGroups, _officialFilters, _topicCardScope, _isbfAlumni, _isbfExplore, _isbfLearning, _isbfMarketplace, _isbfNotificationBell, _isbfNotifications, _isbfOfficialFeed, _isbfV2AccountMenu, _isbfV2AnonymousPosts, _isbfV2Brand, _isbfV2Calendar, _isbfV2RightRail, _isbfV2SideNav, _isbfV2Workbench, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFV2Shell extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "categoryTypeChooser", [_service.service]);
    }
    #categoryTypeChooser = ((0, _decorators.i)(this, "categoryTypeChooser"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "currentUser", [_service.service]);
    }
    #currentUser = ((0, _decorators.i)(this, "currentUser"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "isbfBackNavigation", [_service.service]);
    }
    #isbfBackNavigation = ((0, _decorators.i)(this, "isbfBackNavigation"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "isbfNotifications", [_service.service]);
    }
    #isbfNotifications = ((0, _decorators.i)(this, "isbfNotifications"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "router", [_service.service]);
    }
    #router = ((0, _decorators.i)(this, "router"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "site", [_service.service]);
    }
    #site = ((0, _decorators.i)(this, "site"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "siteSettings", [_service.service]);
    }
    #siteSettings = ((0, _decorators.i)(this, "siteSettings"), void 0);
    get path() {
      return (this.router.currentURL ?? "").split("?")[0];
    }
    get informationPage() {
      return this.path.split("#")[0].match(/^\/(about|faq|guidelines|tos|privacy|rules|conduct)\/?$/)?.[1] ?? null;
    }
    get pageKind() {
      const path = this.path;
      if (/^\/(admin|login|signup|session)(\/|$)/.test(path)) {
        return null;
      }
      const scope = (0, _frontendConsistencyScope.frontendConsistencyScope)(this.router.currentRouteName);
      if (/^\/g(\/|$)/.test(path) && scope?.id.startsWith("group")) {
        return "groups";
      }
      if (scope?.id === "search" || scope?.id === "tags") {
        return scope.id;
      }
      if (this.informationPage) {
        return "information";
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
      if (path === "/isbf/workbench/resume" && this.siteSettings.isbf_resume_enabled) {
        return "resume";
      }
      if (path === "/isbf/workbench") {
        return "workbench";
      }
      if (path === "/isbf/alumni") {
        return "alumni";
      }
      if (path === "/isbf/marketplace") {
        return "marketplace";
      }
      if (path === "/isbf/learning") {
        return "learning";
      }
      if (/^\/u\/[^/]+\/notifications(\/|$)/.test(path)) {
        return "notifications";
      }
      if (/^\/u\/[^/]+\/activity\/bookmarks(\/|$)/.test(path)) {
        return "bookmarks";
      }
      if (/^\/u\/?$/.test(path)) {
        return "directory";
      }
      if (/^\/u\//.test(path)) {
        return "profile";
      }
      if (/^\/badges(\/|$)/.test(path)) {
        return "badges";
      }
      if (this.#isOfficialPath(path) || this.isFeedback) {
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
    get feedbackCategory() {
      return (0, _feedbackCategory.feedbackCategory)(this.site, _theme.settings.feedback_category_id);
    }
    get isFeedback() {
      return (0, _feedbackCategory.isFeedbackPath)(this.path, this.feedbackCategory);
    }
    get composePrompt() {
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.isFeedback ? "isbf_v2.feedback_prompt" : "isbf_v2.compose_prompt"));
    }
    get canCreateExploreCategory() {
      return Boolean(this.currentUser?.admin || this.currentUser?.moderator && this.siteSettings.moderators_manage_categories);
    }
    get showCustomExplore() {
      return this.path.replace(/\/$/, "") === "/categories" && this.siteSettings.isbf_explore_enabled;
    }
    get isNotifications() {
      return this.pageKind === "notifications";
    }
    get showGroupedNotifications() {
      return (0, _notificationGroups.notificationsEnabled)(this.path, this.currentUser, this.siteSettings);
    }
    get isAnonymousPosts() {
      return this.pageKind === "anonymous-posts";
    }
    get isCalendar() {
      return this.pageKind === "calendar";
    }
    get isWorkbench() {
      return ["workbench", "resume", "learning", "alumni", "marketplace"].includes(this.pageKind);
    }
    get isWorkbenchHome() {
      return this.pageKind === "workbench";
    }
    get isAlumni() {
      return this.pageKind === "alumni";
    }
    get isMarketplace() {
      return this.pageKind === "marketplace";
    }
    get isLearning() {
      return this.pageKind === "learning";
    }
    get showPageHeader() {
      return !this.isFeed && !["alumni", "calendar", "explore", "learning", "marketplace", "notifications", "workbench", "resume"].includes(this.pageKind);
    }
    get showSectionHeading() {
      return !this.showGroupedNotifications && ["bookmarks", "explore", "notifications"].includes(this.pageKind);
    }
    get showRightRail() {
      return _theme.settings.show_right_rail && !this.isCalendar && !this.isWorkbench && !this.isAnonymousPosts;
    }
    get isOwnProfile() {
      if (this.pageKind !== "profile" || !this.currentUser) {
        return false;
      }
      const profilePath = `/u/${encodeURIComponent(this.currentUser.username)}`.toLowerCase();
      const path = this.path.toLowerCase();
      return path === profilePath || path.startsWith(`${profilePath}/`);
    }
    get pageTitle() {
      if (this.informationPage) {
        return (0, _discourseI18n.i18n)(this.informationPage === "about" ? "about.simple_title" : this.informationPage);
      }
      if (this.pageKind === "badges") {
        return (0, _discourseI18n.i18n)("badges.title");
      }
      if (this.pageKind === "directory") {
        return (0, _discourseI18n.i18n)("directory.title");
      }
      const frontendTitles = {
        groups: "groups.index.all",
        search: "search.full_page_title",
        tags: "tagging.tags"
      };
      if (frontendTitles[this.pageKind]) {
        return (0, _discourseI18n.i18n)(frontendTitles[this.pageKind]);
      }
      const titles = {
        "anonymous-posts": "my_anonymous_posts",
        bookmarks: "bookmarks",
        calendar: "calendar",
        explore: "explore",
        notifications: "notifications",
        profile: "profile",
        topic: "topic",
        workbench: "workbench"
      };
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2." + titles[this.pageKind]));
    }
    get latestActive() {
      return this.path === "/" || this.path.startsWith("/latest");
    }
    get officialActive() {
      return this.#isOfficialPath(this.path);
    }
    get officialConfig() {
      return (0, _officialFilters.officialConfig)(this.site);
    }
    get showOfficialFeed() {
      return this.officialActive && Boolean(this.officialConfig);
    }
    get canCompose() {
      if (this.isFeedback) {
        return !this.currentUser || this.feedbackCategory.canCreateTopic;
      }
      if (!this.officialActive) {
        return true;
      }
      const categoryId = this.officialConfig?.category_id ?? Number(_theme.settings.official_path.split("/")[3]);
      const category = this.site.categories?.find(item => item.id === categoryId);
      return Boolean(this.currentUser?.academy_official_member && category?.canCreateTopic);
    }
    get showMobileCompose() {
      return this.isFeed && this.canCompose;
    }
    get showMobileReview() {
      return this.isFeed && (this.latestActive || this.officialActive) && Boolean(this.currentUser?.can_review);
    }
    get composeHref() {
      if (this.isFeedback) {
        return (0, _feedbackCategory.feedbackComposeHref)(this.feedbackCategory);
      }
      const categorySlug = _theme.settings.official_path.split("/")[2];
      return this.officialActive ? `/new-topic?category=${encodeURIComponent(categorySlug)}` : "/new-topic";
    }
    get topicController() {
      return (0, _owner.getOwner)(this).lookup("controller:topic");
    }
    get topicFeedStyle() {
      return (0, _topicCardScope.isFeedStyleTopic)(this.topicController.get("model"), this.path) || this.topicConversations;
    }
    get topicConversations() {
      return (0, _topicCardScope.isConversationTopic)(this.topicController.get("model"), this.path, this.siteSettings);
    }
    get shellClass() {
      const classes = ["isbf-v2-shell", `isbf-v2-shell--${this.pageKind}`];
      if (this.topicFeedStyle) {
        classes.push("isbf-v2-shell--topic-feed-style");
        if (this.topicConversations) {
          classes.push("isbf-v2-shell--topic-conversations");
        }
        if (this.topicController.get("editingTopic")) {
          classes.push("isbf-v2-shell--topic-editing");
        }
      }
      if (!this.isFeed && !this.showPageHeader) {
        classes.push("isbf-v2-shell--no-page-header");
      }
      if (this.showGroupedNotifications) {
        classes.push("isbf-v2-shell--grouped-notifications");
      }
      if (this.showCustomExplore) {
        classes.push("isbf-v2-shell--custom-explore");
      }
      if (this.showSectionHeading) {
        classes.push("isbf-v2-shell--section-heading");
      }
      if (this.showOfficialFeed) {
        classes.push("isbf-v2-shell--official-filtered");
      }
      if (this.officialActive) {
        classes.push("isbf-v2-shell--official");
      }
      if (this.isFeedback) {
        classes.push("isbf-v2-shell--feedback");
      }
      if (!this.canCompose) {
        classes.push("isbf-v2-shell--no-compose");
      }
      return classes.join(" ");
    }
    get profileHref() {
      return this.currentUser ? "/u/" + this.currentUser.username : "/login";
    }
    get notificationsHref() {
      return this.currentUser ? "/u/" + this.currentUser.username + "/notifications" : "/login";
    }
    get backHref() {
      return this.isbfBackNavigation.href("/latest");
    }
    goBack(event) {
      this.isbfBackNavigation.back(event);
    }
    static {
      (0, _decorators.n)(this.prototype, "goBack", [_object.action]);
    }
    createExploreCategory() {
      if (this.canCreateExploreCategory) {
        this.categoryTypeChooser.createCategory();
      }
    }
    static {
      (0, _decorators.n)(this.prototype, "createExploreCategory", [_object.action]);
    }
    #isOfficialPath(path) {
      const categoryPath = _theme.settings.official_path.split("/l/")[0];
      return path === categoryPath || path.startsWith(`${categoryPath}/`);
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        {{#if this.pageKind}}
        <div class={{this.shellClass}}>
          <ISBFV2SideNav />
          {{#if this.showRightRail}}<ISBFV2RightRail />{{/if}}
      
          {{#if this.isFeed}}
            {{#if this.isFeedback}}
              <header class="isbf-v2-feedback-header">
                <h1>{{i18n (themePrefix "isbf_v2.feedback")}}</h1>
              </header>
            {{else}}
              <header class="isbf-v2-feed-header">
                <div class="isbf-v2-feed-header__title">
                  {{#if this.currentUser}}
                    <a
                      aria-label={{i18n (themePrefix "isbf_v2.profile")}}
                      class="isbf-v2-feed-header__avatar isbf-avatar"
                      href={{this.profileHref}}
                    >{{dAvatar this.currentUser imageSize="small"}}<PluginOutlet
                        @name="user-avatar-frame"
                        @outletArgs={{lazyHash
                          user=this.currentUser
                          motion="static"
                        }}
                      /></a>
                  {{/if}}
                  <span>{{i18n (themePrefix "isbf_v2.home")}}</span>
                  <ISBFV2Brand
                    class="isbf-v2-feed-header__brand"
                    @mobile={{true}}
                  />
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
            {{/if}}
      
            {{#if this.canCompose}}
              <div class="isbf-v2-compose">
                {{#if this.currentUser}}
                  <a
                    aria-label={{this.currentUser.username}}
                    class="isbf-v2-compose__avatar isbf-avatar"
                    href={{this.profileHref}}
                  >{{dAvatar this.currentUser imageSize="large"}}<PluginOutlet
                      @name="user-avatar-frame"
                      @outletArgs={{lazyHash
                        user=this.currentUser
                        motion="static"
                      }}
                    /></a>
                {{/if}}
                <a
                  class="isbf-v2-compose__prompt"
                  href={{this.composeHref}}
                >{{this.composePrompt}}</a>
                <a
                  class="isbf-v2-compose__button"
                  href={{this.composeHref}}
                >{{i18n (themePrefix "isbf_v2.compose")}}</a>
              </div>
            {{/if}}
          {{else if this.showPageHeader}}
            <header class="isbf-v2-page-header">
              <a
                aria-label={{i18n "back_button"}}
                class="isbf-v2-page-header__back"
                href={{this.backHref}}
                {{on "click" this.goBack}}
              >{{dIcon "arrow-left"}}</a>
              <span>{{this.pageTitle}}</span>
              {{#if this.isOwnProfile}}<ISBFV2AccountMenu
                  @mobile={{true}}
                />{{/if}}
            </header>
          {{/if}}
      
          {{#if this.showSectionHeading}}
            <header class="isbf-v2-section-heading">
              <h1>{{this.pageTitle}}</h1>
            </header>
          {{/if}}
      
          {{#if this.showGroupedNotifications}}<ISBFNotifications />{{/if}}
      
          {{#if this.showCustomExplore}}<ISBFExplore
              @canCreateCategory={{this.canCreateExploreCategory}}
              @onCreateCategory={{this.createExploreCategory}}
            />{{/if}}
      
          {{#if this.showOfficialFeed}}<ISBFOfficialFeed
              @config={{this.officialConfig}}
            />{{/if}}
      
          {{#if this.isAnonymousPosts}}<ISBFV2AnonymousPosts />{{/if}}
          {{#if this.isCalendar}}<ISBFV2Calendar />{{/if}}
          {{#if this.isAlumni}}<ISBFAlumni />
          {{else if this.isMarketplace}}<ISBFMarketplace />
          {{else if this.isLearning}}<ISBFLearning />
          {{else if this.isWorkbenchHome}}<ISBFV2Workbench />{{/if}}
      
          {{#if this.showMobileCompose}}
            <a
              aria-label={{i18n (themePrefix "isbf_v2.compose")}}
              class="isbf-v2-mobile-compose"
              href={{this.composeHref}}
            >{{dIcon "plus"}}</a>
          {{/if}}
      
          {{#if this.showMobileReview}}
            <a
              aria-label={{i18n (themePrefix "isbf_v2.review")}}
              class="isbf-v2-mobile-review"
              href="/review"
            >{{i18n (themePrefix "isbf_v2.review")}}</a>
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
              aria-label={{this.isbfNotifications.linkLabel}}
              class={{if this.isNotifications "is-active"}}
              href={{this.notificationsHref}}
            ><ISBFNotificationBell /><span>{{i18n
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
      */
      {
        "id": null,
        "block": "[[[41,[30,0,[\"pageKind\"]],[[[1,\"  \"],[10,0],[15,0,[30,0,[\"shellClass\"]]],[12],[1,\"\\n    \"],[8,[32,0],null,null,null],[1,\"\\n    \"],[41,[30,0,[\"showRightRail\"]],[[[8,[32,1],null,null,null]],[]],null],[1,\"\\n\\n\"],[41,[30,0,[\"isFeed\"]],[[[41,[30,0,[\"isFeedback\"]],[[[1,\"        \"],[10,\"header\"],[14,0,\"isbf-v2-feedback-header\"],[12],[1,\"\\n          \"],[10,\"h1\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.feedback\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,\"header\"],[14,0,\"isbf-v2-feed-header\"],[12],[1,\"\\n          \"],[10,0],[14,0,\"isbf-v2-feed-header__title\"],[12],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"              \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.profile\"],null]],null]],[14,0,\"isbf-v2-feed-header__avatar isbf-avatar\"],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,4],[[30,0,[\"currentUser\"]]],[[\"imageSize\"],[\"small\"]]]],[8,[32,5],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,6],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n\"]],[]],null],[1,\"            \"],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.home\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,7],[[24,0,\"isbf-v2-feed-header__brand\"]],[[\"@mobile\"],[true]],null],[1,\"\\n            \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.search\"],null]],null]],[14,0,\"isbf-v2-feed-header__search\"],[14,6,\"/search\"],[12],[1,[28,[32,8],[\"magnifying-glass\"],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n          \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.feed_label\"],null]],null]],[12],[1,\"\\n            \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"latestActive\"]],\"page\"]],[15,0,[52,[30,0,[\"latestActive\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.latest\"],null]],null]],[13],[1,\"\\n            \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"officialActive\"]],\"page\"]],[15,0,[52,[30,0,[\"officialActive\"]],\"is-active\"]],[15,6,[32,9,[\"official_path\"]]],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.official\"],null]],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]]],[1,\"\\n\"],[41,[30,0,[\"canCompose\"]],[[[1,\"        \"],[10,0],[14,0,\"isbf-v2-compose\"],[12],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"            \"],[10,3],[15,\"aria-label\",[30,0,[\"currentUser\",\"username\"]]],[14,0,\"isbf-v2-compose__avatar isbf-avatar\"],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,4],[[30,0,[\"currentUser\"]]],[[\"imageSize\"],[\"large\"]]]],[8,[32,5],null,[[\"@name\",\"@outletArgs\"],[\"user-avatar-frame\",[28,[32,6],null,[[\"user\",\"motion\"],[[30,0,[\"currentUser\"]],\"static\"]]]]],null],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[10,3],[14,0,\"isbf-v2-compose__prompt\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[30,0,[\"composePrompt\"]]],[13],[1,\"\\n          \"],[10,3],[14,0,\"isbf-v2-compose__button\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.compose\"],null]],null]],[13],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null]],[]],[[[41,[30,0,[\"showPageHeader\"]],[[[1,\"      \"],[10,\"header\"],[14,0,\"isbf-v2-page-header\"],[12],[1,\"\\n        \"],[11,3],[16,\"aria-label\",[28,[32,2],[\"back_button\"],null]],[24,0,\"isbf-v2-page-header__back\"],[16,6,[30,0,[\"backHref\"]]],[4,[32,10],[\"click\",[30,0,[\"goBack\"]]],null],[12],[1,[28,[32,8],[\"arrow-left\"],null]],[13],[1,\"\\n        \"],[10,1],[12],[1,[30,0,[\"pageTitle\"]]],[13],[1,\"\\n        \"],[41,[30,0,[\"isOwnProfile\"]],[[[8,[32,11],null,[[\"@mobile\"],[true]],null]],[]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"]],[]],null]],[]]],[1,\"\\n\"],[41,[30,0,[\"showSectionHeading\"]],[[[1,\"      \"],[10,\"header\"],[14,0,\"isbf-v2-section-heading\"],[12],[1,\"\\n        \"],[10,\"h1\"],[12],[1,[30,0,[\"pageTitle\"]]],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"showGroupedNotifications\"]],[[[8,[32,12],null,null,null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"showCustomExplore\"]],[[[8,[32,13],null,[[\"@canCreateCategory\",\"@onCreateCategory\"],[[30,0,[\"canCreateExploreCategory\"]],[30,0,[\"createExploreCategory\"]]]],null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"showOfficialFeed\"]],[[[8,[32,14],null,[[\"@config\"],[[30,0,[\"officialConfig\"]]]],null]],[]],null],[1,\"\\n\\n    \"],[41,[30,0,[\"isAnonymousPosts\"]],[[[8,[32,15],null,null,null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"isCalendar\"]],[[[8,[32,16],null,null,null]],[]],null],[1,\"\\n    \"],[41,[30,0,[\"isAlumni\"]],[[[8,[32,17],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isMarketplace\"]],[[[8,[32,18],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isLearning\"]],[[[8,[32,19],null,null,null],[1,\"\\n    \"]],[]],[[[41,[30,0,[\"isWorkbenchHome\"]],[[[8,[32,20],null,null,null]],[]],null]],[]]]],[]]]],[]]],[1,\"\\n\"],[41,[30,0,[\"showMobileCompose\"]],[[[1,\"      \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.compose\"],null]],null]],[14,0,\"isbf-v2-mobile-compose\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[28,[32,8],[\"plus\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"showMobileReview\"]],[[[1,\"      \"],[10,3],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.review\"],null]],null]],[14,0,\"isbf-v2-mobile-review\"],[14,6,\"/review\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.review\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.quick_label\"],null]],null]],[14,0,\"isbf-v2-mobile-nav\"],[12],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isFeed\"]],\"page\"]],[15,0,[52,[30,0,[\"isFeed\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,8],[\"house\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.home\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isNotifications\"]],\"page\"]],[15,\"aria-label\",[30,0,[\"isbfNotifications\",\"linkLabel\"]]],[15,0,[52,[30,0,[\"isNotifications\"]],\"is-active\"]],[15,6,[30,0,[\"notificationsHref\"]]],[12],[8,[32,21],null,null,null],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.notifications\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isCalendar\"]],\"page\"]],[15,0,[52,[30,0,[\"isCalendar\"]],\"is-active\"]],[14,6,\"/isbf/calendar\"],[12],[1,[28,[32,8],[\"calendar-days\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar\"],null]],null]],[13],[13],[1,\"\\n      \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"isWorkbench\"]],\"page\"]],[15,0,[52,[30,0,[\"isWorkbench\"]],\"is-active\"]],[14,6,\"/isbf/workbench\"],[12],[1,[28,[32,8],[\"table-cells-large\"],null]],[10,1],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.workbench\"],null]],null]],[13],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          ISBFV2SideNav: _isbfV2SideNav.default,
          ISBFV2RightRail: _isbfV2RightRail.default,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          dAvatar: _dAvatar.default,
          PluginOutlet: _pluginOutlet.default,
          lazyHash: _lazyHash.default,
          ISBFV2Brand: _isbfV2Brand.default,
          dIcon: _dIcon.default,
          settings: _theme.settings,
          on: _modifier.on,
          ISBFV2AccountMenu: _isbfV2AccountMenu.default,
          ISBFNotifications: _isbfNotifications.default,
          ISBFExplore: _isbfExplore.default,
          ISBFOfficialFeed: _isbfOfficialFeed.default,
          ISBFV2AnonymousPosts: _isbfV2AnonymousPosts.default,
          ISBFV2Calendar: _isbfV2Calendar.default,
          ISBFAlumni: _isbfAlumni.default,
          ISBFMarketplace: _isbfMarketplace.default,
          ISBFLearning: _isbfLearning.default,
          ISBFV2Workbench: _isbfV2Workbench.default,
          ISBFNotificationBell: _isbfNotificationBell.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFV2Shell;
});
define("isbf-unread-review/discourse/components/isbf-v2-side-nav", ["exports", "@glimmer/component", "@ember/service", "isbf-unread-review/theme", "discourse/ui-kit/helpers/d-icon", "discourse-i18n", "../lib/feedback-category", "./isbf-notification-bell", "./isbf-v2-account-menu", "./isbf-v2-brand", "./isbf-v2-more-menu", "@ember/component", "@ember/template-factory", "isbf-unread-review/decorators"], function (_exports, _component, _service, _theme, _dIcon, _discourseI18n, _feedbackCategory, _isbfNotificationBell, _isbfV2AccountMenu, _isbfV2Brand, _isbfV2MoreMenu, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFV2SideNav extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "currentUser", [_service.service]);
    }
    #currentUser = ((0, _decorators.i)(this, "currentUser"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "isbfNotifications", [_service.service]);
    }
    #isbfNotifications = ((0, _decorators.i)(this, "isbfNotifications"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "router", [_service.service]);
    }
    #router = ((0, _decorators.i)(this, "router"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "site", [_service.service]);
    }
    #site = ((0, _decorators.i)(this, "site"), void 0);
    get composeHref() {
      const category = (0, _feedbackCategory.feedbackCategory)(this.site, _theme.settings.feedback_category_id);
      return (0, _feedbackCategory.isFeedbackPath)(this.router.currentURL, category) ? (0, _feedbackCategory.feedbackComposeHref)(category) : "/new-topic";
    }
    get bookmarksHref() {
      return this.currentUser ? `/u/${this.currentUser.username}/activity/bookmarks` : "/login";
    }
    get notificationsHref() {
      return this.currentUser ? `/u/${this.currentUser.username}/notifications` : "/login";
    }
    get profileHref() {
      return this.currentUser ? `/u/${this.currentUser.username}` : "/login";
    }
    get homeActive() {
      const path = this.router.currentURL ?? "";
      const officialPath = _theme.settings.official_path.split("/l/")[0];
      if ((0, _feedbackCategory.isFeedbackPath)(path, (0, _feedbackCategory.feedbackCategory)(this.site, _theme.settings.feedback_category_id))) {
        return false;
      }
      return path === "/" || path.startsWith("/latest") || path === officialPath || path.startsWith(`${officialPath}/`);
    }
    get exploreActive() {
      if ((0, _feedbackCategory.isFeedbackPath)(this.router.currentURL, (0, _feedbackCategory.feedbackCategory)(this.site, _theme.settings.feedback_category_id))) {
        return false;
      }
      return /^\/(search|categories|c|tag|tags)(\/|\?|$)/.test(this.router.currentURL ?? "");
    }
    get notificationsActive() {
      return /\/notifications(\/|\?|$)/.test(this.router.currentURL ?? "");
    }
    get calendarActive() {
      return (this.router.currentURL ?? "").startsWith("/isbf/calendar");
    }
    get workbenchActive() {
      return /^\/isbf\/(workbench|learning|alumni)(\/|\?|$)/.test(this.router.currentURL ?? "");
    }
    get bookmarksActive() {
      return /\/activity\/bookmarks(\/|\?|$)/.test(this.router.currentURL ?? "");
    }
    get profileActive() {
      const path = this.router.currentURL ?? "";
      return /^\/u\//.test(path) && !this.notificationsActive && !this.bookmarksActive;
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <aside
        aria-label={{i18n (themePrefix "isbf_v2.navigation_label")}}
        class="isbf-v2-side"
      >
        <ISBFV2Brand />
      
        <nav class="isbf-v2-side__links">
          <a
            aria-current={{if this.homeActive "page"}}
            class={{if this.homeActive "is-active"}}
            href="/latest"
          >{{dIcon "house"}}<span>{{i18n (themePrefix "isbf_v2.home")}}</span></a>
          <a
            aria-current={{if this.exploreActive "page"}}
            class={{if this.exploreActive "is-active"}}
            href="/categories"
          >{{dIcon "magnifying-glass"}}<span>{{i18n
                (themePrefix "isbf_v2.explore")
              }}</span></a>
          <a
            aria-current={{if this.notificationsActive "page"}}
            aria-label={{this.isbfNotifications.linkLabel}}
            class={{if this.notificationsActive "is-active"}}
            href={{this.notificationsHref}}
          ><ISBFNotificationBell /><span>{{i18n
                (themePrefix "isbf_v2.notifications")
              }}</span></a>
          <a
            aria-current={{if this.calendarActive "page"}}
            class={{if this.calendarActive "is-active"}}
            href="/isbf/calendar"
          >{{dIcon "calendar-days"}}<span>{{i18n
                (themePrefix "isbf_v2.calendar")
              }}</span></a>
          <a
            aria-current={{if this.workbenchActive "page"}}
            class={{if this.workbenchActive "is-active"}}
            href="/isbf/workbench"
          >{{dIcon "table-cells-large"}}<span>{{i18n
                (themePrefix "isbf_v2.workbench")
              }}</span></a>
          <a
            aria-current={{if this.bookmarksActive "page"}}
            class={{if this.bookmarksActive "is-active"}}
            href={{this.bookmarksHref}}
          >{{dIcon "bookmark"}}<span>{{i18n
                (themePrefix "isbf_v2.bookmarks")
              }}</span></a>
          <a
            aria-current={{if this.profileActive "page"}}
            class={{if this.profileActive "is-active"}}
            href={{this.profileHref}}
          >{{dIcon "user"}}<span>{{i18n
                (themePrefix "isbf_v2.profile")
              }}</span></a>
          <ISBFV2MoreMenu />
        </nav>
      
        <a class="isbf-v2-side__compose" href={{this.composeHref}}>{{i18n
            (themePrefix "isbf_v2.compose")
          }}</a>
      
        {{#if this.currentUser.can_review}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.review")}}
            class="isbf-v2-side__review"
            href="/review"
          >{{i18n (themePrefix "isbf_v2.review")}}</a>
        {{/if}}
      
        {{#if this.currentUser}}
          <ISBFV2AccountMenu />
        {{/if}}
      </aside>
      */
      {
        "id": null,
        "block": "[[[10,\"aside\"],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.navigation_label\"],null]],null]],[14,0,\"isbf-v2-side\"],[12],[1,\"\\n  \"],[8,[32,2],null,null,null],[1,\"\\n\\n  \"],[10,\"nav\"],[14,0,\"isbf-v2-side__links\"],[12],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"homeActive\"]],\"page\"]],[15,0,[52,[30,0,[\"homeActive\"]],\"is-active\"]],[14,6,\"/latest\"],[12],[1,[28,[32,3],[\"house\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.home\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"exploreActive\"]],\"page\"]],[15,0,[52,[30,0,[\"exploreActive\"]],\"is-active\"]],[14,6,\"/categories\"],[12],[1,[28,[32,3],[\"magnifying-glass\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.explore\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"notificationsActive\"]],\"page\"]],[15,\"aria-label\",[30,0,[\"isbfNotifications\",\"linkLabel\"]]],[15,0,[52,[30,0,[\"notificationsActive\"]],\"is-active\"]],[15,6,[30,0,[\"notificationsHref\"]]],[12],[8,[32,4],null,null,null],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"calendarActive\"]],\"page\"]],[15,0,[52,[30,0,[\"calendarActive\"]],\"is-active\"]],[14,6,\"/isbf/calendar\"],[12],[1,[28,[32,3],[\"calendar-days\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.calendar\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"workbenchActive\"]],\"page\"]],[15,0,[52,[30,0,[\"workbenchActive\"]],\"is-active\"]],[14,6,\"/isbf/workbench\"],[12],[1,[28,[32,3],[\"table-cells-large\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.workbench\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"bookmarksActive\"]],\"page\"]],[15,0,[52,[30,0,[\"bookmarksActive\"]],\"is-active\"]],[15,6,[30,0,[\"bookmarksHref\"]]],[12],[1,[28,[32,3],[\"bookmark\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.bookmarks\"],null]],null]],[13],[13],[1,\"\\n    \"],[10,3],[15,\"aria-current\",[52,[30,0,[\"profileActive\"]],\"page\"]],[15,0,[52,[30,0,[\"profileActive\"]],\"is-active\"]],[15,6,[30,0,[\"profileHref\"]]],[12],[1,[28,[32,3],[\"user\"],null]],[10,1],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.profile\"],null]],null]],[13],[13],[1,\"\\n    \"],[8,[32,5],null,null,null],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,3],[14,0,\"isbf-v2-side__compose\"],[15,6,[30,0,[\"composeHref\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.compose\"],null]],null]],[13],[1,\"\\n\\n\"],[41,[30,0,[\"currentUser\",\"can_review\"]],[[[1,\"    \"],[10,3],[15,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.review\"],null]],null]],[14,0,\"isbf-v2-side__review\"],[14,6,\"/review\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.review\"],null]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,0,[\"currentUser\"]],[[[1,\"    \"],[8,[32,6],null,null,null],[1,\"\\n\"]],[]],null],[13]],[],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          ISBFV2Brand: _isbfV2Brand.default,
          dIcon: _dIcon.default,
          ISBFNotificationBell: _isbfNotificationBell.default,
          ISBFV2MoreMenu: _isbfV2MoreMenu.default,
          ISBFV2AccountMenu: _isbfV2AccountMenu.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFV2SideNav;
});
define("isbf-unread-review/discourse/initializers/isbf-notifications", ["exports", "../services/isbf-notifications"], function (_exports, _isbfNotifications) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  _exports.initialize = initialize;
  function initialize(_container, owner) {
    owner.register("service:isbf-notifications", _isbfNotifications.default);
  }
  var _default = _exports.default = {
    name: "isbf-notification-state",
    after: "inject-objects",
    initialize
  };
});
define("isbf-unread-review/discourse/services/isbf-notifications", ["exports", "@glimmer/tracking", "@ember/runloop", "@ember/service", "isbf-unread-review/theme", "discourse/lib/ajax", "discourse/lib/decorators", "discourse-i18n", "isbf-unread-review/decorators"], function (_exports, _tracking, _runloop, _service, _theme, _ajax, _decorators, _discourseI18n, _decorators2) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFNotifications extends _service.default {
    static {
      (0, _decorators2.g)(this.prototype, "a11y", [_service.service]);
    }
    #a11y = ((0, _decorators2.i)(this, "a11y"), void 0);
    static {
      (0, _decorators2.g)(this.prototype, "appEvents", [_service.service]);
    }
    #appEvents = ((0, _decorators2.i)(this, "appEvents"), void 0);
    static {
      (0, _decorators2.g)(this.prototype, "currentUser", [_service.service]);
    }
    #currentUser = ((0, _decorators2.i)(this, "currentUser"), void 0);
    static {
      (0, _decorators2.g)(this.prototype, "messageBus", [_service.service]);
    }
    #messageBus = ((0, _decorators2.i)(this, "messageBus"), void 0);
    static {
      (0, _decorators2.g)(this.prototype, "siteSettings", [_service.service]);
    }
    #siteSettings = ((0, _decorators2.i)(this, "siteSettings"), void 0);
    static {
      (0, _decorators2.g)(this.prototype, "savingStyle", [_tracking.tracked], function () {
        return false;
      });
    }
    #savingStyle = ((0, _decorators2.i)(this, "savingStyle"), void 0);
    static {
      (0, _decorators2.g)(this.prototype, "styleError", [_tracking.tracked], function () {
        return false;
      });
    }
    #styleError = ((0, _decorators2.i)(this, "styleError"), void 0);
    version = 0;
    #channel;
    #requestedStyle;
    constructor() {
      super(...arguments);
      if (this.currentUser && this.siteSettings.isbf_notifications_enabled) {
        this.#channel = `/notification/${this.currentUser.id}`;
        this.messageBus.subscribe(this.#channel, this.onNotification);
        this.appEvents.on("user-menu:notification-click", this, this.onNotificationClick);
      }
    }
    willDestroy() {
      if (this.#channel) {
        this.messageBus.unsubscribe(this.#channel, this.onNotification);
        this.appEvents.off("user-menu:notification-click", this, this.onNotificationClick);
      }
      super.willDestroy(...arguments);
    }
    get displayCount() {
      return this.unreadCount > 99 ? "99+" : this.unreadCount;
    }
    get dotStyle() {
      return this.currentUser?.get("isbf_notification_badge_style") === "dot";
    }
    get linkLabel() {
      if (!this.unreadCount) {
        return (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.notifications"));
      }
      return (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.unreadCount > 99 ? "isbf_v2.notifications_badge_many" : "isbf_v2.notifications_badge_count"), {
        count: this.unreadCount
      });
    }
    get numberStyle() {
      return !this.dotStyle;
    }
    get unreadCount() {
      if (!this.currentUser || !this.siteSettings.isbf_notifications_enabled) {
        return 0;
      }
      // The header's counters exclude notices seen in a menu but still unread.
      return Object.values(this.currentUser.get("grouped_unread_notifications") || {}).reduce((total, count) => total + Math.max(0, Number(count) || 0), 0);
    }
    onNotification(data) {
      this.version++;
      this.currentUser.set("grouped_unread_notifications", data.grouped_unread_notifications);
      this.appEvents.trigger("isbf:notifications-updated", data);
    }
    static {
      (0, _decorators2.n)(this.prototype, "onNotification", [_decorators.bind]);
    }
    onNotificationClick() {
      (0, _runloop.scheduleOnce)("actions", this, this.#notifyLocalChange);
    }
    retryBadgeStyle() {
      return this.saveBadgeStyle(this.#requestedStyle);
    }
    static {
      (0, _decorators2.n)(this.prototype, "retryBadgeStyle", [_decorators.bind]);
    }
    async saveBadgeStyle(style) {
      if (!this.currentUser || this.savingStyle || !["number", "dot"].includes(style)) {
        return;
      }
      const userId = this.currentUser.id;
      this.#requestedStyle = style;
      this.savingStyle = true;
      this.styleError = false;
      try {
        await (0, _ajax.ajax)(`/u/${encodeURIComponent(this.currentUser.username)}.json`, {
          type: "PUT",
          data: {
            custom_fields: {
              isbf_notification_badge_style: style
            }
          }
        });
        if (!this.isDestroying && this.currentUser?.id === userId) {
          this.currentUser.set("isbf_notification_badge_style", style);
        }
      } catch {
        if (!this.isDestroying) {
          this.styleError = true;
          this.a11y.announce((0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.notifications_badge_error")), "assertive");
        }
      } finally {
        if (!this.isDestroying) {
          this.savingStyle = false;
        }
      }
    }
    static {
      (0, _decorators2.n)(this.prototype, "saveBadgeStyle", [_decorators.bind]);
    }
    #notifyLocalChange() {
      if (!this.isDestroying) {
        this.appEvents.trigger("isbf:notifications-updated");
      }
    }
  }
  _exports.default = ISBFNotifications;
});
define("isbf-unread-review/discourse/components/isbf-notification-entry", ["exports", "@glimmer/component", "@ember/modifier", "@ember/object", "@ember/service", "isbf-unread-review/theme", "discourse/components/user-menu/menu-item", "discourse/ui-kit/d-relative-date", "discourse/ui-kit/helpers/d-avatar", "discourse/ui-kit/helpers/d-icon", "discourse-i18n", "../lib/user-display", "@ember/component", "@ember/template-factory", "isbf-unread-review/decorators"], function (_exports, _component, _modifier, _object, _service, _theme, _menuItem, _dRelativeDate, _dAvatar, _dIcon, _discourseI18n, _userDisplay, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFNotificationEntry extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "siteSettings", [_service.service]);
    }
    #siteSettings = ((0, _decorators.i)(this, "siteSettings"), void 0);
    get useNativeSummary() {
      return this.args.standalone || !["liked", "reaction", "replied", "mentioned", "group_mentioned"].includes(this.args.entry.action);
    }
    get displayName() {
      const actor = this.args.entry.actor;
      if (!actor) {
        return null;
      }
      return (0, _userDisplay.displayIdentity)({
        name: this.siteSettings.enable_names ? actor.name : null,
        username: actor.username
      });
    }
    open(event) {
      this.args.entry.item.onClick({
        event
      });
    }
    static {
      (0, _decorators.n)(this.prototype, "open", [_object.action]);
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <div
        class={{if
          @entry.notification.read
          "isbf-notification-entry"
          "isbf-notification-entry is-unread"
        }}
      >
        {{#if @entry.actor}}
          <span class="isbf-notification-entry__avatar">{{dAvatar
              @entry.actor
              imageSize="medium"
            }}</span>
        {{else}}
          <span
            aria-hidden="true"
            class="isbf-notification-entry__avatar isbf-notification-entry__system"
          >{{dIcon @entry.item.icon}}</span>
        {{/if}}
        <div class="isbf-notification-entry__content">
          {{#unless @entry.notification.read}}<span class="sr-only">{{i18n
                (themePrefix "isbf_v2.notifications_unread")
              }}</span>{{/unless}}
          {{#if this.useNativeSummary}}
            <ul class="isbf-notification-entry__native"><MenuItem
                @item={{@entry.item}}
              /></ul>
          {{else}}
            <a
              class="isbf-notification-entry__link"
              href={{@entry.item.linkHref}}
              title={{@entry.item.linkTitle}}
              {{on "click" this.open}}
            >
              {{#if @entry.actor}}<span
                  class="isbf-notification-entry__name"
                >{{this.displayName}}</span>
              {{/if}}
              <span>{{@entry.actionLabel}}</span>
            </a>
          {{/if}}
          <span class="isbf-notification-entry__time"><DRelativeDate
              @date={{@entry.created_at}}
            /></span>
        </div>
      </div>
      */
      {
        "id": null,
        "block": "[[[10,0],[15,0,[52,[30,1,[\"notification\",\"read\"]],\"isbf-notification-entry\",\"isbf-notification-entry is-unread\"]],[12],[1,\"\\n\"],[41,[30,1,[\"actor\"]],[[[1,\"    \"],[10,1],[14,0,\"isbf-notification-entry__avatar\"],[12],[1,[28,[32,0],[[30,1,[\"actor\"]]],[[\"imageSize\"],[\"medium\"]]]],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-notification-entry__avatar isbf-notification-entry__system\"],[12],[1,[28,[32,1],[[30,1,[\"item\",\"icon\"]]],null]],[13],[1,\"\\n\"]],[]]],[1,\"  \"],[10,0],[14,0,\"isbf-notification-entry__content\"],[12],[1,\"\\n    \"],[41,[51,[30,1,[\"notification\",\"read\"]]],[[[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.notifications_unread\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"useNativeSummary\"]],[[[1,\"      \"],[10,\"ul\"],[14,0,\"isbf-notification-entry__native\"],[12],[8,[32,4],null,[[\"@item\"],[[30,1,[\"item\"]]]],null],[13],[1,\"\\n\"]],[]],[[[1,\"      \"],[11,3],[24,0,\"isbf-notification-entry__link\"],[16,6,[30,1,[\"item\",\"linkHref\"]]],[16,\"title\",[30,1,[\"item\",\"linkTitle\"]]],[4,[32,5],[\"click\",[30,0,[\"open\"]]],null],[12],[1,\"\\n        \"],[41,[30,1,[\"actor\"]],[[[10,1],[14,0,\"isbf-notification-entry__name\"],[12],[1,[30,0,[\"displayName\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,1],[12],[1,[30,1,[\"actionLabel\"]]],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]]],[1,\"    \"],[10,1],[14,0,\"isbf-notification-entry__time\"],[12],[8,[32,6],null,[[\"@date\"],[[30,1,[\"created_at\"]]]],null],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@entry\"],[\"if\",\"unless\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          dAvatar: _dAvatar.default,
          dIcon: _dIcon.default,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          MenuItem: _menuItem.default,
          on: _modifier.on,
          DRelativeDate: _dRelativeDate.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFNotificationEntry;
});
define("isbf-unread-review/wrapper", ["exports", "isbf-unread-review/discourse/components/isbf-v2-shell", "@ember/component", "@ember/template-factory", "@ember/component/template-only"], function (_exports, _isbfV2Shell, _component, _templateFactory, _templateOnly) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  var _default = _exports.default = (0, _component.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
  /*
    <Shell />
  */
  {
    "id": null,
    "block": "[[[8,[32,0],null,null,null]],[],[]]",
    "moduleName": "(unknown template module)",
    "scope": () => ({
      Shell: _isbfV2Shell.default
    }),
    "isStrictMode": true
  }), (0, _templateOnly.default)());
});

const unreadLookup = (name) => window.moduleBroker.lookup(name);
const { getComponentTemplate, setComponentTemplate } = unreadLookup("@ember/component");
setComponentTemplate(getComponentTemplate(unreadLookup("isbf-unread-review/wrapper").default), window.isbfUnreadCachedTheme["discourse/components/isbf-v2-shell"].default);
window.isbfUnreadCachedTheme["discourse/initializers/isbf-notifications"] = unreadLookup("isbf-unread-review/discourse/initializers/isbf-notifications");
for (const [lang, messages] of Object.entries({"en":{"continue_reading":{"title":"Keep reading","suggested":"New & unread","related":"Related topics","sources":"More topic sources","browse":"Browse more topics","browse_all":"Browse all →","browse_category":"Browse all topics in %{category}","all_categories":"All categories","replies":{"one":"%{count} reply","other":"%{count} replies"},"remaining_new":{"one":"%{count} new topic remaining","other":"%{count} new topics remaining"},"remaining_unread":{"one":"%{count} unread topic","other":"%{count} unread topics"}},"reply_conversations":{"progress":"%{current} / %{total}","reply_to":"Replying to %{name} · #%{number}","original_post":"Original post","go_to_original":"Go to original","context_loaded":"Original reply loaded","context_unavailable":"This reply is unavailable or could not be loaded."},"learning_request_course":"Request a course","learning_submit_request":"Submit request","learning_course_pending":"Course request submitted and awaiting review","learning_resource_description":"Brief introduction (optional)","learning_description_hint":"Up to 300 characters","learning_grade_1":"Year 1","learning_grade_2":"Year 2","learning_grade_3":"Year 3","learning_grade_4":"Year 4","learning_grade":"Year","learning_back":"Back to workbench","learning_search":"Search all learning resources","learning_search_results":"Search results","learning_search_hint":"Search covers all years and courses. Clear search to return to your selected course.","learning_select_course":"Select a course","learning_no_courses":"No courses in this year yet","learning_apply_share":"Apply to share resources","learning_resource_contributor":"Contributor","learning_contributor_hint":"Up to 15 characters; leave blank to use your display name","learning_unknown_contributor":"Unknown","learning_contributor_credit":"Contributor: ","learning_edit":"Edit resource","learning_save_changes":"Save changes","learning_edit_error":"Could not update the resource. Check the fields and try again.","learning_edit_load_error":"Could not load the resource. Try again.","learning_edit_unavailable":"This resource cannot currently be edited. Close this dialog and refresh the list.","learning_retry":"Retry","learning_edit_contributor_hint":"Up to 15 characters; leave blank to use the original contributor’s display name","learning_delete":"Delete","learning_delete_confirm":"Delete this learning resource?","learning_delete_error":"Could not delete the resource. Please retry.","learning_share":"Share resources","learning_resource_title":"Title","learning_resource_link":"Link","learning_share_error":"Could not share the resource. Check the title and link, then retry.","learning_share_pending":"Application submitted, awaiting administrator review","learning_share_unavailable":"Resource sharing is temporarily unavailable. Please try again later.","learning_files":"Attachments","learning_links":"Related links","learning_loading":"Loading…","learning_load_error":"Could not load. Please retry.","learning_empty":"No learning resources yet","learning_unavailable":"Learning resources are not available yet.","learning_login_required":"Sign in to view and share learning resources.","learning_add_course":"Add course","learning_course_name":"Course name","learning_course_save_error":"Could not save the course. Check its name and your permissions, then retry.","learning_save":"Save","official_campus":"Campus","official_type":"Type","official_all_campuses":"All campuses","official_all_types":"All types","official_loading":"Loading official posts…","official_load_error":"Could not load official posts. Please retry.","official_empty":"No official posts match these filters.","official_retry":"Retry","official_required":"Select at least one campus and one type.","official_selection_hint":"Official posts require at least one campus and one type. Multiple selections are allowed.","sidebar_more":"More","sidebar_settings":"Settings","appearance":"Appearance","appearance_light":"Light","appearance_dark":"Dark","appearance_auto":"System","appearance_unavailable":"Appearance switching is currently unavailable.","feedback":"Feedback","feedback_prompt":"Share a question or suggestion","feedback_unavailable":"Feedback is currently unavailable. Please try again later.","join_us":"Join us","join_us_pending":"Recruitment information is being prepared","severe_report":"Severe violation","severe_description":"Report a severe violation. The post will be hidden immediately and sent to moderators for review.","severe_reason":"Reason","severe_hint":"Enter 10–2000 characters explaining the violation.","severe_confirm":"Submitting will hide this post immediately. Please confirm.","severe_submit":"Submit and hide post","severe_back":"Back","severe_failed":"Could not submit the report. Please retry.","report_hidden":"This post is hidden pending review.","explore_categories":"Categories","explore_tags":"Tags","explore_selected_count":"%{label} · %{count}","explore_search_categories":"Search categories","explore_search_tags":"Search tags","explore_clear":"Clear","explore_no_options":"No matches","explore_create_category":"New category","explore_hot":"Popular","explore_new_topic":"New topic","explore_create_restricted":"You cannot create topics in the selected category","explore_loading":"Loading…","explore_restore_error":"Could not restore filters. Please retry.","explore_filter_unavailable":"The explore filter plugin needs updating. Refresh the page or contact a developer.","explore_save_error":"Could not save filters. Please retry.","explore_search_error":"Search failed. Please retry.","explore_retry":"Retry","explore_saving":"Saving…","explore_saved":"Saved","explore_guest_preferences":"Sign in to remember your filters","explore_all_topics":"All posts","explore_matching_tags":"Posts matching tags","explore_load_error":"Could not load posts. Please retry.","explore_empty":"No matching posts","explore_expand":"Expand post list","explore_collapse":"Collapse","explore_load_more":"Load more","explore_end":"All posts shown","anonymous_post":"Post anonymously","anonymous_post_hint":"After publishing, you cannot edit or delete this post.","my_anonymous_posts":"My anonymous posts","anonymous_posts_empty":"You have not posted anonymously yet.","anonymous_posts_load_error":"Could not load anonymous posts.","load_more":"Load more","home":"Home","explore":"Explore","notifications":"Notifications","bookmarks":"Bookmarks","profile":"Profile","account_actions":"Account actions","switch_account":"Switch account","link_account":"Link another account","account_username":"Target account username","account_username_placeholder":"Enter a username","send_link_request":"Send link request","account_link_pending":"Awaiting developer approval","verify_device":"Verify this device","switch_now":"Switch","target_password":"Target account password","device_verification_method":"Device verification method","password_verification":"Password","email_code_verification":"Email code","target_email_code":"Target account email code","send_email_code":"Send code","resend_email_code":"Resend code","email_code_sent":"A code was sent to the target account's email. It is valid for %{minutes} minutes.","authenticator_code_help":"Get the current code from the authenticator app linked to the target account. This is separate from the email code.","backup_code_help":"Enter a single-use backup code saved from the target account's Preferences → Security.","second_factor_code":"Target account two-factor code","second_factor_method":"Verification method","authenticator_code":"Authenticator code","backup_code":"Backup code","verify_and_switch":"Verify and switch","account_action_failed":"The account action failed. Please try again.","logout":"Log out","logout_confirm":"Log out of @%{username}?","logout_failed":"Could not log out. Please try again.","compose":"Post","review":"Review","quick_post":"New post","compose_prompt":"What's happening on campus?","compose_cancel":"Cancel","optional_title":"Title (optional)","compose_options":"Post options","reply":"Reply","repost":"Quote repost","like":"Like","bookmark_action":"Bookmark","views":"Views","views_count":"%{count} views","report":"Report","more_actions":"More actions","show_more":"Show more","show_less":"Show less","view_post":"View post","preview_open":"View update","preview_image":"View image","action_failed":"The action failed. Please try again.","latest":"Latest","official":"Official","search":"Search","search_placeholder":"Search ISBF","rail_label":"Community links","recent":"Recent discussions","view_all":"View all topics","hot":"Popular topics","top":"Top topics","categories":"Browse categories","navigation_label":"Main navigation","feed_label":"Feed filters","quick_label":"Quick navigation","topic":"Post","reading_progress":"Reading progress","back_home":"Back to home","workbench":"Workbench","workbench_pending":"Coming soon","workbench_intro":"The tools you use for campus life will gradually come together here.","workbench_modules":"Future services","workbench_learning_resources":"Learning resources","workbench_courses":"Courses","workbench_careers":"Jobs and internships","workbench_resume":"Resume tools","workbench_campus_services":"Campus services","workbench_student_identity":"Student verification","workbench_library":"Resource library","workbench_alumni":"Alumni network","calendar":"Calendar","calendar_filter_label":"Filter calendar contents","calendar_all":"All","calendar_personal":"Personal schedule","calendar_community":"Community events","calendar_add_personal":"Add schedule","calendar_publish_event":"Publish event","calendar_today":"Today","calendar_previous":"Previous month","calendar_next":"Next month","calendar_selected":"Selected day","calendar_all_day":"All day","calendar_loading":"Loading calendar…","calendar_load_error":"Some calendar items could not be loaded. Please try again.","calendar_empty":"Nothing planned for this day","calendar_title":"Title","calendar_start":"Start","calendar_end":"End","calendar_note":"Note","calendar_edit":"Edit","calendar_delete":"Delete","calendar_delete_confirm":"Delete this personal schedule entry?","calendar_close":"Close","calendar_cancel":"Cancel","calendar_save":"Save","calendar_save_error":"Check the title and times, then try again.","week_mon":"Mon","week_tue":"Tue","week_wed":"Wed","week_thu":"Thu","week_fri":"Fri","week_sat":"Sat","week_sun":"Sun","notifications_menu":"Notification actions","notifications_mark_read":"Mark all as read","notifications_settings":"Notification settings","notifications_tabs":"Notification filters","notifications_all":"All","notifications_mentions":"Mentions","notifications_loading":"Loading notifications…","notifications_error":"Could not load notifications. Please try again.","notifications_retry":"Retry","notifications_empty":"No notifications yet.","notifications_unread_empty":"You have no unread notifications.","notifications_unread_only":"Only unread","notifications_badge_style":"Badge display","notifications_badge_number":"Numbers","notifications_badge_dot":"Dot","notifications_badge_error":"Could not save the badge display. Please retry.","notifications_badge_count":{"one":"Notifications, %{count} unread notification","other":"Notifications, %{count} unread notifications"},"notifications_badge_many":"Notifications, more than 99 unread notifications","notification_liked":"Liked","notification_reaction":"Reacted","notification_replied":"Replied","notification_mentioned":"Mentioned you","notification_group_mentioned":"Mentioned your group","notification_activity":"Activity","notification_action_count":"%{action} · %{count}","notifications_unread":"Unread notification","topic_info":"Topic information and notifications","topic_edit_title":"Edit title, category and tags","schedule_editor_title":"Activity times and deadlines","schedule_timezone_hint":"Enter all dates and times in Beijing time (Asia/Shanghai).","schedule_name":"Name","schedule_type":"Type","schedule_event":"Activity","schedule_deadline":"Deadline","schedule_date_only":"Date only","schedule_due":"Due date or time","schedule_start":"Start date or time","schedule_end_optional":"End date or time (optional)","schedule_remove_item":"Remove time item","schedule_add_item":"Add time item","schedule_save_items":"Save time items","schedule_invalid_time":"Check the dates and times. An end cannot be before its start.","schedule_item_count":"Times and deadlines · %{count}","schedule_add":"Add to my calendar","schedule_added":"Added","schedule_add_error":"Could not add this item. Its information may have changed; check the times and try again.","schedule_deadline_day":"Due %{date} · Date only · Beijing time","schedule_deadline_time":"Due %{date} · Beijing time","schedule_event_day":"%{date} · All day · Beijing time","schedule_event_time":"%{date} · Beijing time","schedule_event_range":"%{start} – %{end} · Beijing time","schedule_imported":"From an official announcement","schedule_source":"View announcement","schedule_unavailable":"The source announcement is currently unavailable.","schedule_changed":"Changed","schedule_cancelled":"Cancelled","schedule_cancelled_hint":"The official time item has been cancelled or removed. Your calendar record and note remain until you remove them.","schedule_pending_count":"Changes to confirm · %{count}","schedule_pending_hint":"Includes changes outside this month. Your saved times stay the same until you confirm an update.","schedule_updates_error":"Could not load changes to confirm. Please try again.","schedule_review":"Review change","schedule_current":"Saved in your calendar","schedule_latest":"Latest official information","schedule_accept":"Update my calendar","schedule_keep":"Keep saved information","schedule_version_changed":"The official information changed again. Review the refreshed information before confirming.","schedule_update_error":"Could not confirm this change. Please try again.","schedule_edit_note":"Edit private note","schedule_note_error":"Could not save your note. Please try again.","schedule_activity_time":"Activity time","schedule_registration_deadline":"Registration deadline","schedule_has_registration_deadline":"Set a registration deadline","schedule_registration_date_only":"Registration deadline is date only","schedule_registration_name":"Registration deadline for %{name}","schedule_standalone_deadline":"Standalone deadline","schedule_location":"Location","schedule_organizer":"Organizer","schedule_none":"None","schedule_not_provided":"Not provided","schedule_too_many_items":"You can add up to %{max} time items. Activities and their registration deadlines count separately.","alumni_return_china":"Return to China","alumni_my_profile":"My alumni profile","alumni_country":"Country","alumni_region":"Province / state","alumni_city":"City","alumni_all":"All areas","alumni_directory":"Alumni directory","alumni_name":"Display name","alumni_industry":"Industry","alumni_select":"Select an area","alumni_city_optional":"Leave city unspecified","alumni_visible":"Show in the alumni directory","alumni_load_error":"Could not load alumni. Please retry.","alumni_save_error":"Could not read or save your profile. Please retry.","alumni_empty":"No public alumni profiles in this area.","alumni_unavailable":"Alumni network is unavailable.","alumni_login":"Log in to browse the alumni network.","alumni_map":"Alumni region map. Pan and zoom, or use the region menus above.","alumni_map_error":"Could not load the map. Region menus remain available.","workbench_marketplace":"Marketplace","marketplace_back":"Back to workbench","marketplace_unavailable":"Marketplace is not available yet.","marketplace_error":"Could not load products. Please retry.","marketplace_empty":"No products yet.","marketplace_login":"Log in to browse the marketplace.","marketplace_publish":"List a product","marketplace_price":"Price (yuan)","marketplace_home":"Also show on home","marketplace_composer_hint":"Enter a product name and description. Images are optional; attach, drag or paste them into the editor.","marketplace_validation":"Enter a product name, description and a nonnegative price with at most two decimal places.","marketplace_name":"Product name","marketplace_description":"Product description","image_retry":"Retry","untitled_topic":"Campus update","preview_picture":"Picture","preview_post":"View post"},"zh_CN":{"continue_reading":{"title":"接着看看","suggested":"新帖与未读","related":"相关话题","sources":"更多话题来源","browse":"浏览更多话题","browse_all":"浏览全部 →","browse_category":"浏览%{category}中的全部话题","all_categories":"所有分类","replies":{"other":"%{count} 回复"},"remaining_new":{"other":"还有 %{count} 个新话题"},"remaining_unread":{"other":"%{count} 个未读话题"}},"reply_conversations":{"progress":"%{current} / %{total}","reply_to":"回复 %{name} · #%{number}","original_post":"原帖","go_to_original":"定位原文","context_loaded":"已加载原回复","context_unavailable":"该回复不可查看，或暂时无法加载。"},"learning_request_course":"申请添加课程","learning_submit_request":"提交申请","learning_course_pending":"课程申请已提交，审核通过后展示","learning_resource_description":"简要介绍（选填）","learning_description_hint":"最多 300 字","learning_grade_1":"大一","learning_grade_2":"大二","learning_grade_3":"大三","learning_grade_4":"大四","learning_grade":"年级","learning_back":"返回工作台","learning_search":"搜索全部学习资源","learning_search_results":"搜索结果","learning_search_hint":"搜索范围包含所有年级和课程。清空搜索可返回所选课程。","learning_select_course":"选择课程","learning_no_courses":"本年级暂无课程","learning_apply_share":"申请分享资料","learning_resource_contributor":"贡献者","learning_contributor_hint":"最多 15 字；留空使用你的显示名称","learning_unknown_contributor":"未知","learning_contributor_credit":"贡献者：","learning_edit":"编辑资料","learning_save_changes":"保存修改","learning_edit_error":"资料修改失败，请检查填写内容后重试。","learning_edit_load_error":"资料读取失败，请重试。","learning_edit_unavailable":"这份资料目前无法编辑，请关闭后刷新列表。","learning_retry":"重试","learning_edit_contributor_hint":"最多 15 字；留空使用原投稿人的显示名称","learning_delete":"删除","learning_delete_confirm":"确认删除这份学习资料？","learning_delete_error":"资料删除失败，请重试。","learning_share":"分享资料","learning_resource_title":"标题","learning_resource_link":"链接","learning_share_error":"资料分享失败，请检查标题和链接后重试。","learning_share_pending":"申请已提交，等待管理员审核","learning_share_unavailable":"资料分享暂不可用，请稍后重试。","learning_files":"附件","learning_links":"相关链接","learning_loading":"正在加载…","learning_load_error":"加载失败，请重试。","learning_empty":"暂无学习资源","learning_unavailable":"学习资源暂未开放。","learning_login_required":"请登录后查看和分享学习资源。","learning_add_course":"添加课程","learning_course_name":"课程名称","learning_course_save_error":"课程保存失败，请检查名称、权限后重试。","learning_save":"保存","official_campus":"校区","official_type":"分类","official_all_campuses":"全部校区","official_all_types":"全部分类","official_loading":"正在加载官方信息…","official_load_error":"官方信息加载失败，请重试。","official_empty":"当前筛选下暂无官方信息。","official_retry":"重试","official_required":"请至少选择一个校区和一个类型。","official_selection_hint":"官方信息须选择校区和类型，可多选。","sidebar_more":"更多","sidebar_settings":"设置","appearance":"外观","appearance_light":"浅色","appearance_dark":"深色","appearance_auto":"跟随系统","appearance_unavailable":"当前外观暂不可切换，请稍后重试。","feedback":"反馈","feedback_prompt":"提出问题或建议","feedback_unavailable":"反馈暂不可用，请稍后重试。","join_us":"加入我们","join_us_pending":"招募信息筹备中","severe_report":"严重违规","severe_description":"请说明严重违规的具体情况。提交后帖子将立即下架，并交由管理员审核。","severe_reason":"举报理由","severe_hint":"请填写 10–2000 字的具体理由。","severe_confirm":"提交后立即下架，请确认","severe_submit":"提交并立即下架","severe_back":"返回","severe_failed":"举报提交失败，请重试。","report_hidden":"该帖子已下架，等待审核。","explore_categories":"类别","explore_tags":"标签","explore_selected_count":"%{label} · %{count}","explore_search_categories":"搜索类别","explore_search_tags":"搜索标签","explore_clear":"清空","explore_no_options":"没有匹配项","explore_create_category":"新建类别","explore_hot":"热门","explore_new_topic":"新建话题","explore_create_restricted":"你没有在所选类别中发布话题的权限","explore_loading":"正在加载…","explore_restore_error":"筛选偏好恢复失败，请重试。","explore_filter_unavailable":"探索筛选插件版本不兼容，请刷新页面；仍无法使用时请联系开发者。","explore_save_error":"筛选偏好保存失败，请重试。","explore_search_error":"搜索失败，请重试。","explore_retry":"重试","explore_saving":"正在保存…","explore_saved":"已保存","explore_guest_preferences":"登录后可记住筛选条件","explore_all_topics":"全部帖子","explore_matching_tags":"匹配标签的帖子","explore_load_error":"帖子加载失败，请重试。","explore_empty":"没有匹配的帖子","explore_expand":"展开帖子列表","explore_collapse":"收起","explore_load_more":"加载更多","explore_end":"已显示全部帖子","anonymous_post":"匿名发布","anonymous_post_hint":"发布后不能编辑或删除此帖。","my_anonymous_posts":"我的匿名帖子","anonymous_posts_empty":"你还没有匿名发布的帖子。","anonymous_posts_load_error":"匿名帖子加载失败。","load_more":"加载更多","home":"首页","explore":"探索","notifications":"通知","bookmarks":"书签","profile":"个人资料","account_actions":"账号操作","switch_account":"切换账号","link_account":"关联账号","account_username":"目标账号用户名","account_username_placeholder":"输入用户名","send_link_request":"发送关联申请","account_link_pending":"等待开发者批准","verify_device":"验证此设备","switch_now":"切换","target_password":"目标账号密码","device_verification_method":"设备验证方式","password_verification":"密码","email_code_verification":"邮箱验证码","target_email_code":"目标账号邮箱验证码","send_email_code":"发送验证码","resend_email_code":"重新发送验证码","email_code_sent":"验证码已发送至目标账号的邮箱，%{minutes} 分钟内有效。","authenticator_code_help":"在目标账号已绑定的身份验证器应用中获取动态验证码；此处不使用邮箱验证码。","backup_code_help":"输入目标账号在「偏好设置 → 安全」中保存的一次性备用验证码。","second_factor_code":"目标账号双重验证码","second_factor_method":"验证方式","authenticator_code":"身份验证器","backup_code":"备用验证码","verify_and_switch":"验证并切换","account_action_failed":"账号操作失败，请重试。","logout":"退出账号","logout_confirm":"确定退出账号 @%{username} 吗？","logout_failed":"退出失败，请重试。","compose":"发布","review":"审核","quick_post":"发布动态","compose_prompt":"有什么新鲜事？","compose_cancel":"取消","optional_title":"标题（可选）","compose_options":"发布选项","reply":"评论","repost":"引用转发","like":"点赞","bookmark_action":"书签","views":"浏览量","views_count":"浏览量 %{count}","report":"举报","more_actions":"更多操作","show_more":"显示更多","show_less":"收起","view_post":"查看帖子","preview_open":"查看动态","preview_image":"查看图片","action_failed":"操作失败，请稍后重试。","latest":"最新","official":"官方","search":"搜索","search_placeholder":"搜索国金社区","rail_label":"社区入口","recent":"最近讨论","view_all":"查看全部话题","hot":"热门话题","top":"精华内容","categories":"浏览分类","navigation_label":"主导航","feed_label":"信息流筛选","quick_label":"快捷导航","topic":"帖子","reading_progress":"阅读进度","back_home":"返回首页","workbench":"工作台","workbench_pending":"即将开放","workbench_intro":"你在校园生活中常用的工具，将陆续汇集于此。","workbench_modules":"未来服务","workbench_learning_resources":"学习资源","workbench_courses":"课程专区","workbench_careers":"求职实习","workbench_resume":"简历工具","workbench_campus_services":"校园服务","workbench_student_identity":"学生认证","workbench_library":"资料库","workbench_alumni":"校友网络","calendar":"日历","calendar_filter_label":"日历内容筛选","calendar_all":"全部","calendar_personal":"个人行程","calendar_community":"社区活动","calendar_add_personal":"添加行程","calendar_publish_event":"发布活动","calendar_today":"今天","calendar_previous":"上个月","calendar_next":"下个月","calendar_selected":"当日安排","calendar_all_day":"全天","calendar_loading":"正在加载日历…","calendar_load_error":"部分日历内容加载失败，请稍后重试。","calendar_empty":"这一天还没有安排","calendar_title":"行程名称","calendar_start":"开始","calendar_end":"结束","calendar_note":"备注","calendar_edit":"编辑","calendar_delete":"删除","calendar_delete_confirm":"确定删除这条个人行程吗？","calendar_close":"关闭","calendar_cancel":"取消","calendar_save":"保存","calendar_save_error":"请检查标题和时间后重试。","week_mon":"一","week_tue":"二","week_wed":"三","week_thu":"四","week_fri":"五","week_sat":"六","week_sun":"日","notifications_menu":"通知操作","notifications_mark_read":"全部标为已读","notifications_settings":"通知设置","notifications_tabs":"通知筛选","notifications_all":"全部","notifications_mentions":"提及","notifications_loading":"正在加载通知…","notifications_error":"通知加载失败，请重试。","notifications_retry":"重试","notifications_empty":"暂时没有通知。","notifications_unread_empty":"当前没有未读通知。","notifications_unread_only":"只看未读","notifications_badge_style":"角标显示","notifications_badge_number":"数字","notifications_badge_dot":"圆点","notifications_badge_error":"角标显示方式保存失败，请重试。","notifications_badge_count":{"other":"通知，%{count} 条未读通知"},"notifications_badge_many":"通知，超过 99 条未读通知","notification_liked":"点赞","notification_reaction":"回应","notification_replied":"回复","notification_mentioned":"提及了你","notification_group_mentioned":"提及了你的群组","notification_activity":"动态","notification_action_count":"%{action} · %{count}","notifications_unread":"未读通知","topic_info":"话题信息与订阅","topic_edit_title":"编辑标题、分类和标签","schedule_editor_title":"活动时间与截止日期","schedule_timezone_hint":"所有日期和时间均按北京时间（Asia/Shanghai）填写。","schedule_name":"名称","schedule_type":"类型","schedule_event":"活动","schedule_deadline":"截止日期","schedule_date_only":"仅日期","schedule_due":"截止日期或时间","schedule_start":"开始日期或时间","schedule_end_optional":"结束日期或时间（可选）","schedule_remove_item":"移除时间项","schedule_add_item":"添加时间项","schedule_save_items":"保存时间项","schedule_invalid_time":"请检查日期和时间，结束时间不能早于开始时间。","schedule_item_count":"时间与截止日期 · %{count}","schedule_add":"添加到我的日历","schedule_added":"已添加","schedule_add_error":"添加失败，官方时间信息可能已变更，请核对时间后重试。","schedule_deadline_day":"%{date} 截止 · 仅日期 · 北京时间","schedule_deadline_time":"%{date} 截止 · 北京时间","schedule_event_day":"%{date} · 全天 · 北京时间","schedule_event_time":"%{date} · 北京时间","schedule_event_range":"%{start} 至 %{end} · 北京时间","schedule_imported":"来自官方消息","schedule_source":"查看原消息","schedule_unavailable":"原消息暂时无法访问。","schedule_changed":"信息已变更","schedule_cancelled":"已取消","schedule_cancelled_hint":"官方已取消或移除该时间项。日历记录和备注会保留，直到你主动删除。","schedule_pending_count":"待确认变更 · %{count}","schedule_pending_hint":"包含其他月份的变更。确认更新之前，日历保留原有时间信息。","schedule_updates_error":"待确认变更加载失败，请重试。","schedule_review":"查看变更","schedule_current":"日历中保留的信息","schedule_latest":"官方最新信息","schedule_accept":"更新我的日历","schedule_keep":"保留原信息","schedule_version_changed":"官方信息再次变更，请核对刷新后的信息再确认。","schedule_update_error":"变更确认失败，请重试。","schedule_edit_note":"编辑私人备注","schedule_note_error":"备注保存失败，请重试。","schedule_activity_time":"活动时间","schedule_registration_deadline":"报名截止时间","schedule_has_registration_deadline":"设置报名截止时间","schedule_registration_date_only":"报名截止仅填写日期","schedule_registration_name":"%{name}报名截止","schedule_standalone_deadline":"独立截止","schedule_location":"地点","schedule_organizer":"主办方","schedule_none":"无","schedule_not_provided":"未填写","schedule_too_many_items":"最多可填写 %{max} 个时间项，活动和报名截止分别计数。","alumni_return_china":"返回中国","alumni_my_profile":"我的校友资料","alumni_country":"国家","alumni_region":"省／州","alumni_city":"城市","alumni_all":"全部地区","alumni_directory":"校友名单","alumni_name":"展示姓名","alumni_industry":"行业","alumni_select":"请选择","alumni_city_optional":"暂不填写城市","alumni_visible":"在校友网络展示","alumni_load_error":"校友名单加载失败，请重试。","alumni_save_error":"资料读取或保存失败，请重试。","alumni_empty":"该地区暂无公开展示的校友资料。","alumni_unavailable":"校友网络暂未开放。","alumni_login":"登录后查看校友网络。","alumni_map":"校友地区地图，可拖动和缩放；也可使用上方菜单选择地区。","alumni_map_error":"地图加载失败，仍可使用地区菜单查询。","workbench_marketplace":"商城","marketplace_back":"返回工作台","marketplace_unavailable":"商城尚未开放。","marketplace_error":"商品加载失败，请重试。","marketplace_empty":"暂无商品。","marketplace_login":"登录后查看商城。","marketplace_publish":"发布商品","marketplace_price":"价格（元）","marketplace_home":"同时发布到首页","marketplace_composer_hint":"请填写商品名称和详细描述。图片可选，可通过附件按钮、拖放或粘贴上传。","marketplace_validation":"请填写商品名称、详细描述及有效价格（非负数，最多两位小数）。","marketplace_name":"商品名称","marketplace_description":"商品描述","image_retry":"重试","untitled_topic":"校园动态","preview_picture":"图片","preview_post":"查看帖子"}})) {
  const data = window._discourse_locale_data;
  data.theme ??= {}; data.theme[4] ??= {}; data.theme[4][lang] ??= {};
  data.theme[4][lang].isbf_v2 = { ...data.theme[4][lang].isbf_v2, ...messages };
  const existing = unreadLookup("discourse-i18n").default.translations?.[lang]?.js?.theme_translations?.[4];
  if (existing) existing.isbf_v2 = { ...existing.isbf_v2, ...messages };
}
window.isbfUnreadSourceInstalled = true;
