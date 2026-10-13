import { i18n } from "discourse-i18n";
import ResumePhoto from "./resume-photo";

export default <template>
  <div class="isbf-resume-fields isbf-resume__fields">
    {{#each @fields key="id" as |definition|}}
      <@scope.Field
        class={{if
          definition.wide
          "isbf-resume__field --full-row"
          "isbf-resume__field"
        }}
        @format="full"
        @helpText={{i18n definition.helpKey}}
        @name={{definition.id}}
        @title={{i18n definition.labelKey}}
        @type={{definition.type}}
        @validation={{if definition.required "required:trim"}}
        as |field|
      >
        {{#if definition.photo}}
          <field.Control>
            <ResumePhoto
              @describedBy={{field.describedBy}}
              @disabled={{@disabled}}
              @id={{field.id}}
              @invalid={{field.error}}
              @onBusy={{@onPhotoBusy}}
              @onChange={{field.set}}
              @value={{field.value}}
            />
          </field.Control>
        {{else}}
          <field.Control
            disabled={{@disabled}}
            maxlength={{definition.maxLength}}
            placeholder={{i18n definition.placeholderKey}}
          />
        {{/if}}
      </@scope.Field>
    {{/each}}
  </div>
</template>
