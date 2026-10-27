import Component from "@glimmer/component";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
import DSelect from "discourse/ui-kit/d-select";
import dIcon from "discourse/ui-kit/helpers/d-icon";

export default class FormTemplateFieldMultiSelect extends Component {
  @action
  isSelected(option) {
    return this.args.value?.includes(option);
  }

  <template>
    <div
      class="control-group form-template-field"
      data-field-type="multi-select"
    >
      {{#if @attributes.label}}
        <label class="form-template-field__label" for={{@id}}>
          {{@attributes.label}}
          {{#if @validations.required}}
            {{dIcon "asterisk" class="form-template-field__required-indicator"}}
          {{/if}}
        </label>
      {{/if}}

      {{#if @attributes.description}}
        <span class="form-template-field__description">
          {{trustHTML @attributes.description}}
        </span>
      {{/if}}

      <DSelect
        aria-label={{@attributes.label}}
        class="form-template-field__multi-select"
        id={{@id}}
        name={{@id}}
        required={{if @validations.required "required" ""}}
        @includeNone={{false}}
        @multiple={{true}}
        @onInput={{@onChange}}
      >
        {{#if @attributes.none_label}}
          <option
            class="form-template-field__multi-select-placeholder"
            disabled
            hidden
            value=""
          >{{@attributes.none_label}}</option>
        {{/if}}
        {{#each @choices as |choice|}}
          <option
            selected={{this.isSelected choice}}
            value={{choice}}
          >{{choice}}</option>
        {{/each}}
      </DSelect>
    </div>
  </template>
}
