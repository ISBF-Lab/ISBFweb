import { trustHTML } from "@ember/template";
import { eq } from "discourse/truth-helpers";
import DSelect from "discourse/ui-kit/d-select";
import dIcon from "discourse/ui-kit/helpers/d-icon";

const Dropdown = <template>
  <div class="control-group form-template-field" data-field-type="dropdown">
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
      class="form-template-field__dropdown"
      id={{@id}}
      name={{@id}}
      required={{if @validations.required "required" ""}}
      @includeNone={{false}}
      @onInput={{@onChange}}
    >
      {{#if @attributes.none_label}}
        <option
          class="form-template-field__dropdown-placeholder"
          disabled
          hidden
          selected
          value
        >{{@attributes.none_label}}</option>
      {{/if}}
      {{#each @choices as |choice|}}
        <option
          selected={{eq @value choice}}
          value={{choice}}
        >{{choice}}</option>
      {{/each}}
    </DSelect>
  </div>
</template>;

export default Dropdown;
