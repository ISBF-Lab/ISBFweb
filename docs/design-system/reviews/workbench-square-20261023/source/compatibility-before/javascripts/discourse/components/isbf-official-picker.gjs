import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";

export default class ISBFOfficialPicker extends Component {
  fallbackPlacements = ["bottom-start", "bottom-end"];

  get label() {
    const selected = this.options.filter((item) => item.selected);
    if (!selected.length) {
      return i18n(themePrefix(this.args.allKey ?? this.args.labelKey));
    }
    if (selected.length === 1) {
      return selected[0].label;
    }
    return i18n(themePrefix("isbf_v2.explore_selected_count"), {
      label: i18n(themePrefix(this.args.labelKey)),
      count: selected.length,
    });
  }

  get options() {
    return this.args.items.map((item) => ({
      ...item,
      label:
        item.enabled === false
          ? i18n(themePrefix("isbf_v2.official_inactive"), {
              label: item.label,
            })
          : item.label,
      selected: this.args.selectedIds.includes(item.id),
    }));
  }

  get allSelected() {
    return !this.args.selectedIds.length;
  }

  @action
  async select(menu, id) {
    this.args.onSelect(id);
    await menu.close();
  }

  @action
  toggle(id, event) {
    this.args.onSelect(id, event.target.checked);
  }

  <template>
    <DMenu
      @ariaLabel={{i18n (themePrefix @labelKey)}}
      @contentClass="isbf-official-picker__menu"
      @fallbackPlacements={{this.fallbackPlacements}}
      @icon="chevron-down"
      @label={{this.label}}
      @placement="bottom-start"
      @triggerClass="btn-flat isbf-official-picker__trigger"
    >
      <:content as |menu|>
        <DDropdownMenu as |dropdown|>
          {{#unless @multiple}}
            <dropdown.item>
              <DButton
                class="btn-flat isbf-official-picker__item"
                @action={{fn this.select menu ""}}
                @ariaPressed={{this.allSelected}}
                @translatedLabel={{i18n (themePrefix @allKey)}}
              />
            </dropdown.item>
          {{/unless}}
          {{#each this.options as |item|}}
            <dropdown.item>
              {{#if @multiple}}
                <label class="isbf-official-picker__item">
                  <input
                    checked={{item.selected}}
                    type="checkbox"
                    {{on "change" (fn this.toggle item.id)}}
                  />
                  <span>{{item.label}}</span>
                </label>
              {{else}}
                <DButton
                  class="btn-flat isbf-official-picker__item"
                  @action={{fn this.select menu item.id}}
                  @ariaPressed={{item.selected}}
                  @translatedLabel={{item.label}}
                />
              {{/if}}
            </dropdown.item>
          {{/each}}
        </DDropdownMenu>
      </:content>
    </DMenu>
  </template>
}
