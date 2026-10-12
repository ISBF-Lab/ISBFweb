import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import {
  isOfficialComposer,
  officialConfig,
  officialSelections,
} from "../lib/official-filters";
import ISBFOfficialCalendarComposer from "./isbf-official-calendar-composer";
import ISBFOfficialPicker from "./isbf-official-picker";

export default class ISBFOfficialComposer extends Component {
  @service site;

  get config() {
    return officialConfig(this.site);
  }

  get visible() {
    return isOfficialComposer(this.args.model, this.config);
  }

  get campuses() {
    return officialSelections(
      get(this.args.model, "isbf_official_campuses"),
      this.config.campuses
    );
  }

  get types() {
    return officialSelections(
      get(this.args.model, "isbf_official_types"),
      this.config.types
    );
  }

  @action
  select(field, id, checked) {
    const items =
      field === "isbf_official_campuses"
        ? this.config.campuses
        : this.config.types;
    const selected = officialSelections(this.args.model[field], items);
    this.args.model.set(
      field,
      checked
        ? [...new Set([...selected, id])]
        : selected.filter((value) => value !== id)
    );
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-official-composer">
        <p>{{i18n (themePrefix "isbf_v2.official_selection_hint")}}</p>
        <div class="isbf-official-composer__menus">
          <ISBFOfficialPicker
            @items={{this.config.campuses}}
            @labelKey="isbf_v2.official_campus"
            @multiple={{true}}
            @onSelect={{fn this.select "isbf_official_campuses"}}
            @selectedIds={{this.campuses}}
          />
          <ISBFOfficialPicker
            @items={{this.config.types}}
            @labelKey="isbf_v2.official_type"
            @multiple={{true}}
            @onSelect={{fn this.select "isbf_official_types"}}
            @selectedIds={{this.types}}
          />
        </div>
      </div>
    {{/if}}
    <ISBFOfficialCalendarComposer @model={{@model}} />
  </template>
}
