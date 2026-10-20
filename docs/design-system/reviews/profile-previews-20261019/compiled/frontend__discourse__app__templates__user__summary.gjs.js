import { LinkTo } from "@ember/routing";
import { trustHTML } from "@ember/template";
import PluginOutlet from "discourse/components/plugin-outlet";
import UserSummaryCategorySearch from "discourse/components/user-summary-category-search";
import UserSummarySection from "discourse/components/user-summary-section";
import UserSummaryTopic from "discourse/components/user-summary-topic";
import UserSummaryTopicsList from "discourse/components/user-summary-topics-list";
import UserSummaryUser from "discourse/components/user-summary-user";
import UserSummaryUsersList from "discourse/components/user-summary-users-list";
import bodyClass from "discourse/helpers/body-class";
import lazyHash from "discourse/helpers/lazy-hash";
import shortenUrl from "discourse/helpers/shorten-url";
import DBadgeCard from "discourse/ui-kit/d-badge-card";
import DUserStat from "discourse/ui-kit/d-user-stat";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import { i18n } from "discourse-i18n";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
export default setComponentTemplate(createTemplateFactory(
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
    bodyClass,
    PluginOutlet,
    lazyHash,
    i18n,
    DUserStat,
    LinkTo,
    UserSummarySection,
    UserSummaryTopicsList,
    UserSummaryTopic,
    shortenUrl,
    trustHTML,
    UserSummaryUsersList,
    UserSummaryUser,
    dCategoryLink,
    UserSummaryCategorySearch,
    DBadgeCard
  }),
  "isStrictMode": true
}), templateOnly());