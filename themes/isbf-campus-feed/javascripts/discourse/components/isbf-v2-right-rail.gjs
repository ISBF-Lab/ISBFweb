import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { settings, themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ISBFV2RightRail extends Component {
  @tracked topics = [];

  constructor() {
    super(...arguments);
    this.loadTopics();
  }

  async loadTopics() {
    try {
      const response = await ajax("/latest.json");
      this.topics = (response.topic_list?.topics ?? [])
        .slice(0, 4)
        .map((topic) => ({
          id: topic.id,
          title: topic.title,
          href: `/t/${topic.slug}/${topic.id}`,
        }));
    } catch {
      // The navigation links below remain available while the feed is offline.
    }
  }

  <template>
    <aside
      aria-label={{i18n (themePrefix "isbf_v2.rail_label")}}
      class="isbf-v2-rail"
    >
      <form
        action="/search"
        class="isbf-v2-rail__search"
        method="get"
        role="search"
      >
        {{dIcon "magnifying-glass"}}
        <label class="sr-only" for="isbf-v2-search">{{i18n
            (themePrefix "isbf_v2.search")
          }}</label>
        <input
          autocomplete="off"
          id="isbf-v2-search"
          name="q"
          placeholder={{i18n (themePrefix "isbf_v2.search_placeholder")}}
          type="search"
        />
      </form>

      <div class="isbf-v2-rail__content">

        {{#if this.topics.length}}
          <section
            aria-labelledby="isbf-v2-recent-title"
            class="isbf-v2-rail__panel"
          >
            <h2 id="isbf-v2-recent-title">{{i18n
                (themePrefix "isbf_v2.recent")
              }}</h2>
            {{#each this.topics as |topic|}}
              <a class="isbf-v2-rail__topic" href={{topic.href}}><span
                >{{topic.title}}</span>{{dIcon "chevron-right"}}</a>
            {{/each}}
            <a class="isbf-v2-rail__more" href="/latest">{{i18n
                (themePrefix "isbf_v2.view_all")
              }}</a>
          </section>
        {{/if}}

        <section
          aria-labelledby="isbf-v2-links-title"
          class="isbf-v2-rail__panel"
        >
          <h2 id="isbf-v2-links-title">{{i18n
              (themePrefix "isbf_v2.rail_label")
            }}</h2>
          <a href={{settings.official_path}}><span>{{i18n
                (themePrefix "isbf_v2.official")
              }}</span>{{dIcon "chevron-right"}}</a>
          <a href="/categories"><span>{{i18n
                (themePrefix "isbf_v2.categories")
              }}</span>{{dIcon "chevron-right"}}</a>
          <a href="/top"><span>{{i18n
                (themePrefix "isbf_v2.top")
              }}</span>{{dIcon "chevron-right"}}</a>
        </section>
      </div>
    </aside>
  </template>
}
