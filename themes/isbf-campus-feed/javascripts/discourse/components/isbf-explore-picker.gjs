import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import dMenuHighlight from "discourse/ui-kit/modifiers/d-menu-highlight";
import { i18n } from "discourse-i18n";

export default class ISBFExplorePicker extends Component {
  @tracked search = "";
  #menu;

  get label() {
    const label = i18n(themePrefix(this.args.labelKey));
    return this.args.selectedIds.length
      ? i18n(themePrefix("isbf_v2.explore_selected_count"), {
          count: this.args.selectedIds.length,
          label,
        })
      : label;
  }

  get options() {
    const selected = new Set(this.args.selectedIds);
    const query = this.search.trim().toLocaleLowerCase();
    return this.args.items
      .filter((item) =>
        this.args.onSearch
          ? true
          : item.label.toLocaleLowerCase().includes(query)
      )
      .map((item) => ({ ...item, selected: selected.has(item.id) }));
  }

  @action
  clear() {
    this.args.onClear();
  }

  @action
  createCategory() {
    this.#menu?.close();
    this.args.onCreateCategory?.();
  }

  @action
  focusSearch() {
    this.#menu?.content?.querySelector("input[type='search']")?.focus();
  }

  @action
  opened() {
    this.args.onSearch?.(this.search);
    scheduleOnce("afterRender", this, this.focusSearch);
  }

  @action
  registerMenu(menu) {
    this.#menu = menu;
  }

  @action
  retrySearch() {
    this.args.onSearch?.(this.search);
  }

  @action
  toggleOption(item) {
    this.args.onToggle(item);
  }

  @action
  updateSearch(event) {
    this.search = event.target.value;
    this.args.onSearch?.(this.search);
  }

  <template>
    <DMenu
      @ariaLabel={{this.label}}
      @contentClass="isbf-explore-picker__menu"
      @disabled={{@disabled}}
      @icon="chevron-down"
      @inlineTabOrder={{true}}
      @label={{this.label}}
      @onRegisterApi={{this.registerMenu}}
      @onShow={{this.opened}}
      @placement="bottom-start"
      @triggerClass="isbf-explore-picker__trigger"
    >
      <:content>
        <div class="isbf-explore-picker__content">
          <input
            aria-label={{i18n (themePrefix @searchKey)}}
            class="isbf-explore-picker__search"
            placeholder={{i18n (themePrefix @searchKey)}}
            type="search"
            value={{this.search}}
            {{on "input" this.updateSearch}}
          />
          {{#if @loading}}<p role="status">{{i18n
                (themePrefix "isbf_v2.explore_loading")
              }}</p>{{/if}}
          {{#if @error}}
            <div class="isbf-explore-picker__error" role="alert">
              <span>{{i18n (themePrefix "isbf_v2.explore_search_error")}}</span>
              <button type="button" {{on "click" this.retrySearch}}>{{i18n
                  (themePrefix "isbf_v2.explore_retry")
                }}</button>
            </div>
          {{/if}}
          <div
            class="isbf-explore-picker__options"
            {{dMenuHighlight itemSelector="label"}}
          >
            {{#each this.options key="id" as |item|}}
              <label class="isbf-explore-picker__option">
                <span class="isbf-explore-picker__label">{{item.label}}</span>
                <input
                  checked={{item.selected}}
                  class="isbf-explore-picker__checkbox"
                  disabled={{item.pending}}
                  type="checkbox"
                  {{on "change" (fn this.toggleOption item)}}
                />
              </label>
            {{else}}
              {{#unless @loading}}<p>{{i18n
                    (themePrefix "isbf_v2.explore_no_options")
                  }}</p>{{/unless}}
            {{/each}}
          </div>
          <div class="isbf-explore-picker__footer">
            <button
              class="isbf-explore-picker__clear"
              disabled={{eq @selectedIds.length 0}}
              type="button"
              {{on "click" this.clear}}
            >{{i18n (themePrefix "isbf_v2.explore_clear")}}</button>
            {{#if @canCreateCategory}}
              <button
                class="isbf-explore-picker__create"
                type="button"
                {{on "click" this.createCategory}}
              >{{i18n (themePrefix "isbf_v2.explore_create_category")}}</button>
            {{/if}}
          </div>
        </div>
      </:content>
    </DMenu>
  </template>
}
