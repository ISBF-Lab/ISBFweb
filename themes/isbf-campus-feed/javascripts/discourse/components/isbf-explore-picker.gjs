import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { scheduleOnce } from "@ember/runloop";
import { themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

let nextPickerId = 0;

export default class ISBFExplorePicker extends Component {
  @tracked isOpen = false;
  @tracked search = "";

  menuId = `isbf-explore-picker-${++nextPickerId}`;
  #root;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#removeListeners();
  }

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
    this.#close();
    this.args.onCreateCategory?.();
  }

  @action
  focusSearch() {
    this.#root?.querySelector("input[type='search']")?.focus();
  }

  @action
  observe(element) {
    this.#root = element;
  }

  @action
  onDocumentKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation();
      this.#close();
    }
  }

  @action
  onOutsidePointer(event) {
    if (!this.#root?.contains(event.target)) {
      this.#close();
    }
  }

  @action
  retrySearch() {
    this.args.onSearch?.(this.search);
  }

  @action
  toggle() {
    if (this.isOpen) {
      this.#close();
      return;
    }
    this.isOpen = true;
    this.args.onSearch?.(this.search);
    document.addEventListener("pointerdown", this.onOutsidePointer, true);
    document.addEventListener("keydown", this.onDocumentKeydown, true);
    scheduleOnce("afterRender", this, this.focusSearch);
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

  #close() {
    this.isOpen = false;
    this.#removeListeners();
    this.#root?.querySelector(".isbf-explore-picker__trigger")?.focus();
  }

  #removeListeners() {
    document.removeEventListener("pointerdown", this.onOutsidePointer, true);
    document.removeEventListener("keydown", this.onDocumentKeydown, true);
  }

  <template>
    <div class="isbf-explore-picker" {{didInsert this.observe}}>
      <button
        aria-controls={{this.menuId}}
        aria-expanded={{if this.isOpen "true" "false"}}
        class="isbf-explore-picker__trigger"
        disabled={{@disabled}}
        type="button"
        {{on "click" this.toggle}}
      >{{this.label}}{{dIcon "chevron-down"}}</button>
      {{#if this.isOpen}}
        <div
          aria-label={{i18n (themePrefix @labelKey)}}
          class="isbf-explore-picker__menu"
          id={{this.menuId}}
          role="group"
        >
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
          <div class="isbf-explore-picker__options">
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
      {{/if}}
    </div>
  </template>
}
