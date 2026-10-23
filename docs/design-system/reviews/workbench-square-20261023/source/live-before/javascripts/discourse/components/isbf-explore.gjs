import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import {
  createExplorePreferenceWriter,
  normalizeExplorePreferences,
  preferencesSignature,
} from "../lib/explore-preferences";
import {
  buildExploreQuery,
  categoryFilterId,
  enqueueExploreQuery,
} from "../lib/explore-query";
import ISBFExploreGroup from "./isbf-explore-group";
import ISBFExplorePicker from "./isbf-explore-picker";

export default class ISBFExplore extends Component {
  @service composer;
  @service currentUser;
  @service router;
  @service site;
  @service siteSettings;

  @tracked preferences = normalizeExplorePreferences();
  @tracked preferencesReady = false;
  @tracked restoreFailed = false;
  @tracked saveState = "idle";
  @tracked resolvingTagIds = [];
  @tracked selectedTags = [];
  @tracked tagResults = [];
  @tracked tagSearchFailed = false;
  @tracked tagSearchLoading = false;

  #canonicalTags = new Map();
  #generation = 0;
  #ownerId;
  #searchNumber = 0;
  #searchTimer;
  #tagSelectionEpoch = 0;
  #writer;

  constructor() {
    super(...arguments);
    this.#initializeAccount();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#generation += 1;
    this.#writer?.cancel();
    clearTimeout(this.#searchTimer);
  }

  get accountReady() {
    return (
      this.preferencesReady && (this.currentUser?.id || null) === this.#ownerId
    );
  }

  get categoryItems() {
    const categories = Array.from(this.site.categories || []);
    return categories.flatMap((category) => {
      const id = categoryFilterId(category);
      return id ? [{ category, id, label: category.name }] : [];
    });
  }

  get categoryFilterAvailable() {
    return this.site.isbf_explore_category_id_filter === true;
  }

  get filtersReady() {
    return this.accountReady && this.categoryFilterAvailable;
  }

  get showPreferenceStatus() {
    return !this.preferencesReady || this.saveState !== "idle";
  }

  get selectedCategory() {
    if (this.preferences.category_ids.length !== 1) {
      return null;
    }
    return this.categoryItems.find(
      (item) => item.id === this.preferences.category_ids[0]
    )?.category;
  }

  get composeDisabled() {
    return (
      !this.accountReady ||
      Boolean(
        this.currentUser && this.selectedCategory?.canCreateTopic === false
      )
    );
  }

  get composeTitle() {
    return this.currentUser && this.selectedCategory?.canCreateTopic === false
      ? i18n(themePrefix("isbf_v2.explore_create_restricted"))
      : null;
  }

  get groups() {
    if (!this.filtersReady) {
      return [];
    }
    const tags = this.selectedTags.map((tag) => tag.name);
    const selected = new Set(this.preferences.category_ids);
    const categories = this.categoryItems.filter((item) =>
      selected.has(item.id)
    );
    const groups = this.preferences.category_ids.length
      ? categories
      : [
          {
            id: "all",
            label: i18n(
              themePrefix(
                tags.length
                  ? "isbf_v2.explore_matching_tags"
                  : "isbf_v2.explore_all_topics"
              )
            ),
          },
        ];
    return groups.map((group) => {
      const query = buildExploreQuery({
        categoryId: group.category?.id,
        order: this.preferences.order,
        tags,
      });
      return {
        category: group.category,
        key: `${this.currentUser?.id || "guest"}:${group.id}:${query}`,
        label: group.label,
        query,
      };
    });
  }

  get tagItems() {
    const seen = new Set();
    return [...this.selectedTags, ...this.tagResults].flatMap((tag) => {
      if (seen.has(tag.id)) {
        return [];
      }
      seen.add(tag.id);
      return [
        {
          ...tag,
          label: tag.text || tag.name,
          pending: this.resolvingTagIds.includes(tag.id),
        },
      ];
    });
  }

  get tagsLoading() {
    return this.tagSearchLoading || this.resolvingTagIds.length > 0;
  }

  @action
  clearCategories() {
    this.#updatePreferences({ category_ids: [] });
  }

  @action
  clearTags() {
    this.#tagSelectionEpoch += 1;
    this.resolvingTagIds = [];
    this.selectedTags = [];
    this.#updatePreferences({ tag_ids: [] });
  }

  @action
  newTopic() {
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    if (this.composeDisabled) {
      return;
    }
    this.composer.openNewTopic(
      this.selectedCategory?.canCreateTopic
        ? { category: this.selectedCategory }
        : {}
    );
  }

  @action
  retryPreferences() {
    if (this.restoreFailed) {
      void this.#restorePreferences();
    } else {
      void this.#writer?.retry();
    }
  }

  @action
  searchTags(term) {
    clearTimeout(this.#searchTimer);
    const request = ++this.#searchNumber;
    const generation = this.#generation;
    this.tagSearchLoading = true;
    this.tagSearchFailed = false;
    this.#searchTimer = setTimeout(async () => {
      try {
        const result = await ajax("/tags/filter/search.json", {
          data: {
            limit: this.siteSettings.max_tag_search_results,
            q: term.trim(),
          },
        });
        if (this.#isCurrent(generation) && request === this.#searchNumber) {
          this.tagResults = (result.results || []).map((tag) => ({
            ...tag,
            id: Number(tag.id),
          }));
        }
      } catch {
        if (this.#isCurrent(generation) && request === this.#searchNumber) {
          this.tagSearchFailed = true;
        }
      } finally {
        if (this.#isCurrent(generation) && request === this.#searchNumber) {
          this.tagSearchLoading = false;
        }
      }
    }, 200);
  }

  @action
  syncAccount() {
    if ((this.currentUser?.id || null) !== this.#ownerId) {
      this.#initializeAccount();
    }
  }

  @action
  toggleCategory(item) {
    const selected = this.preferences.category_ids;
    this.#updatePreferences({
      category_ids: selected.includes(item.id)
        ? selected.filter((id) => id !== item.id)
        : [...selected, item.id],
    });
  }

  @action
  async toggleTag(item) {
    if (this.resolvingTagIds.includes(item.id)) {
      return;
    }
    if (this.preferences.tag_ids.includes(item.id)) {
      this.selectedTags = this.selectedTags.filter((tag) => tag.id !== item.id);
      this.#updatePreferences({
        tag_ids: this.preferences.tag_ids.filter((id) => id !== item.id),
      });
      return;
    }
    const generation = this.#generation;
    const selectionEpoch = this.#tagSelectionEpoch;
    this.resolvingTagIds = [...this.resolvingTagIds, item.id];
    try {
      let tag = this.#canonicalTags.get(item.id);
      if (!tag) {
        const result = await enqueueExploreQuery(
          () => ajax(`/tag/${item.id}/info.json`),
          () =>
            this.#isCurrent(generation) &&
            selectionEpoch === this.#tagSelectionEpoch
        );
        const name = result?.tag_info?.isbf_explore_filter_name;
        if (name) {
          tag = { ...item, name };
        }
      }
      if (
        !this.#isCurrent(generation) ||
        selectionEpoch !== this.#tagSelectionEpoch
      ) {
        return;
      }
      if (!tag?.name) {
        throw new Error("Missing visible tag");
      }
      this.#canonicalTags.set(item.id, tag);
      this.selectedTags = [...this.selectedTags, { ...tag, id: item.id }];
      this.#updatePreferences({
        tag_ids: [...this.preferences.tag_ids, item.id],
      });
    } catch {
      if (
        this.#isCurrent(generation) &&
        selectionEpoch === this.#tagSelectionEpoch
      ) {
        this.tagSearchFailed = true;
      }
    } finally {
      if (
        this.#isCurrent(generation) &&
        selectionEpoch === this.#tagSelectionEpoch
      ) {
        this.resolvingTagIds = this.resolvingTagIds.filter(
          (id) => id !== item.id
        );
      }
    }
  }

  @action
  toggleOrder() {
    this.#updatePreferences({
      order: this.preferences.order === "hot" ? "activity" : "hot",
    });
  }

  #applyResponse(result) {
    const payload = result?.preferences;
    if (
      !Array.isArray(payload?.category_ids) ||
      !Array.isArray(payload?.tag_ids) ||
      !["activity", "hot"].includes(payload.order) ||
      !Array.isArray(result.tags)
    ) {
      throw new Error("Missing explore preferences");
    }
    const preferences = normalizeExplorePreferences(payload);
    const tags = result.tags.map((tag) => ({ ...tag, id: Number(tag.id) }));
    if (
      preferences.tag_ids.some(
        (id) => !tags.some((tag) => tag.id === id && tag.name)
      )
    ) {
      throw new Error("Missing selected tag metadata");
    }
    this.preferences = preferences;
    this.selectedTags = preferences.tag_ids.map((id) =>
      tags.find((tag) => tag.id === id)
    );
    this.selectedTags.forEach((tag) => this.#canonicalTags.set(tag.id, tag));
  }

  #initializeAccount() {
    this.#generation += 1;
    this.#ownerId = this.currentUser?.id || null;
    this.#searchNumber += 1;
    this.#tagSelectionEpoch += 1;
    this.#writer?.cancel();
    this.#writer = null;
    clearTimeout(this.#searchTimer);
    this.preferences = normalizeExplorePreferences();
    this.preferencesReady = !this.#ownerId;
    this.restoreFailed = false;
    this.saveState = "idle";
    this.selectedTags = [];
    this.tagResults = [];
    this.tagSearchFailed = false;
    this.tagSearchLoading = false;
    this.resolvingTagIds = [];
    this.#canonicalTags.clear();
    if (this.#ownerId) {
      void this.#restorePreferences();
    }
  }

  #isCurrent(generation) {
    return (
      generation === this.#generation &&
      (this.currentUser?.id || null) === this.#ownerId &&
      !this.isDestroying
    );
  }

  async #restorePreferences() {
    const generation = ++this.#generation;
    this.preferencesReady = false;
    this.restoreFailed = false;
    try {
      const result = await ajax("/isbf/explore/preferences");
      if (!this.#isCurrent(generation)) {
        return;
      }
      this.#applyResponse(result);
      this.preferencesReady = true;
      this.#writer = createExplorePreferenceWriter({
        onSaved: (snapshot, response) => {
          if (
            this.#isCurrent(generation) &&
            preferencesSignature(snapshot) ===
              preferencesSignature(this.preferences)
          ) {
            this.#applyResponse(response);
          }
        },
        onState: (state) => {
          if (this.#isCurrent(generation)) {
            this.saveState = state;
          }
        },
        save: (preferences) => {
          if (!this.#isCurrent(generation)) {
            throw new Error("Account changed");
          }
          return ajax("/isbf/explore/preferences", {
            contentType: "application/json",
            data: JSON.stringify(preferences),
            type: "PUT",
          });
        },
      });
    } catch {
      if (this.#isCurrent(generation)) {
        this.restoreFailed = true;
      }
    }
  }

  #updatePreferences(changes) {
    if (!this.filtersReady) {
      return;
    }
    this.preferences = normalizeExplorePreferences({
      ...this.preferences,
      ...changes,
    });
    this.#writer?.update(this.preferences);
  }

  <template>
    <main
      class="isbf-explore"
      {{didUpdate this.syncAccount this.currentUser.id}}
    >
      {{#if this.accountReady}}
        <div class="isbf-explore__toolbar">
          <ISBFExplorePicker
            @canCreateCategory={{@canCreateCategory}}
            @disabled={{not this.filtersReady}}
            @items={{this.categoryItems}}
            @labelKey="isbf_v2.explore_categories"
            @onClear={{this.clearCategories}}
            @onCreateCategory={{@onCreateCategory}}
            @onToggle={{this.toggleCategory}}
            @searchKey="isbf_v2.explore_search_categories"
            @selectedIds={{this.preferences.category_ids}}
          />
          <ISBFExplorePicker
            @disabled={{not this.filtersReady}}
            @error={{this.tagSearchFailed}}
            @items={{this.tagItems}}
            @labelKey="isbf_v2.explore_tags"
            @loading={{this.tagsLoading}}
            @onClear={{this.clearTags}}
            @onSearch={{this.searchTags}}
            @onToggle={{this.toggleTag}}
            @searchKey="isbf_v2.explore_search_tags"
            @selectedIds={{this.preferences.tag_ids}}
          />
          <button
            aria-pressed={{if (eq this.preferences.order "hot") "true" "false"}}
            class="isbf-explore__order"
            disabled={{not this.filtersReady}}
            type="button"
            {{on "click" this.toggleOrder}}
          >{{i18n (themePrefix "isbf_v2.explore_hot")}}</button>
          <button
            class="isbf-explore__compose"
            disabled={{this.composeDisabled}}
            title={{this.composeTitle}}
            type="button"
            {{on "click" this.newTopic}}
          >{{i18n (themePrefix "isbf_v2.explore_new_topic")}}</button>
        </div>
      {{/if}}
      {{#unless this.categoryFilterAvailable}}
        <div class="isbf-explore__error" role="alert">
          {{i18n (themePrefix "isbf_v2.explore_filter_unavailable")}}
        </div>
      {{/unless}}
      {{#if this.restoreFailed}}
        <div class="isbf-explore__error" role="alert">
          <span>{{i18n (themePrefix "isbf_v2.explore_restore_error")}}</span>
          <button type="button" {{on "click" this.retryPreferences}}>{{i18n
              (themePrefix "isbf_v2.explore_retry")
            }}</button>
        </div>
      {{else if (eq this.saveState "failed")}}
        <div class="isbf-explore__error" role="alert">
          <span>{{i18n (themePrefix "isbf_v2.explore_save_error")}}</span>
          <button type="button" {{on "click" this.retryPreferences}}>{{i18n
              (themePrefix "isbf_v2.explore_retry")
            }}</button>
        </div>
      {{else if this.currentUser}}
        {{#if this.showPreferenceStatus}}
          <p class="isbf-explore__status" role="status">
            {{#if (eq this.saveState "saved")}}{{i18n
                (themePrefix "isbf_v2.explore_saved")
              }}{{else if (eq this.saveState "idle")}}
              {{#unless this.preferencesReady}}{{i18n
                  (themePrefix "isbf_v2.explore_loading")
                }}{{/unless}}
            {{else}}{{i18n (themePrefix "isbf_v2.explore_saving")}}{{/if}}
          </p>
        {{/if}}
      {{else}}
        <p class="isbf-explore__status">{{i18n
            (themePrefix "isbf_v2.explore_guest_preferences")
          }}</p>
      {{/if}}
      {{#if this.filtersReady}}
        {{#each this.groups key="key" as |group|}}
          <ISBFExploreGroup
            @category={{group.category}}
            @label={{group.label}}
            @query={{group.query}}
          />
        {{/each}}
      {{/if}}
    </main>
  </template>
}
