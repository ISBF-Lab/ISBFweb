import { concat } from "@ember/helper";
import { i18n } from "discourse-i18n";

export default <template>
  <nav aria-label={{i18n "isbf_guides.contents"}} class="isbf-guide-toc">
    <ol class="isbf-guide-toc__list">
      {{#each @entries key="id" as |entry|}}
        <li class="isbf-guide-toc__entry" data-heading-level={{entry.level}}>
          <a
            class="isbf-guide-toc__link"
            href={{concat "#" entry.id}}
          >{{entry.title}}</a>
        </li>
      {{/each}}
    </ol>
  </nav>
</template>
