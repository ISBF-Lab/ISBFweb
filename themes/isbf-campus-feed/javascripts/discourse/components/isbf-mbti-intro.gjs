import { fn } from "@ember/helper";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default <template>
  <section data-test-mbti-intro>
    <div class="isbf-mbti__panel">
      <h2>{{i18n (themePrefix "isbf_v2.mbti_intro_heading")}}</h2>
      <p>{{i18n (themePrefix "isbf_v2.mbti_intro")}}</p>
      <p class="isbf-mbti__muted">{{i18n
          (themePrefix "isbf_v2.mbti_disclaimer")
        }}</p>
      <div
        aria-label={{i18n (themePrefix "isbf_v2.mbti_choose_version")}}
        class="isbf-mbti__versions"
      >
        {{#each @versions key="variant" as |version|}}
          <DButton
            aria-pressed={{if version.selected "true" "false"}}
            class={{if version.selected "btn-primary"}}
            data-test-mbti-version={{version.variant}}
            @action={{fn @onSelectVariant version.variant}}
            @disabled={{@busy}}
          >
            <span>{{version.label}}</span>
            {{#if version.recommended}}<small>{{i18n
                  (themePrefix "isbf_v2.mbti_recommended")
                }}</small>{{/if}}
          </DButton>
        {{/each}}
      </div>
      {{#if @loggedIn}}
        <div class="isbf-mbti__actions">
          {{#if @hasDraft}}
            <DButton
              class="btn-primary"
              data-test-mbti-resume
              @action={{@onResume}}
              @disabled={{@busy}}
              @label={{themePrefix "isbf_v2.mbti_resume"}}
            />
          {{/if}}
          {{#if @ready}}
            <DButton
              class={{unless @hasDraft "btn-primary"}}
              data-test-mbti-start
              @action={{@onStart}}
              @disabled={{@busy}}
              @label={{themePrefix
                (if @hasDraft "isbf_v2.mbti_restart" "isbf_v2.mbti_start")
              }}
            />
          {{/if}}
        </div>
        <p class="isbf-mbti__muted">{{i18n
            (themePrefix "isbf_v2.mbti_privacy")
          }}</p>
      {{else}}
        <DButton
          class="btn-primary"
          data-test-mbti-login
          @action={{@onLogin}}
          @label={{themePrefix "isbf_v2.mbti_login"}}
        />
      {{/if}}
      {{#if @staleDraft}}<p role="status">{{i18n
            (themePrefix "isbf_v2.mbti_stale_draft")
          }}</p>{{/if}}
    </div>
    <p class="isbf-mbti__source">{{i18n (themePrefix "isbf_v2.mbti_source")}}
      <a
        href="https://github.com/luhuadong/mbti-test/tree/daaf70bfa171fb5487b59cf9f03455dfa2dd9f22"
        rel="noopener noreferrer"
        target="_blank"
      >luhuadong/mbti-test</a></p>
  </section>
</template>
