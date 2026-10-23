import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { isCareersComposer } from "../lib/careers";
import ISBFHomeDisplayOption from "./isbf-home-display-option";

export default class ISBFCareersComposer extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }

  get visible() {
    return isCareersComposer(this.model);
  }

  @action
  changeSalary(event) {
    this.model.set("isbf_careers_salary", event.target.value);
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-careers-composer">
        <label>{{i18n (themePrefix "isbf_v2.careers_salary")}}
          <input
            type="text"
            value={{this.model.isbf_careers_salary}}
            {{on "input" this.changeSalary}}
          />
        </label>
      </div>
    {{/if}}
  </template>
}

export class ISBFCareersHome extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }

  get visible() {
    return isCareersComposer(this.model);
  }

  @action
  changeHome(event) {
    this.model.set("isbf_careers_home", event.target.checked);
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-careers-composer-options">
        <ISBFHomeDisplayOption
          class="isbf-careers-composer__home"
          @checked={{this.model.isbf_careers_home}}
          @label={{i18n (themePrefix "isbf_v2.careers_home")}}
          @onChange={{this.changeHome}}
        />
      </div>
    {{/if}}
  </template>
}
