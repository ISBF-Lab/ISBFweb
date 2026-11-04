import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import DButton from "discourse/ui-kit/d-button";
import DSelect from "discourse/ui-kit/d-select";
import { i18n } from "discourse-i18n";
import { conditionFor } from "../lib/activity-level-rules";

export default class AcademyActivityCondition extends Component {
  get definition() {
    return this.args.catalog.find(
      (entry) => entry.key === this.args.condition.metric
    );
  }

  get metricOptions() {
    return this.args.catalog
      .filter((entry) => entry.group === this.definition.group)
      .map((entry) => ({
        value: entry.key,
        label: i18n(`academy_roles.activity_levels.metrics.${entry.key}`),
      }));
  }

  get periodOptions() {
    return this.definition.periods.map((value) => ({
      value,
      label: i18n(`academy_roles.activity_levels.periods.${value}`, {
        days: this.args.periodDays,
      }),
    }));
  }

  get valueTitle() {
    return i18n(
      `academy_roles.activity_levels.${this.definition.maximum ? "maximum" : "minimum"}`
    );
  }

  @action
  changeMetric(field, metric) {
    const definition = this.args.catalog.find((entry) => entry.key === metric);
    // Form-level onSet commits immediately; keep metric changes in the draft.
    this.args.form.set(
      field.name.slice(0, -".metric".length),
      conditionFor(definition)
    );
  }

  @action
  remove() {
    this.args.fields.remove(this.args.index);
  }

  <template>
    {{#let @form @fields as |form fields|}}
      <form.Section class="academy-activity-levels__condition">
        <form.Row>
          <fields.Field
            @name="metric"
            @title={{i18n "academy_roles.activity_levels.condition"}}
            @type="custom"
            @validation="required"
            as |field|
          >
            <field.Control>
              <DSelect
                aria-describedby={{field.describedBy}}
                aria-invalid={{if field.error "true"}}
                class="form-kit__control-select"
                disabled={{field.disabled}}
                id={{field.id}}
                name={{field.name}}
                @includeNone={{false}}
                @onChange={{fn this.changeMetric field}}
                @value={{field.value}}
                as |select|
              >
                {{#each this.metricOptions as |option|}}
                  <select.Option
                    @value={{option.value}}
                  >{{option.label}}</select.Option>
                {{/each}}
              </DSelect>
            </field.Control>
          </fields.Field>
          <fields.Field
            @name="period"
            @title={{i18n "academy_roles.activity_levels.period"}}
            @type="select"
            @validation="required"
            as |field|
          >
            <field.Control @includeNone={{false}} as |select|>
              {{#each this.periodOptions as |option|}}
                <select.Option
                  @value={{option.value}}
                >{{option.label}}</select.Option>
              {{/each}}
            </field.Control>
          </fields.Field>
          <fields.Field
            @name="value"
            @title={{this.valueTitle}}
            @type="input-number"
            @validation="required"
            as |field|
          >
            <field.Control min="0" step="1" />
          </fields.Field>
        </form.Row>
        {{#if this.definition.percentage}}
          <fields.Field
            @description={{i18n
              "academy_roles.activity_levels.cap_description"
            }}
            @name="cap"
            @title={{i18n "academy_roles.activity_levels.cap"}}
            @type="input-number"
            @validation="required"
            as |field|
          >
            <field.Control min="0" step="1" />
          </fields.Field>
        {{/if}}
        {{#if this.definition.months}}
          <fields.Field
            @description={{i18n
              "academy_roles.activity_levels.penalty_description"
            }}
            @name="months"
            @title={{i18n "academy_roles.activity_levels.penalty_months"}}
            @type="input-number"
            @validation="required"
            as |field|
          >
            <field.Control max="1200" min="1" step="1" />
          </fields.Field>
        {{/if}}
        <DButton
          class="btn-default"
          @action={{this.remove}}
          @label="academy_roles.activity_levels.remove_condition"
        />
      </form.Section>
    {{/let}}
  </template>
}
