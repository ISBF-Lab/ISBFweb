import Component from "@glimmer/component";
import { cached } from "@glimmer/tracking";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import { not, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ISBFMbtiQuestion extends Component {
  @cached
  get formData() {
    return { choice: this.args.choice ? String(this.args.choice) : null };
  }

  @action
  selectChoice(value, { set, name }) {
    set(name, value);
    this.args.onChoice(Number(value));
  }

  <template>
    <section
      class="isbf-mbti-question"
      data-question-id={{@question.id}}
      data-test-mbti-question
    >
      <p aria-live="polite" class="isbf-mbti__muted">{{i18n
          (themePrefix "isbf_v2.mbti_progress")
          current=@position
          total=@total
        }}</p>
      <progress
        aria-label={{i18n (themePrefix "isbf_v2.mbti_progress_label")}}
        class="isbf-mbti__progress"
        max={{@total}}
        value={{@position}}
      />
      <Form @data={{this.formData}} @onSubmit={{@onNext}} as |form|>
        <form.Field
          @disabled={{@saving}}
          @name="choice"
          @onSet={{this.selectChoice}}
          @title={{@question.question}}
          @type="radio-group"
          as |field|
        >
          <field.Control as |options|>
            {{#each @question.options as |option index|}}
              <options.Radio
                data-test-mbti-choice={{if index "2" "1"}}
                @value={{if index "2" "1"}}
                as |radio|
              >
                <radio.Title>{{option}}</radio.Title>
              </options.Radio>
            {{/each}}
          </field.Control>
        </form.Field>
        <div class="isbf-mbti-question__actions">
          <DButton
            data-test-mbti-previous
            @action={{@onPrevious}}
            @disabled={{or @first @saving}}
            @label={{themePrefix "isbf_v2.mbti_previous"}}
          />
          {{#if @last}}
            <DButton
              class="btn-primary"
              data-test-mbti-submit
              @disabled={{or (not @choice) @saving}}
              @isLoading={{@saving}}
              @label={{themePrefix "isbf_v2.mbti_submit"}}
              @type="submit"
            />
          {{else}}
            <DButton
              class="btn-primary"
              data-test-mbti-next
              @disabled={{or (not @choice) @saving}}
              @label={{themePrefix "isbf_v2.mbti_next"}}
              @type="submit"
            />
          {{/if}}
        </div>
      </Form>
    </section>
  </template>
}
