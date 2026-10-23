import Component from "@glimmer/component";
import { on } from "@ember/modifier";

export default class ISBFHomeDisplayOption extends Component {
  get checked() {
    return this.args.checked === true;
  }

  <template>
    <label class="isbf-home-display-option" ...attributes>
      <input
        checked={{this.checked}}
        type="checkbox"
        {{on "change" @onChange}}
      />
      <span>{{@label}}</span>
    </label>
  </template>
}
