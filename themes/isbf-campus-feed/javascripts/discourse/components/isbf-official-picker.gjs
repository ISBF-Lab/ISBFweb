import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dRovingFocus from "discourse/ui-kit/modifiers/d-roving-focus";
import { i18n } from "discourse-i18n";

export default class ISBFOfficialPicker extends Component {
  fallbackPlacements = ["top-start", "bottom-end", "top-end"];
  #menu;
  #entered = false;

  get menuItems() {
    return this.args.multiple
      ? this.options
      : [
          {
            id: "",
            label: i18n(themePrefix(this.args.allKey)),
            selected: this.allSelected,
          },
          ...this.options,
        ];
  }

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
      selected: this.args.selectedIds.includes(item.id),
    }));
  }

  get allSelected() {
    return !this.args.selectedIds.length;
  }

  @action
  enter() {
    if (this.#entered) {
      return;
    }
    this.#entered = true;
    const row =
      this.#menu?.content?.querySelector('[aria-checked="true"]') ||
      this.#menu?.content?.querySelector(
        "button[role], input[type='checkbox']"
      );
    row?.focus({ preventScroll: true });
    row?.scrollIntoView({ block: "nearest" });
  }

  @action
  closed() {
    this.#entered = false;
  }

  @action
  openFromKey(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      this.#menu?.show();
    }
  }

  @action
  registerMenu(menu) {
    this.#menu = menu;
  }

  @action
  async select(menu, id) {
    this.args.onSelect(id);
    await menu.close();
  }

  @action
  toggle(id, selected) {
    this.args.onSelect(id, !selected);
  }

  <template>
    <DMenu
      aria-haspopup="menu"
      @ariaLabel={{this.label}}
      @contentClass="isbf-official-picker__menu"
      @contentRole="presentation"
      @fallbackPlacements={{this.fallbackPlacements}}
      @icon="chevron-down"
      @inlineTabOrder={{true}}
      @label={{this.label}}
      @onClose={{this.closed}}
      @onKeydown={{this.openFromKey}}
      @onPositioned={{this.enter}}
      @onRegisterApi={{this.registerMenu}}
      @placement="bottom-start"
      @triggerClass="btn-flat isbf-official-picker__trigger"
    >
      <:content as |menu|>
        <DDropdownMenu
          aria-label={{i18n (themePrefix @labelKey)}}
          role="menu"
          @manageFocus={{false}}
          {{dRovingFocus
            itemSelector="button[role]"
            itemsKey=this.menuItems
            orientation="vertical"
            typeAhead=true
          }}
          as |dropdown|
        >
          {{#each this.menuItems key="id" as |item|}}
            <dropdown.item role="presentation">
              {{#if @multiple}}
                <DButton
                  aria-checked={{if item.selected "true" "false"}}
                  class="isbf-official-picker__item"
                  role="menuitemcheckbox"
                  @action={{fn this.toggle item.id item.selected}}
                  @translatedLabel={{item.label}}
                />
              {{else}}
                <DButton
                  aria-checked={{if item.selected "true" "false"}}
                  class="isbf-official-picker__item"
                  role="menuitemradio"
                  @action={{fn this.select menu item.id}}
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
