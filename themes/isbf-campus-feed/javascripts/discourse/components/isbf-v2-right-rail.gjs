import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { loadRecentDiscussions } from "../lib/recent-discussions";
import ISBFPostPreview from "./isbf-post-preview";

export default class ISBFV2RightRail extends Component {
  @service site;

  @tracked topics = [];

  #generation = 0;

  constructor() {
    super(...arguments);
    this.#loadTopics();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#generation += 1;
  }

  async #loadTopics() {
    const generation = ++this.#generation;
    const isStale = () => this.isDestroying || generation !== this.#generation;
    try {
      const topics = await loadRecentDiscussions({ site: this.site, isStale });
      if (!isStale()) {
        this.topics = topics.map((topic) => ({
          id: topic.id,
          title: topic.title,
          postId: topic.first_post_id,
          excerpt: topic.excerpt,
          href: `/t/${topic.slug}/${topic.id}`,
        }));
      }
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
            {{#each this.topics key="id" as |topic|}}
              <ISBFPostPreview
                class="isbf-v2-rail__topic"
                @excerpt={{topic.excerpt}}
                @href={{topic.href}}
                @postId={{topic.postId}}
                @title={{topic.title}}
                @variant="rail"
              />
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
