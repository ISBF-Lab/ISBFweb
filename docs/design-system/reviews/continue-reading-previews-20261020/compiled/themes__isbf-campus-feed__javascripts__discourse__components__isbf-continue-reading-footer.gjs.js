import { themePrefix } from "virtual:theme";
import BrowseMore from "discourse/components/more-topics/browse-more";
import getURL from "discourse/lib/get-url";
import Category from "discourse/models/category";
import { gt } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
export default class ISBFContinueReadingFooter extends BrowseMore {
  get navigation() {
    const data = this.topicBrowseMoreData;
    const {
      category,
      latestUrl,
      newTopics,
      unreadTopics
    } = data;
    return {
      ...data,
      browseLabel: category ? i18n(themePrefix("isbf_v2.continue_reading.browse_category"), {
        category: category.name
      }) : i18n("topic.browse_latest_topics"),
      browseUrl: category ? getURL(`/c/${Category.slugFor(category)}/${category.id}`) : latestUrl,
      hasRemainingTopics: newTopics + unreadTopics > 0
    };
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#let this.navigation as |navigation|}}
      <nav
        aria-label={{i18n (themePrefix "isbf_v2.continue_reading.browse")}}
        class="isbf-continue-reading__footer"
        ...attributes
      >
        {{#if navigation.hasRemainingTopics}}
          <div class="isbf-continue-reading__remaining">
            {{#if (gt navigation.newTopics 0)}}
              <a href={{navigation.newUrl}}>
                {{i18n
                  (themePrefix "isbf_v2.continue_reading.remaining_new")
                  count=navigation.newTopics
                }}
              </a>
            {{/if}}
            {{#if (gt navigation.unreadTopics 0)}}
              <a href={{navigation.unreadUrl}}>
                {{i18n
                  (themePrefix "isbf_v2.continue_reading.remaining_unread")
                  count=navigation.unreadTopics
                }}
              </a>
            {{/if}}
          </div>
        {{/if}}
    
        <div class="isbf-continue-reading__browse">
          {{#unless navigation.hasRemainingTopics}}
            {{#if navigation.category}}
              <a href={{navigation.latestUrl}}>
                {{i18n "topic.browse_latest_topics"}}
              </a>
            {{else}}
              <a href={{navigation.categoriesUrl}}>
                {{i18n (themePrefix "isbf_v2.continue_reading.all_categories")}}
              </a>
            {{/if}}
          {{/unless}}
          <a
            class="isbf-continue-reading__browse-all"
            href={{navigation.browseUrl}}
            title={{navigation.browseLabel}}
          >{{i18n (themePrefix "isbf_v2.continue_reading.browse_all")}}</a>
        </div>
      </nav>
    {{/let}}
    */
    {
      "id": null,
      "block": "[[[44,[[30,0,[\"navigation\"]]],[[[1,\"  \"],[11,\"nav\"],[16,\"aria-label\",[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.browse\"],null]],null]],[24,0,\"isbf-continue-reading__footer\"],[17,2],[12],[1,\"\\n\"],[41,[30,1,[\"hasRemainingTopics\"]],[[[1,\"      \"],[10,0],[14,0,\"isbf-continue-reading__remaining\"],[12],[1,\"\\n\"],[41,[28,[32,2],[[30,1,[\"newTopics\"]],0],null],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"newUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.remaining_new\"],null]],[[\"count\"],[[30,1,[\"newTopics\"]]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[41,[28,[32,2],[[30,1,[\"unreadTopics\"]],0],null],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"unreadUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.remaining_unread\"],null]],[[\"count\"],[[30,1,[\"unreadTopics\"]]]]]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],null],[1,\"      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,0],[14,0,\"isbf-continue-reading__browse\"],[12],[1,\"\\n\"],[41,[51,[30,1,[\"hasRemainingTopics\"]]],[[[41,[30,1,[\"category\"]],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"latestUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[\"topic.browse_latest_topics\"],null]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]],[[[1,\"          \"],[10,3],[15,6,[30,1,[\"categoriesUrl\"]]],[12],[1,\"\\n            \"],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.all_categories\"],null]],null]],[1,\"\\n          \"],[13],[1,\"\\n\"]],[]]]],[]],null],[1,\"      \"],[10,3],[14,0,\"isbf-continue-reading__browse-all\"],[15,6,[30,1,[\"browseUrl\"]]],[15,\"title\",[30,1,[\"browseLabel\"]]],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.continue_reading.browse_all\"],null]],null]],[13],[1,\"\\n    \"],[13],[1,\"\\n  \"],[13],[1,\"\\n\"]],[1]]]],[\"navigation\",\"&attrs\"],[\"let\",\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        i18n,
        themePrefix,
        gt
      }),
      "isStrictMode": true
    }), this);
  }
}