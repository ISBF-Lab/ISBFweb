define("profile-preview-review/decorators", ["exports", "./runtime--fcdnjmJ.js"], function (_exports, _runtimeFcdnjmJ) {
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
define("profile-preview-review/runtime--fcdnjmJ.js", ["exports"], function (_exports) {
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

define("profile-preview-review/theme", [], function () {
  return { themePrefix: (key) => "theme_translations.4." + key,
    get settings() { return window.moduleBroker.lookup("discourse/lib/theme-settings-store").getObjectForTheme(4); } };
});
for (const [name, exports] of Object.entries(window.isbfUnreadCachedTheme)) {
  if (!["profile-preview-review/core/components/user-summary-topic","profile-preview-review/core/templates/user/summary","profile-preview-review/discourse/lib/post-preview","profile-preview-review/discourse/lib/feed-post-loader","profile-preview-review/discourse/components/isbf-post-preview","profile-preview-review/discourse/components/isbf-activity-preview","profile-preview-review/discourse/api-initializers/isbf-campus-feed","profile-preview-review/discourse/components/isbf-summary-topic-title"].includes("profile-preview-review/" + name)) {
    define("profile-preview-review/" + name, [], function () { return exports; });
  }
}

define("profile-preview-review/core/components/user-summary-topic", ["exports", "@ember/component", "@ember/template", "@ember-decorators/component", "discourse/components/plugin-outlet", "discourse/helpers/lazy-hash", "discourse/ui-kit/helpers/d-format-date", "discourse/ui-kit/helpers/d-icon", "discourse/ui-kit/helpers/d-number", "@ember/template-factory", "profile-preview-review/decorators"], function (_exports, _component, _template, _component2, _pluginOutlet, _lazyHash, _dFormatDate, _dIcon, _dNumber, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  /* eslint-disable ember/no-classic-components */

  const UserSummaryTopic = (0, _decorators.c)(class UserSummaryTopic extends _component.default {
    static {
      (0, _component.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <li ...attributes>
        <PluginOutlet
          @name="user-summary-topic-wrapper"
          @outletArgs={{lazyHash
            topic=@topic
            url=@url
            createdAt=@createdAt
            likes=@likes
          }}
        >
          <span class="topic-info">
            {{dFormatDate @createdAt format="tiny" noTitle="true"}}
            {{#if @likes}}
              &middot;
              {{dIcon "heart"}}&nbsp;<span class="like-count">{{dNumber
                  @likes
                }}</span>
            {{/if}}
          </span>
          <br />
          <PluginOutlet
            @name="user-summary-topic-title"
            @outletArgs={{lazyHash topic=@topic url=@url postNumber=@postNumber}}
          >
            <a href={{@url}}>{{trustHTML @topic.fancyTitle}}</a>
          </PluginOutlet>
        </PluginOutlet>
      </li>
      */
      {
        "id": null,
        "block": "[[[11,\"li\"],[17,1],[12],[1,\"\\n  \"],[8,[32,0],null,[[\"@name\",\"@outletArgs\"],[\"user-summary-topic-wrapper\",[28,[32,1],null,[[\"topic\",\"url\",\"createdAt\",\"likes\"],[[30,2],[30,3],[30,4],[30,5]]]]]],[[\"default\"],[[[[1,\"\\n    \"],[10,1],[14,0,\"topic-info\"],[12],[1,\"\\n      \"],[1,[28,[32,2],[[30,4]],[[\"format\",\"noTitle\"],[\"tiny\",\"true\"]]]],[1,\"\\n\"],[41,[30,5],[[[1,\"        ·\\n        \"],[1,[28,[32,3],[\"heart\"],null]],[1,\" \"],[10,1],[14,0,\"like-count\"],[12],[1,[28,[32,4],[[30,5]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n    \"],[10,\"br\"],[12],[13],[1,\"\\n    \"],[8,[32,0],null,[[\"@name\",\"@outletArgs\"],[\"user-summary-topic-title\",[28,[32,1],null,[[\"topic\",\"url\",\"postNumber\"],[[30,2],[30,3],[30,6]]]]]],[[\"default\"],[[[[1,\"\\n      \"],[10,3],[15,6,[30,3]],[12],[1,[28,[32,5],[[30,2,[\"fancyTitle\"]]],null]],[13],[1,\"\\n    \"]],[]]]]],[1,\"\\n  \"]],[]]]]],[1,\"\\n\"],[13]],[\"&attrs\",\"@topic\",\"@url\",\"@createdAt\",\"@likes\",\"@postNumber\"],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          PluginOutlet: _pluginOutlet.default,
          lazyHash: _lazyHash.default,
          dFormatDate: _dFormatDate.default,
          dIcon: _dIcon.default,
          dNumber: _dNumber.default,
          trustHTML: _template.trustHTML
        }),
        "isStrictMode": true
      }), this);
    }
  }, [(0, _component2.tagName)("")]);
  var _default = _exports.default = UserSummaryTopic;
});
define("profile-preview-review/core/templates/user/summary", ["exports", "@ember/routing", "@ember/template", "discourse/components/plugin-outlet", "discourse/components/user-summary-category-search", "discourse/components/user-summary-section", "discourse/components/user-summary-topic", "discourse/components/user-summary-topics-list", "discourse/components/user-summary-user", "discourse/components/user-summary-users-list", "discourse/helpers/body-class", "discourse/helpers/lazy-hash", "discourse/helpers/shorten-url", "discourse/ui-kit/d-badge-card", "discourse/ui-kit/d-user-stat", "discourse/ui-kit/helpers/d-category-link", "discourse-i18n", "@ember/component", "@ember/template-factory", "@ember/component/template-only"], function (_exports, _routing, _template, _pluginOutlet, _userSummaryCategorySearch, _userSummarySection, _userSummaryTopic, _userSummaryTopicsList, _userSummaryUser, _userSummaryUsersList, _bodyClass, _lazyHash, _shortenUrl, _dBadgeCard, _dUserStat, _dCategoryLink, _discourseI18n, _component, _templateFactory, _templateOnly) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  var _default = _exports.default = (0, _component.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
  /*
    {{bodyClass "user-summary-page"}}
  
  <div class="user-content" id="user-content">
    <PluginOutlet
      @name="above-user-summary-stats"
      @outletArgs={{lazyHash model=@controller.model user=@controller.user}}
    />
    {{#if @controller.model.can_see_summary_stats}}
      <div class="top-section stats-section">
        <h3 class="stats-title">{{i18n "user.summary.stats"}}</h3>
        <ul>
          <li class="stats-days-visited">
            <DUserStat
              @label="user.summary.days_visited"
              @value={{@controller.model.days_visited}}
            />
          </li>
          <li class="stats-time-read">
            <DUserStat
              @label="user.summary.time_read"
              @rawTitle={{i18n
                "user.summary.time_read_title"
                duration=@controller.timeReadMedium
              }}
              @type="string"
              @value={{@controller.timeRead}}
            />
          </li>
          {{#if @controller.showRecentTimeRead}}
            <li class="stats-recent-read">
              <DUserStat
                @label="user.summary.recent_time_read"
                @rawTitle={{i18n
                  "user.summary.recent_time_read_title"
                  duration=@controller.recentTimeReadMedium
                }}
                @type="string"
                @value={{@controller.recentTimeRead}}
              />
            </li>
          {{/if}}
          <li class="stats-topics-entered">
            <DUserStat
              @label="user.summary.topics_entered"
              @value={{@controller.model.topics_entered}}
            />
          </li>
          <li class="stats-posts-read">
            <DUserStat
              @label="user.summary.posts_read"
              @value={{@controller.model.posts_read_count}}
            />
          </li>
          {{#if @controller.model.can_see_user_actions}}
            <li class="stats-likes-given linked-stat">
              <LinkTo @route="userActivity.likesGiven">
                <DUserStat
                  @icon="heart"
                  @label="user.summary.likes_given"
                  @value={{@controller.model.likes_given}}
                />
              </LinkTo>
            </li>
          {{else}}
            <li class="stats-likes-given">
              <DUserStat
                @icon="heart"
                @label="user.summary.likes_given"
                @value={{@controller.model.likes_given}}
              />
            </li>
          {{/if}}
          <li class="stats-likes-received">
            <DUserStat
              @icon="heart"
              @label="user.summary.likes_received"
              @value={{@controller.model.likes_received}}
            />
          </li>
          {{#if @controller.model.bookmark_count}}
            {{#if @controller.model.can_see_user_actions}}
              <li class="stats-bookmark-count linked-stat">
                <LinkTo @route="userActivity.bookmarks">
                  <DUserStat
                    @label="user.summary.bookmark_count"
                    @value={{@controller.model.bookmark_count}}
                  />
                </LinkTo>
              </li>
            {{else}}
              <li class="stats-bookmark-count">
                <DUserStat
                  @label="user.summary.bookmark_count"
                  @value={{@controller.model.bookmark_count}}
                />
              </li>
            {{/if}}
          {{/if}}
          {{#if @controller.model.can_see_user_actions}}
            <li class="stats-topic-count linked-stat">
              <LinkTo @route="userActivity.topics">
                <DUserStat
                  @label="user.summary.topic_count"
                  @value={{@controller.model.topic_count}}
                />
              </LinkTo>
            </li>
          {{else}}
            <li class="stats-topic-count">
              <DUserStat
                @label="user.summary.topic_count"
                @value={{@controller.model.topic_count}}
              />
            </li>
          {{/if}}
          {{#if @controller.model.can_see_user_actions}}
            <li class="stats-post-count linked-stat">
              <LinkTo @route="userActivity.replies">
                <DUserStat
                  @label="user.summary.post_count"
                  @value={{@controller.model.post_count}}
                />
              </LinkTo>
            </li>
          {{else}}
            <li class="stats-post-count">
              <DUserStat
                @label="user.summary.post_count"
                @value={{@controller.model.post_count}}
              />
            </li>
          {{/if}}
          <PluginOutlet
            @connectorTagName="li"
            @name="user-summary-stat"
            @outletArgs={{lazyHash
              model=@controller.model
              user=@controller.user
            }}
          />
        </ul>
      </div>
    {{/if}}
  
    <PluginOutlet
      @name="below-user-summary-stats"
      @outletArgs={{lazyHash model=@controller.model user=@controller.user}}
    />
  
    <div class="top-section replies-and-topics-section">
      <UserSummarySection
        class="replies-section pull-left"
        @title="top_replies"
      >
        <UserSummaryTopicsList
          @items={{@controller.model.replies}}
          @type="replies"
          @user={{@controller.user}}
          as |reply|
        >
          <UserSummaryTopic
            @createdAt={{reply.createdAt}}
            @likes={{reply.like_count}}
            @postNumber={{reply.post_number}}
            @topic={{reply.topic}}
            @url={{reply.url}}
          />
        </UserSummaryTopicsList>
      </UserSummarySection>
  
      <UserSummarySection class="topics-section pull-right" @title="top_topics">
        <UserSummaryTopicsList
          @items={{@controller.model.topics}}
          @type="topics"
          @user={{@controller.user}}
          as |topic|
        >
          <UserSummaryTopic
            @createdAt={{topic.created_at}}
            @likes={{topic.like_count}}
            @postNumber={{1}}
            @topic={{topic}}
            @url={{topic.url}}
          />
        </UserSummaryTopicsList>
      </UserSummarySection>
    </div>
  
    <div class="top-section links-and-replied-to-section">
      <UserSummarySection class="links-section pull-left" @title="top_links">
        {{#if @controller.model.links.length}}
          <ul>
            {{#each @controller.model.links as |link|}}
              <li>
                {{! eslint-disable ember/template-link-rel-noopener }}
                <a
                  aria-label={{i18n "topic_map.clicks" count=link.clicks}}
                  class="domain"
                  data-clicks={{link.clicks}}
                  href={{link.url}}
                  rel="noopener {{unless
                    @controller.user.removeNoFollow
                    'nofollow ugc'
                  }}"
                  target="_blank"
                  title={{link.title}}
                >
                  {{shortenUrl link.url}}
                </a>
                {{! eslint-enable ember/template-link-rel-noopener }}
                <br />
  
                <PluginOutlet
                  @name="user-summary-topic-title"
                  @outletArgs={{lazyHash
                    topic=link.topic
                    url=link.post_url
                    postNumber=link.post_number
                  }}
                >
                  <a href={{link.post_url}}>
                    {{trustHTML link.topic.fancyTitle}}
                  </a>
                </PluginOutlet>
              </li>
            {{/each}}
          </ul>
        {{else}}
          <p>{{i18n "user.summary.no_links"}}</p>
        {{/if}}
      </UserSummarySection>
  
      <UserSummarySection
        class="summary-user-list replied-section pull-right"
        @title="most_replied_to_users"
      >
        <UserSummaryUsersList
          @none="no_replies"
          @users={{@controller.model.most_replied_to_users}}
          as |user|
        >
          <UserSummaryUser @countClass="replies" @icon="reply" @user={{user}} />
        </UserSummaryUsersList>
      </UserSummarySection>
    </div>
  
    <div class="top-section most-liked-section">
      <UserSummarySection
        class="summary-user-list liked-by-section pull-left"
        @title="most_liked_by"
      >
        <UserSummaryUsersList
          @none="no_likes"
          @users={{@controller.model.most_liked_by_users}}
          as |user|
        >
          <UserSummaryUser @countClass="likes" @icon="heart" @user={{user}} />
        </UserSummaryUsersList>
      </UserSummarySection>
  
      <UserSummarySection
        class="summary-user-list liked-section pull-right"
        @title="most_liked_users"
      >
        <UserSummaryUsersList
          @none="no_likes"
          @users={{@controller.model.most_liked_users}}
          as |user|
        >
          <UserSummaryUser @countClass="likes" @icon="heart" @user={{user}} />
        </UserSummaryUsersList>
      </UserSummarySection>
    </div>
  
    {{#if @controller.model.top_categories.length}}
      <div class="top-section top-categories-section">
        <UserSummarySection
          class="summary-category-list pull-left"
          @title="top_categories"
        >
          <table>
            <thead>
              <th class="category-link"></th>
              <th class="topic-count">{{i18n "user.summary.topics"}}</th>
              <th class="reply-count">{{i18n "user.summary.replies"}}</th>
            </thead>
            <tbody>
              {{#each @controller.model.top_categories as |category|}}
                <tr>
                  <PluginOutlet
                    @name="user-summary-top-category-row"
                    @outletArgs={{lazyHash
                      category=category
                      user=@controller.user
                    }}
                  >
                    <td class="category-link">
                      {{dCategoryLink
                        category
                        allowUncategorized="true"
                        hideParent=false
                      }}
                    </td>
                    <td class="topic-count">
                      <UserSummaryCategorySearch
                        @category={{category}}
                        @count={{category.topic_count}}
                        @searchOnlyFirstPosts={{true}}
                        @user={{@controller.user}}
                      />
                    </td>
                    <td class="reply-count">
                      <UserSummaryCategorySearch
                        @category={{category}}
                        @count={{category.post_count}}
                        @searchOnlyFirstPosts={{false}}
                        @user={{@controller.user}}
                      />
                    </td>
                  </PluginOutlet>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </UserSummarySection>
      </div>
    {{/if}}
  
    {{#if @controller.siteSettings.enable_badges}}
      <div class="top-section badges-section">
        <h3 class="stats-title">{{i18n "user.summary.top_badges"}}</h3>
  
        {{#if @controller.model.badges}}
          <div class="badge-group-list">
            {{#each @controller.model.badges as |badge|}}
              <DBadgeCard
                @badge={{badge}}
                @count={{badge.count}}
                @username={{@controller.user.username_lower}}
              />
            {{/each}}
            <PluginOutlet
              @name="after-user-summary-badges"
              @outletArgs={{lazyHash
                model=@controller.model
                user=@controller.user
              }}
            />
          </div>
        {{else}}
          <p>{{i18n "user.summary.no_badges"}}</p>
        {{/if}}
  
        {{#if @controller.moreBadges}}
          <LinkTo class="more" @model={{@controller.user}} @route="user.badges">
            {{i18n "user.summary.more_badges"}}
          </LinkTo>
        {{/if}}
      </div>
    {{/if}}
  </div>
  */
  {
    "id": null,
    "block": "[[[1,[28,[32,0],[\"user-summary-page\"],null]],[1,\"\\n\\n\"],[10,0],[14,0,\"user-content\"],[14,1,\"user-content\"],[12],[1,\"\\n  \"],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"above-user-summary-stats\",[28,[32,2],null,[[\"model\",\"user\"],[[30,1,[\"model\"]],[30,1,[\"user\"]]]]]]],null],[1,\"\\n\"],[41,[30,1,[\"model\",\"can_see_summary_stats\"]],[[[1,\"    \"],[10,0],[14,0,\"top-section stats-section\"],[12],[1,\"\\n      \"],[10,\"h3\"],[14,0,\"stats-title\"],[12],[1,[28,[32,3],[\"user.summary.stats\"],null]],[13],[1,\"\\n      \"],[10,\"ul\"],[12],[1,\"\\n        \"],[10,\"li\"],[14,0,\"stats-days-visited\"],[12],[1,\"\\n          \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.days_visited\",[30,1,[\"model\",\"days_visited\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n        \"],[10,\"li\"],[14,0,\"stats-time-read\"],[12],[1,\"\\n          \"],[8,[32,4],null,[[\"@label\",\"@rawTitle\",\"@type\",\"@value\"],[\"user.summary.time_read\",[28,[32,3],[\"user.summary.time_read_title\"],[[\"duration\"],[[30,1,[\"timeReadMedium\"]]]]],\"string\",[30,1,[\"timeRead\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"],[41,[30,1,[\"showRecentTimeRead\"]],[[[1,\"          \"],[10,\"li\"],[14,0,\"stats-recent-read\"],[12],[1,\"\\n            \"],[8,[32,4],null,[[\"@label\",\"@rawTitle\",\"@type\",\"@value\"],[\"user.summary.recent_time_read\",[28,[32,3],[\"user.summary.recent_time_read_title\"],[[\"duration\"],[[30,1,[\"recentTimeReadMedium\"]]]]],\"string\",[30,1,[\"recentTimeRead\"]]]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,\"li\"],[14,0,\"stats-topics-entered\"],[12],[1,\"\\n          \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.topics_entered\",[30,1,[\"model\",\"topics_entered\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n        \"],[10,\"li\"],[14,0,\"stats-posts-read\"],[12],[1,\"\\n          \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.posts_read\",[30,1,[\"model\",\"posts_read_count\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"],[41,[30,1,[\"model\",\"can_see_user_actions\"]],[[[1,\"          \"],[10,\"li\"],[14,0,\"stats-likes-given linked-stat\"],[12],[1,\"\\n            \"],[8,[32,5],null,[[\"@route\"],[\"userActivity.likesGiven\"]],[[\"default\"],[[[[1,\"\\n              \"],[8,[32,4],null,[[\"@icon\",\"@label\",\"@value\"],[\"heart\",\"user.summary.likes_given\",[30,1,[\"model\",\"likes_given\"]]]],null],[1,\"\\n            \"]],[]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,\"li\"],[14,0,\"stats-likes-given\"],[12],[1,\"\\n            \"],[8,[32,4],null,[[\"@icon\",\"@label\",\"@value\"],[\"heart\",\"user.summary.likes_given\",[30,1,[\"model\",\"likes_given\"]]]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]]],[1,\"        \"],[10,\"li\"],[14,0,\"stats-likes-received\"],[12],[1,\"\\n          \"],[8,[32,4],null,[[\"@icon\",\"@label\",\"@value\"],[\"heart\",\"user.summary.likes_received\",[30,1,[\"model\",\"likes_received\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"],[41,[30,1,[\"model\",\"bookmark_count\"]],[[[41,[30,1,[\"model\",\"can_see_user_actions\"]],[[[1,\"            \"],[10,\"li\"],[14,0,\"stats-bookmark-count linked-stat\"],[12],[1,\"\\n              \"],[8,[32,5],null,[[\"@route\"],[\"userActivity.bookmarks\"]],[[\"default\"],[[[[1,\"\\n                \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.bookmark_count\",[30,1,[\"model\",\"bookmark_count\"]]]],null],[1,\"\\n              \"]],[]]]]],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],[[[1,\"            \"],[10,\"li\"],[14,0,\"stats-bookmark-count\"],[12],[1,\"\\n              \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.bookmark_count\",[30,1,[\"model\",\"bookmark_count\"]]]],null],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]]]],[]],null],[41,[30,1,[\"model\",\"can_see_user_actions\"]],[[[1,\"          \"],[10,\"li\"],[14,0,\"stats-topic-count linked-stat\"],[12],[1,\"\\n            \"],[8,[32,5],null,[[\"@route\"],[\"userActivity.topics\"]],[[\"default\"],[[[[1,\"\\n              \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.topic_count\",[30,1,[\"model\",\"topic_count\"]]]],null],[1,\"\\n            \"]],[]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,\"li\"],[14,0,\"stats-topic-count\"],[12],[1,\"\\n            \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.topic_count\",[30,1,[\"model\",\"topic_count\"]]]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]]],[41,[30,1,[\"model\",\"can_see_user_actions\"]],[[[1,\"          \"],[10,\"li\"],[14,0,\"stats-post-count linked-stat\"],[12],[1,\"\\n            \"],[8,[32,5],null,[[\"@route\"],[\"userActivity.replies\"]],[[\"default\"],[[[[1,\"\\n              \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.post_count\",[30,1,[\"model\",\"post_count\"]]]],null],[1,\"\\n            \"]],[]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,\"li\"],[14,0,\"stats-post-count\"],[12],[1,\"\\n            \"],[8,[32,4],null,[[\"@label\",\"@value\"],[\"user.summary.post_count\",[30,1,[\"model\",\"post_count\"]]]],null],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]]],[1,\"        \"],[8,[32,1],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"li\",\"user-summary-stat\",[28,[32,2],null,[[\"model\",\"user\"],[[30,1,[\"model\"]],[30,1,[\"user\"]]]]]]],null],[1,\"\\n      \"],[13],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n  \"],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"below-user-summary-stats\",[28,[32,2],null,[[\"model\",\"user\"],[[30,1,[\"model\"]],[30,1,[\"user\"]]]]]]],null],[1,\"\\n\\n  \"],[10,0],[14,0,\"top-section replies-and-topics-section\"],[12],[1,\"\\n    \"],[8,[32,6],[[24,0,\"replies-section pull-left\"]],[[\"@title\"],[\"top_replies\"]],[[\"default\"],[[[[1,\"\\n      \"],[8,[32,7],null,[[\"@items\",\"@type\",\"@user\"],[[30,1,[\"model\",\"replies\"]],\"replies\",[30,1,[\"user\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[8,[32,8],null,[[\"@createdAt\",\"@likes\",\"@postNumber\",\"@topic\",\"@url\"],[[30,2,[\"createdAt\"]],[30,2,[\"like_count\"]],[30,2,[\"post_number\"]],[30,2,[\"topic\"]],[30,2,[\"url\"]]]],null],[1,\"\\n      \"]],[2]]]]],[1,\"\\n    \"]],[]]]]],[1,\"\\n\\n    \"],[8,[32,6],[[24,0,\"topics-section pull-right\"]],[[\"@title\"],[\"top_topics\"]],[[\"default\"],[[[[1,\"\\n      \"],[8,[32,7],null,[[\"@items\",\"@type\",\"@user\"],[[30,1,[\"model\",\"topics\"]],\"topics\",[30,1,[\"user\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[8,[32,8],null,[[\"@createdAt\",\"@likes\",\"@postNumber\",\"@topic\",\"@url\"],[[30,3,[\"created_at\"]],[30,3,[\"like_count\"]],1,[30,3],[30,3,[\"url\"]]]],null],[1,\"\\n      \"]],[3]]]]],[1,\"\\n    \"]],[]]]]],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,0],[14,0,\"top-section links-and-replied-to-section\"],[12],[1,\"\\n    \"],[8,[32,6],[[24,0,\"links-section pull-left\"]],[[\"@title\"],[\"top_links\"]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"model\",\"links\",\"length\"]],[[[1,\"        \"],[10,\"ul\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,1,[\"model\",\"links\"]]],null]],null],null,[[[1,\"            \"],[10,\"li\"],[12],[1,\"\\n\"],[1,\"              \"],[10,3],[15,\"aria-label\",[28,[32,3],[\"topic_map.clicks\"],[[\"count\"],[[30,4,[\"clicks\"]]]]]],[14,0,\"domain\"],[15,\"data-clicks\",[30,4,[\"clicks\"]]],[15,6,[30,4,[\"url\"]]],[15,\"rel\",[29,[\"noopener \",[52,[51,[30,1,[\"user\",\"removeNoFollow\"]]],\"nofollow ugc\"]]]],[14,\"target\",\"_blank\"],[15,\"title\",[30,4,[\"title\"]]],[12],[1,\"\\n                \"],[1,[28,[32,9],[[30,4,[\"url\"]]],null]],[1,\"\\n              \"],[13],[1,\"\\n\"],[1,\"              \"],[10,\"br\"],[12],[13],[1,\"\\n\\n              \"],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"user-summary-topic-title\",[28,[32,2],null,[[\"topic\",\"url\",\"postNumber\"],[[30,4,[\"topic\"]],[30,4,[\"post_url\"]],[30,4,[\"post_number\"]]]]]]],[[\"default\"],[[[[1,\"\\n                \"],[10,3],[15,6,[30,4,[\"post_url\"]]],[12],[1,\"\\n                  \"],[1,[28,[32,10],[[30,4,[\"topic\",\"fancyTitle\"]]],null]],[1,\"\\n                \"],[13],[1,\"\\n              \"]],[]]]]],[1,\"\\n            \"],[13],[1,\"\\n\"]],[4]],null],[1,\"        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,2],[12],[1,[28,[32,3],[\"user.summary.no_links\"],null]],[13],[1,\"\\n\"]],[]]],[1,\"    \"]],[]]]]],[1,\"\\n\\n    \"],[8,[32,6],[[24,0,\"summary-user-list replied-section pull-right\"]],[[\"@title\"],[\"most_replied_to_users\"]],[[\"default\"],[[[[1,\"\\n      \"],[8,[32,11],null,[[\"@none\",\"@users\"],[\"no_replies\",[30,1,[\"model\",\"most_replied_to_users\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[8,[32,12],null,[[\"@countClass\",\"@icon\",\"@user\"],[\"replies\",\"reply\",[30,5]]],null],[1,\"\\n      \"]],[5]]]]],[1,\"\\n    \"]],[]]]]],[1,\"\\n  \"],[13],[1,\"\\n\\n  \"],[10,0],[14,0,\"top-section most-liked-section\"],[12],[1,\"\\n    \"],[8,[32,6],[[24,0,\"summary-user-list liked-by-section pull-left\"]],[[\"@title\"],[\"most_liked_by\"]],[[\"default\"],[[[[1,\"\\n      \"],[8,[32,11],null,[[\"@none\",\"@users\"],[\"no_likes\",[30,1,[\"model\",\"most_liked_by_users\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[8,[32,12],null,[[\"@countClass\",\"@icon\",\"@user\"],[\"likes\",\"heart\",[30,6]]],null],[1,\"\\n      \"]],[6]]]]],[1,\"\\n    \"]],[]]]]],[1,\"\\n\\n    \"],[8,[32,6],[[24,0,\"summary-user-list liked-section pull-right\"]],[[\"@title\"],[\"most_liked_users\"]],[[\"default\"],[[[[1,\"\\n      \"],[8,[32,11],null,[[\"@none\",\"@users\"],[\"no_likes\",[30,1,[\"model\",\"most_liked_users\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[8,[32,12],null,[[\"@countClass\",\"@icon\",\"@user\"],[\"likes\",\"heart\",[30,7]]],null],[1,\"\\n      \"]],[7]]]]],[1,\"\\n    \"]],[]]]]],[1,\"\\n  \"],[13],[1,\"\\n\\n\"],[41,[30,1,[\"model\",\"top_categories\",\"length\"]],[[[1,\"    \"],[10,0],[14,0,\"top-section top-categories-section\"],[12],[1,\"\\n      \"],[8,[32,6],[[24,0,\"summary-category-list pull-left\"]],[[\"@title\"],[\"top_categories\"]],[[\"default\"],[[[[1,\"\\n        \"],[10,\"table\"],[12],[1,\"\\n          \"],[10,\"thead\"],[12],[1,\"\\n            \"],[10,\"th\"],[14,0,\"category-link\"],[12],[13],[1,\"\\n            \"],[10,\"th\"],[14,0,\"topic-count\"],[12],[1,[28,[32,3],[\"user.summary.topics\"],null]],[13],[1,\"\\n            \"],[10,\"th\"],[14,0,\"reply-count\"],[12],[1,[28,[32,3],[\"user.summary.replies\"],null]],[13],[1,\"\\n          \"],[13],[1,\"\\n          \"],[10,\"tbody\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,1,[\"model\",\"top_categories\"]]],null]],null],null,[[[1,\"              \"],[10,\"tr\"],[12],[1,\"\\n                \"],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"user-summary-top-category-row\",[28,[32,2],null,[[\"category\",\"user\"],[[30,8],[30,1,[\"user\"]]]]]]],[[\"default\"],[[[[1,\"\\n                  \"],[10,\"td\"],[14,0,\"category-link\"],[12],[1,\"\\n                    \"],[1,[28,[32,13],[[30,8]],[[\"allowUncategorized\",\"hideParent\"],[\"true\",false]]]],[1,\"\\n                  \"],[13],[1,\"\\n                  \"],[10,\"td\"],[14,0,\"topic-count\"],[12],[1,\"\\n                    \"],[8,[32,14],null,[[\"@category\",\"@count\",\"@searchOnlyFirstPosts\",\"@user\"],[[30,8],[30,8,[\"topic_count\"]],true,[30,1,[\"user\"]]]],null],[1,\"\\n                  \"],[13],[1,\"\\n                  \"],[10,\"td\"],[14,0,\"reply-count\"],[12],[1,\"\\n                    \"],[8,[32,14],null,[[\"@category\",\"@count\",\"@searchOnlyFirstPosts\",\"@user\"],[[30,8],[30,8,[\"post_count\"]],false,[30,1,[\"user\"]]]],null],[1,\"\\n                  \"],[13],[1,\"\\n                \"]],[]]]]],[1,\"\\n              \"],[13],[1,\"\\n\"]],[8]],null],[1,\"          \"],[13],[1,\"\\n        \"],[13],[1,\"\\n      \"]],[]]]]],[1,\"\\n    \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,1,[\"siteSettings\",\"enable_badges\"]],[[[1,\"    \"],[10,0],[14,0,\"top-section badges-section\"],[12],[1,\"\\n      \"],[10,\"h3\"],[14,0,\"stats-title\"],[12],[1,[28,[32,3],[\"user.summary.top_badges\"],null]],[13],[1,\"\\n\\n\"],[41,[30,1,[\"model\",\"badges\"]],[[[1,\"        \"],[10,0],[14,0,\"badge-group-list\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,1,[\"model\",\"badges\"]]],null]],null],null,[[[1,\"            \"],[8,[32,15],null,[[\"@badge\",\"@count\",\"@username\"],[[30,9],[30,9,[\"count\"]],[30,1,[\"user\",\"username_lower\"]]]],null],[1,\"\\n\"]],[9]],null],[1,\"          \"],[8,[32,1],null,[[\"@name\",\"@outletArgs\"],[\"after-user-summary-badges\",[28,[32,2],null,[[\"model\",\"user\"],[[30,1,[\"model\"]],[30,1,[\"user\"]]]]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,2],[12],[1,[28,[32,3],[\"user.summary.no_badges\"],null]],[13],[1,\"\\n\"]],[]]],[1,\"\\n\"],[41,[30,1,[\"moreBadges\"]],[[[1,\"        \"],[8,[32,5],[[24,0,\"more\"]],[[\"@model\",\"@route\"],[[30,1,[\"user\"]],\"user.badges\"]],[[\"default\"],[[[[1,\"\\n          \"],[1,[28,[32,3],[\"user.summary.more_badges\"],null]],[1,\"\\n        \"]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[13]],[\"@controller\",\"reply\",\"topic\",\"link\",\"user\",\"user\",\"user\",\"category\",\"badge\"],[\"if\",\"each\",\"-track-array\",\"unless\"]]",
    "moduleName": "(unknown template module)",
    "scope": () => ({
      bodyClass: _bodyClass.default,
      PluginOutlet: _pluginOutlet.default,
      lazyHash: _lazyHash.default,
      i18n: _discourseI18n.i18n,
      DUserStat: _dUserStat.default,
      LinkTo: _routing.LinkTo,
      UserSummarySection: _userSummarySection.default,
      UserSummaryTopicsList: _userSummaryTopicsList.default,
      UserSummaryTopic: _userSummaryTopic.default,
      shortenUrl: _shortenUrl.default,
      trustHTML: _template.trustHTML,
      UserSummaryUsersList: _userSummaryUsersList.default,
      UserSummaryUser: _userSummaryUser.default,
      dCategoryLink: _dCategoryLink.default,
      UserSummaryCategorySearch: _userSummaryCategorySearch.default,
      DBadgeCard: _dBadgeCard.default
    }),
    "isStrictMode": true
  }), (0, _templateOnly.default)());
});
define("profile-preview-review/discourse/lib/post-preview", ["exports"], function (_exports) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.hasPostPreviewTarget = hasPostPreviewTarget;
  _exports.isActivityPreview = isActivityPreview;
  _exports.postPreview = postPreview;
  const PUBLIC_ACTION_TYPES = new Set([1, 2, 4, 5, 6, 7, 9, 11, 17]);
  function hasPostPreviewTarget({
    postId,
    topicId,
    postNumber
  }) {
    const positiveInteger = value => Number.isSafeInteger(Number(value)) && Number(value) > 0;
    return positiveInteger(postId) || positiveInteger(topicId) && positiveInteger(postNumber);
  }
  function isActivityPreview(item, path) {
    const pathname = (path ?? "").split(/[?#]/)[0];
    return /^\/u\/[^/]+\/activity(?:\/|$)/.test(pathname) && !/\/(?:drafts|bookmarks|pending|messages|notifications)(?:\/|$)/.test(pathname) && hasPostPreviewTarget({
      postId: item?.post_id,
      topicId: item?.topic_id,
      postNumber: item?.post_number
    }) && PUBLIC_ACTION_TYPES.has(Number(item?.action_type)) && (!item.post_type || Number(item.post_type) === 1) && !item.draft_key;
  }
  function postPreview(html) {
    const document = new DOMParser().parseFromString(html ?? "", "text/html");
    const body = document.body;
    body.querySelectorAll("script, style, iframe, aside.quote, aside.onebox, .lightbox-wrapper .meta").forEach(element => element.remove());
    const images = [];
    const sources = new Set();
    for (const image of body.querySelectorAll("img:not(.emoji)")) {
      if (image.matches(".avatar, .favicon, .ytp-thumbnail-image")) {
        continue;
      }
      const source = image.getAttribute("src");
      if (!source) {
        continue;
      }
      try {
        const url = new URL(source, window.location.href);
        if (["https:", "http:"].includes(url.protocol) && !sources.has(url.href)) {
          images.push({
            src: url.href
          });
          sources.add(url.href);
        }
      } catch {
        continue;
      }
      if (images.length === 3) {
        break;
      }
    }
    body.querySelectorAll("a.lightbox, img:not(.emoji)").forEach(element => {
      element.remove();
    });
    body.querySelectorAll("img.emoji").forEach(image => {
      image.replaceWith(document.createTextNode(image.getAttribute("alt") ?? ""));
    });
    body.querySelectorAll("p, div, br, li, blockquote, h1, h2, h3").forEach(element => {
      element.append(document.createTextNode(" "));
    });
    const text = body.textContent.replace(/\s+/g, " ").trim();
    const characters = Array.from(text);
    return {
      text: characters.length > 300 ? `${characters.slice(0, 300).join("")}…` : text,
      images
    };
  }
});
define("profile-preview-review/discourse/lib/feed-post-loader", ["exports", "discourse/lib/ajax", "./post-preview"], function (_exports, _ajax, _postPreview) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.invalidateCookedPost = invalidateCookedPost;
  _exports.loadCookedPost = loadCookedPost;
  _exports.loadPostPolls = loadPostPolls;
  _exports.loadRepostCount = loadRepostCount;
  const cache = new Map();
  const pendingRequests = new Map();
  const invalidatedPosts = new Set();
  const generations = new Map();
  const postNumbers = new Map();
  const queue = [];
  const pollCache = new Map();
  const pendingPolls = new Map();
  let activeRequests = 0;
  let generation = 0;
  function rememberPostNumber(key, postId) {
    if (!key) {
      return;
    }
    postNumbers.delete(key);
    postNumbers.set(key, postId);
    if (postNumbers.size > 50) {
      postNumbers.delete(postNumbers.keys().next().value);
    }
  }
  function runQueue() {
    while (activeRequests < 4 && queue.length) {
      activeRequests += 1;
      runJob(queue.shift());
    }
  }
  function runJob(job) {
    const isPoll = job.kind === "polls";
    (0, _ajax.ajax)(isPoll ? `/posts/${job.postId}.json` : job.url).then(result => {
      const postId = job.postId || Number(result.id);
      if (!Number.isSafeInteger(postId) || postId <= 0) {
        throw new Error("Post response is missing its ID");
      }
      rememberPostNumber(job.postNumberKey, postId);
      if (invalidatedPosts.has(postId) || (generations.get(postId) || 0) > job.startedGeneration) {
        job.resolve(isPoll ? null : "");
      } else if (isPoll) {
        pollCache.set(job.key, {
          value: result,
          at: Date.now()
        });
        if (pollCache.size > 100) {
          pollCache.delete(pollCache.keys().next().value);
        }
        job.resolve(result);
      } else {
        cache.set(postId, result.cooked);
        if (cache.size > 50) {
          cache.delete(cache.keys().next().value);
        }
        job.resolve(result.cooked);
      }
    }).catch(job.reject).finally(() => {
      if (!isPoll && pendingRequests.get(job.key)?.promise === job.promise) {
        pendingRequests.delete(job.key);
      }
      activeRequests -= 1;
      runQueue();
    });
  }
  function loadCookedPost(postId, {
    topicId,
    postNumber
  } = {}) {
    if (!(0, _postPreview.hasPostPreviewTarget)({
      postId,
      topicId,
      postNumber
    })) {
      return Promise.reject(new Error("Post preview target is missing"));
    }
    const postNumberKey = (0, _postPreview.hasPostPreviewTarget)({
      topicId,
      postNumber
    }) ? `${Number(topicId)}/${Number(postNumber)}` : null;
    postId = Number.isSafeInteger(Number(postId)) && Number(postId) > 0 ? Number(postId) : postNumbers.get(postNumberKey);
    if (postId) {
      rememberPostNumber(postNumberKey, postId);
    }
    if (invalidatedPosts.has(postId)) {
      return Promise.resolve("");
    }
    if (cache.has(postId)) {
      const cooked = cache.get(postId);
      cache.delete(postId);
      cache.set(postId, cooked);
      return Promise.resolve(cooked);
    }
    const key = postId || postNumberKey;
    const targetGeneration = postId ? generations.get(postId) || 0 : generation;
    const pending = pendingRequests.get(key);
    if (pending && pending.targetGeneration === targetGeneration) {
      return pending.promise;
    }
    const job = {
      key,
      postId,
      postNumberKey,
      startedGeneration: generation,
      targetGeneration,
      url: postId ? `/posts/${postId}/cooked` : `/posts/by_number/${postNumberKey}.json`
    };
    job.promise = new Promise((resolve, reject) => {
      Object.assign(job, {
        reject,
        resolve
      });
    });
    pendingRequests.set(key, job);
    queue.push(job);
    runQueue();
    return job.promise;
  }
  function loadPostPolls(postId, userId, {
    refresh = false
  } = {}) {
    const id = Number(postId);
    if (!Number.isSafeInteger(id) || id <= 0 || invalidatedPosts.has(id)) {
      return Promise.resolve(null);
    }
    const key = `${userId || "guest"}:${id}`;
    if (pendingPolls.has(key)) {
      return pendingPolls.get(key);
    }
    const cached = pollCache.get(key);
    if (!refresh && cached && Date.now() - cached.at < 30000) {
      return Promise.resolve(cached.value);
    }
    pollCache.delete(key);
    const promise = new Promise((resolve, reject) => {
      queue.push({
        kind: "polls",
        key,
        postId: id,
        reject,
        resolve,
        startedGeneration: generation
      });
      runQueue();
    }).finally(() => {
      if (pendingPolls.get(key) === promise) {
        pendingPolls.delete(key);
      }
    });
    pendingPolls.set(key, promise);
    return promise;
  }
  function invalidateCookedPost(postId, hidden = true) {
    const id = Number(postId);
    generations.set(id, ++generation);
    if (hidden) {
      invalidatedPosts.add(id);
    } else {
      invalidatedPosts.delete(id);
    }
    cache.delete(id);
    for (const key of pollCache.keys()) {
      if (key.endsWith(`:${id}`)) {
        pollCache.delete(key);
      }
    }
    for (const key of pendingPolls.keys()) {
      if (key.endsWith(`:${id}`)) {
        pendingPolls.delete(key);
      }
    }
  }
  const countCache = new Map();
  const pendingCountIds = new Set();
  const countResolvers = new Map();
  let countTimer;
  async function flushCounts() {
    const ids = [...pendingCountIds].slice(0, 50);
    ids.forEach(id => pendingCountIds.delete(id));
    countTimer = null;
    try {
      const result = await (0, _ajax.ajax)("/isbf/reposts/counts", {
        data: {
          topic_ids: ids
        }
      });
      ids.forEach(id => {
        const count = Number(result.counts?.[id] ?? 0);
        countCache.set(id, count);
        countResolvers.get(id)?.forEach(resolve => resolve(count));
        countResolvers.delete(id);
      });
    } catch {
      ids.forEach(id => {
        countResolvers.get(id)?.forEach(resolve => resolve(null));
        countResolvers.delete(id);
      });
    }
    if (pendingCountIds.size) {
      countTimer = setTimeout(flushCounts, 40);
    }
  }
  function loadRepostCount(topicId) {
    if (countCache.has(topicId)) {
      return Promise.resolve(countCache.get(topicId));
    }
    pendingCountIds.add(topicId);
    return new Promise(resolve => {
      const resolvers = countResolvers.get(topicId) ?? [];
      resolvers.push(resolve);
      countResolvers.set(topicId, resolvers);
      countTimer ??= setTimeout(flushCounts, 40);
    });
  }
});
define("profile-preview-review/discourse/components/isbf-post-preview", ["exports", "@glimmer/component", "@glimmer/tracking", "@ember/helper", "@ember/modifier", "@ember/object", "@ember/render-modifiers/modifiers/did-insert", "@ember/render-modifiers/modifiers/did-update", "@ember/render-modifiers/modifiers/will-destroy", "profile-preview-review/theme", "discourse/ui-kit/helpers/d-concat-class", "discourse/ui-kit/helpers/d-icon", "discourse/ui-kit/helpers/d-replace-emoji", "discourse-i18n", "../lib/feed-post-loader", "../lib/optional-topic-title", "../lib/post-preview", "@ember/component", "@ember/template-factory", "profile-preview-review/decorators"], function (_exports, _component, _tracking, _helper, _modifier, _object, _didInsert, _didUpdate, _willDestroy, _theme, _dConcatClass, _dIcon, _dReplaceEmoji, _discourseI18n, _feedPostLoader, _optionalTopicTitle, _postPreview, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFPostPreview extends _component.default {
    #generation = 0;
    #observer;
    #requested = false;
    static {
      (0, _decorators.g)(this.prototype, "_failedImages", [_tracking.tracked], function () {
        return [];
      });
    }
    #_failedImages = ((0, _decorators.i)(this, "_failedImages"), void 0);
    static {
      (0, _decorators.g)(this.prototype, "_preview", [_tracking.tracked], function () {
        return null;
      });
    }
    #_preview = ((0, _decorators.i)(this, "_preview"), void 0);
    get isRail() {
      return this.args.variant === "rail";
    }
    get isSummary() {
      return this.args.variant === "summary";
    }
    get preview() {
      return this.args.disabled ? {
        text: "",
        images: []
      } : this._preview ?? (0, _postPreview.postPreview)(this.args.excerpt);
    }
    static {
      (0, _decorators.n)(this.prototype, "preview", [_tracking.cached]);
    }
    get images() {
      if (this.args.disabled || this.isRail || this.isSummary) {
        return [];
      }
      return (this._preview?.images ?? []).filter(image => !this._failedImages.includes(image.src)).slice(0, 3);
    }
    get text() {
      return this.isRail && this.title || this.preview.text || (0, _discourseI18n.i18n)((0, _theme.themePrefix)(this.isRail || this.isSummary ? this.preview.images.length ? "isbf_v2.preview_picture" : "isbf_v2.preview_post" : "isbf_v2.preview_open"));
    }
    get title() {
      return (0, _optionalTopicTitle.optionalTopicTitle)(this.args.title);
    }
    observe(element) {
      this.#observer?.disconnect();
      this.#generation += 1;
      this.#requested = false;
      this._preview = null;
      this._failedImages = [];
      if (this.args.disabled || !(0, _postPreview.hasPostPreviewTarget)(this.args) || this.isRail && this.title) {
        return;
      }
      this.#observer = new IntersectionObserver(entries => {
        if (entries.some(entry => entry.isIntersecting)) {
          this.#observer.disconnect();
          this.#loadBody();
        }
      }, {
        rootMargin: "200px",
        threshold: 0
      });
      this.#observer.observe(element);
    }
    static {
      (0, _decorators.n)(this.prototype, "observe", [_object.action]);
    }
    destroyObserver() {
      this.#generation += 1;
      this.#observer?.disconnect();
    }
    static {
      (0, _decorators.n)(this.prototype, "destroyObserver", [_object.action]);
    }
    imageFailed(source) {
      this._failedImages = [...this._failedImages, source];
    }
    static {
      (0, _decorators.n)(this.prototype, "imageFailed", [_object.action]);
    }
    async #loadBody() {
      if (this.#requested) {
        return;
      }
      this.#requested = true;
      const generation = this.#generation;
      try {
        const cooked = await (0, _feedPostLoader.loadCookedPost)(this.args.postId, {
          topicId: this.args.topicId,
          postNumber: this.args.postNumber
        });
        if (!this.isDestroying && generation === this.#generation) {
          this._preview = (0, _postPreview.postPreview)(cooked);
        }
      } catch {
        // The existing excerpt and post link remain usable if the request fails.
      }
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        <a
        class={{dConcatClass
          "isbf-post-preview"
          (if this.isRail "--rail" (if this.isSummary "--summary" "--activity"))
        }}
        href={{@href}}
        ...attributes
        {{didInsert this.observe}}
        {{didUpdate
          this.observe
          @postId
          @topicId
          @postNumber
          @disabled
          @title
          @excerpt
          @variant
        }}
        {{willDestroy this.destroyObserver}}
      >
        <span class="isbf-post-preview__text">{{dReplaceEmoji this.text}}</span>
        {{#if this.images.length}}
          <span class="isbf-post-preview__images">
            {{#each this.images key="src" as |image|}}
              <img
                alt={{i18n (themePrefix "isbf_v2.preview_image")}}
                class="isbf-post-preview__image"
                decoding="async"
                loading="lazy"
                src={{image.src}}
                {{on "error" (fn this.imageFailed image.src)}}
              />
            {{/each}}
          </span>
        {{/if}}
        {{#if this.isRail}}{{dIcon "chevron-right"}}{{/if}}
      </a>
      */
      {
        "id": null,
        "block": "[[[11,3],[16,0,[28,[32,0],[\"isbf-post-preview\",[52,[30,0,[\"isRail\"]],\"--rail\",[52,[30,0,[\"isSummary\"]],\"--summary\",\"--activity\"]]],null]],[16,6,[30,1]],[17,2],[4,[32,1],[[30,0,[\"observe\"]]],null],[4,[32,2],[[30,0,[\"observe\"]],[30,3],[30,4],[30,5],[30,6],[30,7],[30,8],[30,9]],null],[4,[32,3],[[30,0,[\"destroyObserver\"]]],null],[12],[1,\"\\n  \"],[10,1],[14,0,\"isbf-post-preview__text\"],[12],[1,[28,[32,4],[[30,0,[\"text\"]]],null]],[13],[1,\"\\n\"],[41,[30,0,[\"images\",\"length\"]],[[[1,\"    \"],[10,1],[14,0,\"isbf-post-preview__images\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"images\"]]],null]],null],\"src\",[[[1,\"        \"],[11,\"img\"],[16,\"alt\",[28,[32,5],[[28,[32,6],[\"isbf_v2.preview_image\"],null]],null]],[24,0,\"isbf-post-preview__image\"],[24,\"decoding\",\"async\"],[24,\"loading\",\"lazy\"],[16,\"src\",[30,10,[\"src\"]]],[4,[32,7],[\"error\",[28,[32,8],[[30,0,[\"imageFailed\"]],[30,10,[\"src\"]]],null]],null],[12],[13],[1,\"\\n\"]],[10]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[41,[30,0,[\"isRail\"]],[[[1,[28,[32,9],[\"chevron-right\"],null]]],[]],null],[1,\"\\n\"],[13]],[\"@href\",\"&attrs\",\"@postId\",\"@topicId\",\"@postNumber\",\"@disabled\",\"@title\",\"@excerpt\",\"@variant\",\"image\"],[\"if\",\"each\",\"-track-array\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          dConcatClass: _dConcatClass.default,
          didInsert: _didInsert.default,
          didUpdate: _didUpdate.default,
          willDestroy: _willDestroy.default,
          dReplaceEmoji: _dReplaceEmoji.default,
          i18n: _discourseI18n.i18n,
          themePrefix: _theme.themePrefix,
          on: _modifier.on,
          fn: _helper.fn,
          dIcon: _dIcon.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFPostPreview;
});
define("profile-preview-review/discourse/components/isbf-activity-preview", ["exports", "@glimmer/component", "@ember/service", "@ember/template", "discourse/components/expand-post", "discourse/ui-kit/d-decorated-html", "discourse/ui-kit/d-user-link", "discourse/ui-kit/helpers/d-avatar", "discourse/ui-kit/helpers/d-category-link", "discourse/ui-kit/helpers/d-format-date", "discourse/ui-kit/helpers/d-replace-emoji", "../lib/optional-topic-title", "../lib/post-preview", "./isbf-post-preview", "@ember/component", "@ember/template-factory", "profile-preview-review/decorators"], function (_exports, _component, _service, _template, _expandPost, _dDecoratedHtml, _dUserLink, _dAvatar, _dCategoryLink, _dFormatDate, _dReplaceEmoji, _optionalTopicTitle, _postPreview, _isbfPostPreview, _component2, _templateFactory, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFActivityPreview extends _component.default {
    static {
      (0, _decorators.g)(this.prototype, "router", [_service.service]);
    }
    #router = ((0, _decorators.i)(this, "router"), void 0);
    get available() {
      return !this.post.hidden && !this.post.deleted;
    }
    get enabled() {
      return (0, _postPreview.isActivityPreview)(this.post, this.router.currentURL);
    }
    get post() {
      return this.args.outletArgs.item;
    }
    get title() {
      return (0, _optionalTopicTitle.optionalTopicTitle)(this.post.title);
    }
    get user() {
      return {
        id: this.post.user_id,
        name: this.post.name,
        username: this.post.username,
        avatar_template: this.post.avatar_template
      };
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        {{#if this.enabled}}
        <article class="isbf-activity-preview">
          <div class="isbf-activity-preview__header">
            <DUserLink @user={{this.user}}>
              {{dAvatar this.user imageSize="large" ignoreTitle="true"}}
            </DUserLink>
            <div class="isbf-activity-preview__details">
              {{#if this.title}}
                <a
                  class="isbf-activity-preview__title"
                  href={{this.post.postUrl}}
                >{{dReplaceEmoji this.title}}</a>
              {{/if}}
              <div class="isbf-activity-preview__metadata">
                {{#if this.post.category}}
                  <span>{{dCategoryLink
                      this.post.category
                      styleType="square"
                    }}</span>
                {{/if}}
                <span>{{dFormatDate this.post.created_at leaveAgo="true"}}</span>
              </div>
            </div>
            {{#if this.available}}<ExpandPost @item={{this.post}} />{{/if}}
          </div>
          {{#if this.available}}
            {{#if this.post.expandedExcerpt}}
              <div
                class="excerpt isbf-activity-preview__body"
                data-post-id={{this.post.post_id}}
                data-topic-id={{this.post.topic_id}}
                data-user-id={{this.post.user_id}}
              >
                <DDecoratedHtml
                  @className="cooked"
                  @html={{trustHTML this.post.expandedExcerpt}}
                />
              </div>
            {{else}}
              <ISBFPostPreview
                @excerpt={{this.post.excerpt}}
                @href={{this.post.postUrl}}
                @postId={{this.post.post_id}}
                @postNumber={{this.post.post_number}}
                @topicId={{this.post.topic_id}}
                @variant="activity"
              />
            {{/if}}
          {{else}}
            <ISBFPostPreview
              @disabled={{true}}
              @href={{this.post.postUrl}}
              @variant="activity"
            />
          {{/if}}
        </article>
      {{/if}}
      */
      {
        "id": null,
        "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[10,\"article\"],[14,0,\"isbf-activity-preview\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-activity-preview__header\"],[12],[1,\"\\n      \"],[8,[32,0],null,[[\"@user\"],[[30,0,[\"user\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[1,[28,[32,1],[[30,0,[\"user\"]]],[[\"imageSize\",\"ignoreTitle\"],[\"large\",\"true\"]]]],[1,\"\\n      \"]],[]]]]],[1,\"\\n      \"],[10,0],[14,0,\"isbf-activity-preview__details\"],[12],[1,\"\\n\"],[41,[30,0,[\"title\"]],[[[1,\"          \"],[10,3],[14,0,\"isbf-activity-preview__title\"],[15,6,[30,0,[\"post\",\"postUrl\"]]],[12],[1,[28,[32,2],[[30,0,[\"title\"]]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,0],[14,0,\"isbf-activity-preview__metadata\"],[12],[1,\"\\n\"],[41,[30,0,[\"post\",\"category\"]],[[[1,\"            \"],[10,1],[12],[1,[28,[32,3],[[30,0,[\"post\",\"category\"]]],[[\"styleType\"],[\"square\"]]]],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[10,1],[12],[1,[28,[32,4],[[30,0,[\"post\",\"created_at\"]]],[[\"leaveAgo\"],[\"true\"]]]],[13],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n      \"],[41,[30,0,[\"available\"]],[[[8,[32,5],null,[[\"@item\"],[[30,0,[\"post\"]]]],null]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n\"],[41,[30,0,[\"available\"]],[[[41,[30,0,[\"post\",\"expandedExcerpt\"]],[[[1,\"        \"],[10,0],[14,0,\"excerpt isbf-activity-preview__body\"],[15,\"data-post-id\",[30,0,[\"post\",\"post_id\"]]],[15,\"data-topic-id\",[30,0,[\"post\",\"topic_id\"]]],[15,\"data-user-id\",[30,0,[\"post\",\"user_id\"]]],[12],[1,\"\\n          \"],[8,[32,6],null,[[\"@className\",\"@html\"],[\"cooked\",[28,[32,7],[[30,0,[\"post\",\"expandedExcerpt\"]]],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[8,[32,8],null,[[\"@excerpt\",\"@href\",\"@postId\",\"@postNumber\",\"@topicId\",\"@variant\"],[[30,0,[\"post\",\"excerpt\"]],[30,0,[\"post\",\"postUrl\"]],[30,0,[\"post\",\"post_id\"]],[30,0,[\"post\",\"post_number\"]],[30,0,[\"post\",\"topic_id\"]],\"activity\"]],null],[1,\"\\n\"]],[]]]],[]],[[[1,\"      \"],[8,[32,8],null,[[\"@disabled\",\"@href\",\"@variant\"],[true,[30,0,[\"post\",\"postUrl\"]],\"activity\"]],null],[1,\"\\n\"]],[]]],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          DUserLink: _dUserLink.default,
          dAvatar: _dAvatar.default,
          dReplaceEmoji: _dReplaceEmoji.default,
          dCategoryLink: _dCategoryLink.default,
          dFormatDate: _dFormatDate.default,
          ExpandPost: _expandPost.default,
          DDecoratedHtml: _dDecoratedHtml.default,
          trustHTML: _template.trustHTML,
          ISBFPostPreview: _isbfPostPreview.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFActivityPreview;
});
define("profile-preview-review/discourse/api-initializers/isbf-campus-feed", ["exports", "@ember/runloop", "@ember/service", "profile-preview-review/theme", "discourse/lib/api", "discourse/models/composer", "discourse/ui-kit/helpers/d-concat-class", "discourse-i18n", "../components/isbf-activity-preview", "../components/isbf-summary-topic-title", "../components/isbf-v2-composer-cancel", "../components/isbf-v2-composer-options", "../components/isbf-v2-composer-title", "../components/isbf-v2-shell", "../lib/anonymous-post-scope", "../lib/optional-topic-title", "../lib/post-preview", "../lib/quick-post-scope", "profile-preview-review/decorators"], function (_exports, _runloop, _service, _theme, _api, _composer, _dConcatClass, _discourseI18n, _isbfActivityPreview, _isbfSummaryTopicTitle, _isbfV2ComposerCancel, _isbfV2ComposerOptions, _isbfV2ComposerTitle, _isbfV2Shell, _anonymousPostScope, _optionalTopicTitle, _postPreview, _quickPostScope, _decorators) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  function focusComposer() {
    document.querySelector("#reply-control.open.composer-action-create-topic .d-editor-input")?.focus();
  }
  var _default = _exports.default = (0, _api.apiInitializer)(api => {
    api.modifyClass("controller:user", {
      pluginId: "isbf-ui-profile-expanded",
      forceExpand: true
    });
    api.modifyClass("component:post-list/item", Superclass => class ISBFActivityPostListItem extends Superclass {
      static {
        (0, _decorators.g)(this.prototype, "router", [_service.service]);
      }
      #router = ((0, _decorators.i)(this, "router"), void 0);
      get itemClasses() {
        return (0, _dConcatClass.default)(super.itemClasses, this.args.additionalItemClasses === "user-stream-item" && (0, _postPreview.isActivityPreview)(this.args.post, this.router.currentURL) && "isbf-activity-item");
      }
    });
    api.renderInOutlet("user-stream-item-above", _isbfActivityPreview.default);
    api.renderInOutlet("user-summary-topic-title", _isbfSummaryTopicTitle.default);
    _composer.default.serializeOnCreate("isbf_repost_source_topic_id", "isbf_repost_source_topic_id");
    _composer.default.serializeToDraft("isbf_repost_source_topic_id", "isbf_repost_source_topic_id");
    _composer.default.serializeOnCreate("isbf_anonymous", "isbf_anonymous");
    _composer.default.serializeToDraft("isbf_anonymous", "isbf_anonymous");
    api.renderInOutlet("before-main-outlet", _isbfV2Shell.default);
    api.renderInOutlet("before-composer-controls", _isbfV2ComposerCancel.default);
    api.renderInOutlet("before-composer-fields", _isbfV2ComposerOptions.default);
    api.renderInOutlet("composer-fields", _isbfV2ComposerTitle.default);
    api.customizeComposerText({
      titlePlaceholder: model => (0, _quickPostScope.isQuickPost)(model) ? (0, _theme.themePrefix)("isbf_v2.optional_title") : null,
      actionTitle: model => (0, _quickPostScope.isQuickPost)(model) ? (0, _discourseI18n.i18n)((0, _theme.themePrefix)("isbf_v2.quick_post")) : null,
      saveLabel: model => (0, _quickPostScope.isQuickPost)(model) ? (0, _theme.themePrefix)("isbf_v2.compose") : null
    });
    api.onAppEvent("composer:category-changed", model => {
      if (model.isbf_anonymous && !(0, _anonymousPostScope.canPublishAnonymously)(model, api.container.lookup("service:current-user"), api.container.lookup("service:site-settings"))) {
        model.set("isbf_anonymous", false);
      }
    });
    api.onAppEvent("composer:opened", () => {
      const model = api.container.lookup("service:composer").model;
      if ((0, _quickPostScope.isQuickPost)(model)) {
        (0, _optionalTopicTitle.prepareOptionalTopicTitle)(model);
      }
      (0, _runloop.scheduleOnce)("afterRender", focusComposer);
    });
    api.registerValueTransformer("composer-editor-reply-placeholder", ({
      value,
      context
    }) => {
      const model = context?.model?.model;
      return (0, _quickPostScope.isQuickPost)(model) && !model.requiredCategoryMissing ? (0, _theme.themePrefix)("isbf_v2.compose_prompt") : value;
    });
    api.registerValueTransformer("topic-list-class", ({
      value,
      context
    }) => {
      const listContext = context?.listContext;
      if (listContext !== "discovery" && listContext !== "suggested") {
        return value;
      }
      return [...value, "isbf-v2-topic-list", `--${listContext}`];
    });
    api.registerValueTransformer("topic-list-item-mobile-layout", ({
      value,
      context
    }) => context?.listContext === "discovery" ? true : value);
    api.registerValueTransformer("topic-list-item-class", ({
      value,
      context
    }) => {
      if (context?.listContext !== "discovery") {
        return value;
      }
      return value.includes("isbf-v2-topic") ? value : [...value, "isbf-v2-topic"];
    });
    api.registerValueTransformer("topic-list-item-expand-pinned", ({
      value,
      context
    }) => context?.listContext === "discovery" ? true : value);
  });
});
define("profile-preview-review/discourse/components/isbf-summary-topic-title", ["exports", "@glimmer/component", "@ember/template", "../lib/optional-topic-title", "./isbf-post-preview", "@ember/component", "@ember/template-factory"], function (_exports, _component, _template, _optionalTopicTitle, _isbfPostPreview, _component2, _templateFactory) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  class ISBFSummaryTopicTitle extends _component.default {
    get disabled() {
      const topic = this.args.outletArgs.topic;
      return topic.hidden || topic.deleted;
    }
    get titled() {
      return Boolean((0, _optionalTopicTitle.optionalTopicTitle)(this.args.outletArgs.topic.title).trim());
    }
    static {
      (0, _component2.setComponentTemplate)((0, _templateFactory.createTemplateFactory)(
      /*
        {{#if this.titled}}
        <a href={{@outletArgs.url}} ...attributes>{{trustHTML
            @outletArgs.topic.fancyTitle
          }}</a>
      {{else}}
        <ISBFPostPreview
          ...attributes
          @disabled={{this.disabled}}
          @href={{@outletArgs.url}}
          @postNumber={{@outletArgs.postNumber}}
          @title={{@outletArgs.topic.title}}
          @topicId={{@outletArgs.topic.id}}
          @variant="summary"
        />
      {{/if}}
      */
      {
        "id": null,
        "block": "[[[41,[30,0,[\"titled\"]],[[[1,\"  \"],[11,3],[16,6,[30,1,[\"url\"]]],[17,2],[12],[1,[28,[32,0],[[30,1,[\"topic\",\"fancyTitle\"]]],null]],[13],[1,\"\\n\"]],[]],[[[1,\"  \"],[8,[32,1],[[17,2]],[[\"@disabled\",\"@href\",\"@postNumber\",\"@title\",\"@topicId\",\"@variant\"],[[30,0,[\"disabled\"]],[30,1,[\"url\"]],[30,1,[\"postNumber\"]],[30,1,[\"topic\",\"title\"]],[30,1,[\"topic\",\"id\"]],\"summary\"]],null],[1,\"\\n\"]],[]]]],[\"@outletArgs\",\"&attrs\"],[\"if\"]]",
        "moduleName": "(unknown template module)",
        "scope": () => ({
          trustHTML: _template.trustHTML,
          ISBFPostPreview: _isbfPostPreview.default
        }),
        "isStrictMode": true
      }), this);
    }
  }
  _exports.default = ISBFSummaryTopicTitle;
});

const profileLookup = (name) => window.moduleBroker.lookup(name);
const { getComponentTemplate, setComponentTemplate } = profileLookup("@ember/component");
for (const name of ["components/user-summary-topic", "templates/user/summary"]) {
  const candidate = profileLookup("profile-preview-review/core/" + name).default;
  const original = profileLookup("discourse/" + name).default;
  setComponentTemplate(getComponentTemplate(candidate), original);
}
window.isbfUnreadCachedTheme["discourse/api-initializers/isbf-campus-feed"] = profileLookup("profile-preview-review/discourse/api-initializers/isbf-campus-feed");
window.profilePreviewSourceInstalled = true;
