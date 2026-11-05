import { fn } from "@ember/helper";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default <template>
  <section class="isbf-mbti-history" data-test-mbti-history-list>
    <h2>{{i18n (themePrefix "isbf_v2.mbti_history")}}</h2>
    <p class="isbf-mbti__muted">{{i18n
        (themePrefix "isbf_v2.mbti_privacy")
      }}</p>
    <ul class="isbf-mbti__history">
      {{#each @entries key="id" as |entry|}}
        <li>
          <DButton
            data-result-id={{entry.id}}
            data-test-mbti-history-item
            @action={{fn @onOpen entry.id}}
            @disabled={{@busy}}
          >
            <strong>{{entry.type}}</strong>
            <span>{{i18n
                (themePrefix "isbf_v2.mbti_version")
                count=entry.variant
              }}</span>
            <time datetime={{entry.created_at}}>{{entry.createdLabel}}</time>
          </DButton>
        </li>
      {{else}}
        {{#unless @error}}{{#unless @busy}}<li
              data-test-mbti-history-empty
            >{{i18n
                (themePrefix "isbf_v2.mbti_empty_history")
              }}</li>{{/unless}}{{/unless}}
      {{/each}}
    </ul>
    {{#if @hasMore}}<DButton
        data-test-mbti-load-more
        @action={{@onLoadMore}}
        @disabled={{@busy}}
        @label={{themePrefix "isbf_v2.mbti_load_more"}}
      />{{/if}}
  </section>
</template>
