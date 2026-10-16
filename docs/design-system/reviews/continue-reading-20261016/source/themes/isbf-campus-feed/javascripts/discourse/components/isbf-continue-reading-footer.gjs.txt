import { themePrefix } from "virtual:theme";
import BrowseMore from "discourse/components/more-topics/browse-more";
import getURL from "discourse/lib/get-url";
import Category from "discourse/models/category";
import { gt } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class ISBFContinueReadingFooter extends BrowseMore {
  get navigation() {
    const data = this.topicBrowseMoreData;
    const { category, latestUrl, newTopics, unreadTopics } = data;
    return {
      ...data,
      browseLabel: category
        ? i18n(themePrefix("isbf_v2.continue_reading.browse_category"), {
            category: category.name,
          })
        : i18n("topic.browse_latest_topics"),
      browseUrl: category
        ? getURL(`/c/${Category.slugFor(category)}/${category.id}`)
        : latestUrl,
      hasRemainingTopics: newTopics + unreadTopics > 0,
    };
  }

  <template>
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
  </template>
}
