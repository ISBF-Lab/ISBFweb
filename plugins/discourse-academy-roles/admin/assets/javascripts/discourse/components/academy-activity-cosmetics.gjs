import Component from "@glimmer/component";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import { i18n } from "discourse-i18n";

export default class AcademyActivityCosmetics extends Component {
  get levelOptions() {
    return this.args.levels.flatMap((level, number) =>
      level.id
        ? [
            {
              value: level.id,
              label: level.name
                ? i18n("academy_roles.activity_value_named", {
                    level: number,
                    name: level.name,
                  })
                : `LV${number}`,
            },
          ]
        : []
    );
  }

  <template>
    {{#let @fields as |fields|}}
      <AdminConfigAreaCard @heading="academy_roles.activity_cosmetics.title">
        <:content>
          <p>{{i18n "academy_roles.activity_cosmetics.description"}}</p>
          <fields.Field
            @name="avatar_minimum_level_id"
            @title={{i18n "academy_roles.activity_cosmetics.avatar_minimum"}}
            @type="select"
            @validation="required"
            as |field|
          >
            <field.Control @includeNone={{false}} as |select|>
              {{#each this.levelOptions as |option|}}
                <select.Option
                  @value={{option.value}}
                >{{option.label}}</select.Option>
              {{/each}}
            </field.Control>
          </fields.Field>
          <fields.Field
            @name="name_color_enabled"
            @title={{i18n "academy_roles.activity_cosmetics.enable_name_color"}}
            @type="toggle"
            as |field|
          ><field.Control /></fields.Field>
          <fields.Field
            @name="name_color_minimum_level_id"
            @title={{i18n "academy_roles.activity_cosmetics.name_minimum"}}
            @type="select"
            @validation="required"
            as |field|
          >
            <field.Control @includeNone={{false}} as |select|>
              {{#each this.levelOptions as |option|}}
                <select.Option
                  @value={{option.value}}
                >{{option.label}}</select.Option>
              {{/each}}
            </field.Control>
          </fields.Field>
          <fields.Field
            @name="name_color_light"
            @title={{i18n "academy_roles.activity_cosmetics.light_color"}}
            @type="color"
            @validation={{if @values.name_color_enabled "required"}}
            as |field|
          ><field.Control @prefixHex={{true}} /></fields.Field>
          <fields.Field
            @description={{i18n
              "academy_roles.activity_cosmetics.palette_description"
            }}
            @name="name_color_dark"
            @title={{i18n "academy_roles.activity_cosmetics.dark_color"}}
            @type="color"
            @validation={{if @values.name_color_enabled "required"}}
            as |field|
          ><field.Control @prefixHex={{true}} /></fields.Field>
          <p>{{i18n "academy_roles.activity_cosmetics.save_levels_first"}}</p>
        </:content>
      </AdminConfigAreaCard>
    {{/let}}
  </template>
}
