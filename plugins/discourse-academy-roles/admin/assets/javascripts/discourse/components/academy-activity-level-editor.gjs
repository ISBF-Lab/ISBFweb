import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { conditionFor } from "../lib/activity-level-rules";
import AcademyActivityCondition from "./academy-activity-condition";

export default class AcademyActivityLevelEditor extends Component {
  get heading() {
    return i18n("academy_roles.activity_levels.level_heading", {
      level: this.args.index,
    });
  }

  get badges() {
    const options = this.args.badges || [];
    const selected = this.args.level.badge_id;
    return selected && !options.some((badge) => badge.id === Number(selected))
      ? [
          {
            id: selected,
            name: i18n("academy_roles.activity_cosmetics.unavailable_badge", {
              id: selected,
            }),
          },
          ...options,
        ]
      : options;
  }

  @action
  addCondition(group) {
    const definition = this.args.catalog.find((entry) => entry.group === group);
    this.args.form.addItemToCollection(
      `levels.${this.args.index}.${group}_conditions`,
      conditionFor(definition)
    );
  }

  <template>
    {{#let @form @fields as |form fields|}}
      <AdminConfigAreaCard
        class="academy-activity-levels__level"
        data-level-id={{@level.id}}
        @translatedHeading={{this.heading}}
      >
        <:headerAction>
          {{#if @index}}
            <DButton
              class="btn-danger"
              @action={{@onDelete}}
              @disabled={{@busy}}
              @label="academy_roles.activity_levels.delete_level"
            />
          {{/if}}
        </:headerAction>
        <:content>
          <fields.Field
            @description={{i18n
              "academy_roles.activity_levels.name_description"
            }}
            @name="name"
            @title={{i18n "academy_roles.activity_levels.name"}}
            @type="input"
            as |field|
          >
            <field.Control maxlength="80" />
          </fields.Field>
          <fields.Field
            @description={{i18n
              "academy_roles.activity_cosmetics.badge_description"
            }}
            @name="badge_id"
            @title={{i18n "academy_roles.activity_cosmetics.badge"}}
            @type="select"
            as |field|
          >
            <field.Control
              @includeNone={{true}}
              @nonePlaceholder={{i18n
                "academy_roles.activity_cosmetics.no_badge"
              }}
              as |select|
            >
              {{#each this.badges as |badge|}}
                <select.Option
                  @value={{badge.id}}
                >{{badge.name}}</select.Option>
              {{/each}}
            </field.Control>
          </fields.Field>
          {{#if @index}}
            <fields.Field
              @description={{i18n
                "academy_roles.activity_levels.window_description"
              }}
              @name="period_days"
              @title={{i18n "academy_roles.activity_levels.period_days"}}
              @type="input-number"
              @validation="required"
              as |field|
            >
              <field.Control max="36500" min="1" step="1" />
            </fields.Field>
            <p>{{i18n
                "academy_roles.activity_levels.conditions_description"
              }}</p>
            <fields.Collection
              @name="basic_conditions"
              as |conditionFields conditionIndex condition|
            >
              <AcademyActivityCondition
                @catalog={{@catalog}}
                @condition={{condition}}
                @fields={{conditionFields}}
                @form={{form}}
                @index={{conditionIndex}}
                @periodDays={{@level.period_days}}
              />
            </fields.Collection>
            <DButton
              class="btn-default"
              @action={{fn this.addCondition "basic"}}
              @label="academy_roles.activity_levels.add_condition"
            />
            <AdminConfigAreaCard
              @collapsable={{true}}
              @collapsed={{true}}
              @heading="academy_roles.activity_levels.advanced"
            >
              <:content>
                <fields.Collection
                  @name="advanced_conditions"
                  as |conditionFields conditionIndex condition|
                >
                  <AcademyActivityCondition
                    @catalog={{@catalog}}
                    @condition={{condition}}
                    @fields={{conditionFields}}
                    @form={{form}}
                    @index={{conditionIndex}}
                    @periodDays={{@level.period_days}}
                  />
                </fields.Collection>
                <DButton
                  class="btn-default"
                  @action={{fn this.addCondition "advanced"}}
                  @label="academy_roles.activity_levels.add_advanced_condition"
                />
                <fields.Field
                  @description={{i18n
                    "academy_roles.activity_levels.continuous_description"
                  }}
                  @name="continuous_days"
                  @title={{i18n
                    "academy_roles.activity_levels.continuous_days"
                  }}
                  @type="input-number"
                  @validation="required"
                  as |field|
                >
                  <field.Control max="36500" min="0" step="1" />
                </fields.Field>
                {{#if @level.continuous_days}}
                  <fields.Field
                    @description={{i18n
                      "academy_roles.activity_levels.gap_description"
                    }}
                    @name="max_check_gap_hours"
                    @title={{i18n
                      "academy_roles.activity_levels.max_check_gap_hours"
                    }}
                    @type="input-number"
                    @validation="required"
                    as |field|
                  >
                    <field.Control min="1" step="1" />
                  </fields.Field>
                {{/if}}
                <fields.Field
                  @description={{i18n
                    "academy_roles.activity_levels.buffer_description"
                  }}
                  @name="demotion_buffer_percent"
                  @title={{i18n
                    "academy_roles.activity_levels.demotion_buffer_percent"
                  }}
                  @type="input-number"
                  @validation="required"
                  as |field|
                >
                  <field.Control max="100" min="0" step="1" />
                </fields.Field>
              </:content>
            </AdminConfigAreaCard>
          {{else}}
            <p>{{i18n "academy_roles.activity_levels.base_description"}}</p>
          {{/if}}
        </:content>
      </AdminConfigAreaCard>
    {{/let}}
  </template>
}
