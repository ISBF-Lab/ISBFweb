import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { isMarketplaceComposer } from "../lib/marketplace";

export default class ISBFMarketplaceComposer extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }

  get visible() {
    return isMarketplaceComposer(this.model);
  }

  @action
  changePrice(event) {
    this.model.set("isbf_marketplace_price", event.target.value);
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-marketplace-composer">
        <label>{{i18n (themePrefix "isbf_v2.marketplace_price")}}
          <input
            inputmode="decimal"
            required
            type="text"
            value={{this.model.isbf_marketplace_price}}
            {{on "input" this.changePrice}}
          />
        </label>
      </div>
    {{/if}}
  </template>
}

export class ISBFMarketplaceHome extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }

  get visible() {
    return isMarketplaceComposer(this.model);
  }

  @action
  changeHome(event) {
    this.model.set("isbf_marketplace_home", event.target.checked);
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-marketplace-composer-options">
        <label class="isbf-marketplace-composer__home">
          <input
            checked={{this.model.isbf_marketplace_home}}
            type="checkbox"
            {{on "change" this.changeHome}}
          />
          <span>{{i18n (themePrefix "isbf_v2.marketplace_home")}}</span>
        </label>
      </div>
    {{/if}}
  </template>
}
