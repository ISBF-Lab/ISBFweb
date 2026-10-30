import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ISBFMbtiResult extends Component {
  get dimensions() {
    return this.args.result.dimensions.map((dimension) => ({
      ...dimension,
      firstLabel: i18n(themePrefix(`isbf_v2.mbti_pole_${dimension.first}`)),
      secondLabel: i18n(themePrefix(`isbf_v2.mbti_pole_${dimension.second}`)),
      explanation: i18n(themePrefix(`isbf_v2.mbti_dimension_${dimension.key}`)),
      label: i18n(themePrefix("isbf_v2.mbti_ratio"), {
        first: i18n(themePrefix(`isbf_v2.mbti_pole_${dimension.first}`)),
        second: i18n(themePrefix(`isbf_v2.mbti_pole_${dimension.second}`)),
        firstPercent: dimension.first_percent,
        secondPercent: dimension.second_percent,
      }),
    }));
  }

  get createdAt() {
    return new Date(this.args.result.created_at).toLocaleString();
  }

  <template>
    <section class="isbf-mbti-result" data-test-mbti-result>
      <div class="isbf-mbti__panel isbf-mbti-result__summary">
        <p>{{i18n (themePrefix "isbf_v2.mbti_result_heading")}}</p>
        <h2 class="isbf-mbti-result__type">{{@result.type}}</h2>
        <p class="isbf-mbti__muted">{{i18n
            (themePrefix "isbf_v2.mbti_result_reference")
          }}</p>
        <p class="isbf-mbti__muted">{{i18n
            (themePrefix "isbf_v2.mbti_result_version")
            count=@result.variant
            version=@result.version
          }}</p>
        <time datetime={{@result.created_at}}>{{this.createdAt}}</time>
      </div>
      <ul class="isbf-mbti-result__dimensions">
        {{#each this.dimensions key="key" as |dimension|}}
          <li class="isbf-mbti__panel">
            <div class="isbf-mbti-result__labels">
              <strong>{{dimension.firstLabel}}
                {{dimension.first_percent}}%</strong>
              <strong>{{dimension.secondLabel}}
                {{dimension.second_percent}}%</strong>
            </div>
            <progress
              aria-label={{dimension.label}}
              class="isbf-mbti__progress"
              max="100"
              value={{dimension.first_percent}}
            />
            <p>{{dimension.explanation}}</p>
            {{#if dimension.tied}}
              <p class="isbf-mbti__muted">{{i18n
                  (themePrefix "isbf_v2.mbti_tied")
                }}</p>
            {{/if}}
          </li>
        {{/each}}
      </ul>
      <p class="isbf-mbti__muted">{{i18n
          (themePrefix "isbf_v2.mbti_tie_rule")
        }}</p>
      <div class="isbf-mbti__actions">
        <DButton
          class="btn-primary"
          @action={{@onRetest}}
          @label={{themePrefix "isbf_v2.mbti_retest"}}
        />
        <DButton
          class="btn-danger"
          data-test-mbti-result-delete
          @action={{@onDelete}}
          @disabled={{@busy}}
          @isLoading={{@busy}}
          @label={{themePrefix "isbf_v2.mbti_delete_result"}}
        />
      </div>
    </section>
  </template>
}
