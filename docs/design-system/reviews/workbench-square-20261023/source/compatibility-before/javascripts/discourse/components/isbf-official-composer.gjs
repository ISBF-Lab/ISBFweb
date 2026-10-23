import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import {
  isOfficialComposer,
  officialComposerItems,
  officialConfig,
  officialSelectionIds,
  officialSelectionLimit,
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
    return officialSelectionIds(get(this.args.model, "isbf_official_campuses"));
  }

  get types() {
    return officialSelectionIds(get(this.args.model, "isbf_official_types"));
  }

  get campusItems() {
    return officialComposerItems(this.config.campuses, this.campuses);
  }

  get typeItems() {
    return officialComposerItems(this.config.types, this.types);
  }

  @action
  select(field, id, checked) {
    const items =
      field === "isbf_official_campuses"
        ? this.config.campuses
        : this.config.types;
    const selected = officialSelectionIds(this.args.model[field]);
    if (
      checked &&
      !items.some((item) => item.id === id && item.enabled !== false)
    ) {
      return;
    }
    const next = checked
      ? [...new Set([...selected, id])]
      : selected.filter((value) => value !== id);
    if (checked && !officialSelectionLimit(next)) {
      return;
    }
    this.args.model.set(field, next);
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-official-composer">
        <div class="isbf-official-composer__menus">
          {{#if this.campusItems.length}}
            <div class="isbf-official-composer__campus">
              <ISBFOfficialPicker
                @allKey="isbf_v2.official_campus_optional"
                @items={{this.campusItems}}
                @labelKey="isbf_v2.official_campus"
                @multiple={{true}}
                @onSelect={{fn this.select "isbf_official_campuses"}}
                @selectedIds={{this.campuses}}
              />
            </div>
          {{/if}}
          <div class="isbf-official-composer__type">
            <ISBFOfficialPicker
              @items={{this.typeItems}}
              @labelKey="isbf_v2.official_type"
              @multiple={{true}}
              @onSelect={{fn this.select "isbf_official_types"}}
              @selectedIds={{this.types}}
            />
          </div>
        </div>
      </div>
    {{/if}}
    <ISBFOfficialCalendarComposer @model={{@model}} />
  </template>
}
