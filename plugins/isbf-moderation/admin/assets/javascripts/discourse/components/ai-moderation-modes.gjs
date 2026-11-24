import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import DNativeSelect from "discourse/ui-kit/d-native-select";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

const ENDPOINT = "/isbf/moderation/admin/ai-moderation-modes.json";
const CATEGORY_KEYS = ["fraud", "harassment", "privacy", "sexual"];
const LEVEL_KEYS = ["lenient", "standard", "strict"];
const ACTION_KEYS = ["review_only", "hide_and_review"];
const I18N_PREFIX = "isbf_moderation.admin.modes";

export default class AiModerationModes extends Component {
  @service a11y;
  @service currentUser;

  @tracked category = "fraud";
  @tracked editedLevel = "standard";
  @tracked busy = false;
  @tracked conflict = false;
  @tracked error;
  @tracked latestSaved;
  @tracked savedCategory;

  formData;

  #formApi;
  #revisions = {};
  #savedCategories = {};

  constructor(owner, args) {
    super(owner, args);
    this.formData = {};
    for (const category of CATEGORY_KEYS) {
      const { revision, active_level, profiles } =
        args.model.categories[category];
      this.#revisions[category] = revision;
      this.#savedCategories[category] = { active_level, profiles };
      this.formData[category] = { active_level, profiles };
    }
  }

  get categories() {
    return CATEGORY_KEYS.map((value) => ({
      value,
      label: i18n(`${I18N_PREFIX}.categories.${value}`),
    }));
  }

  get levels() {
    return LEVEL_KEYS.map((value) => ({
      value,
      label: i18n(`${I18N_PREFIX}.levels.${value}`),
    }));
  }

  get actions() {
    return ACTION_KEYS.map((value) => ({
      value,
      label: i18n(`${I18N_PREFIX}.actions.${value}`),
    }));
  }

  get maxPolicyLength() {
    return this.args.model.max_policy_length;
  }

  get showSaved() {
    return (
      this.savedCategory === this.category &&
      JSON.stringify(this.#formApi?.get(this.category)) ===
        JSON.stringify(this.#savedCategories[this.category])
    );
  }

  get latestSavedProfiles() {
    if (!this.latestSaved || this.latestSaved.category !== this.category) {
      return [];
    }
    return this.levels.map((level) => ({
      ...level,
      policy: this.latestSaved.configuration.profiles[level.value].policy,
      action: i18n(
        `${I18N_PREFIX}.actions.${this.latestSaved.configuration.profiles[level.value].action}`
      ),
    }));
  }

  get latestSavedActiveLevel() {
    return i18n(
      `${I18N_PREFIX}.levels.${this.latestSaved.configuration.active_level}`
    );
  }

  @action
  registerForm(api) {
    this.#formApi = api;
  }

  @action
  selectCategory(category) {
    this.category = category;
    this.conflict = false;
    this.error = null;
    this.latestSaved = null;
    this.#formApi.removeErrors();
  }

  @action
  selectEditedLevel(level) {
    this.editedLevel = level;
  }

  @action
  restoreProfile() {
    const profile =
      this.args.model.defaults[this.category].profiles[this.editedLevel];
    this.#formApi.set(`${this.category}.profiles.${this.editedLevel}`, {
      ...profile,
    });
    this.#formApi.removeErrors();
    this.a11y.announce(i18n(`${I18N_PREFIX}.restored`), "polite");
  }

  @action
  validate(data, { addError }) {
    this.error = null;
    for (const level of LEVEL_KEYS) {
      const policy = data[this.category].profiles[level].policy;
      if (
        typeof policy !== "string" ||
        !policy.trim() ||
        Array.from(policy).length > this.maxPolicyLength
      ) {
        const title = i18n(`${I18N_PREFIX}.levels.${level}`);
        const message = i18n(`${I18N_PREFIX}.invalid_policy`, {
          count: this.maxPolicyLength,
          level: title,
        });
        addError(`${this.category}.profiles.${level}.policy`, {
          title,
          message,
        });
        this.error = message;
      }
    }
  }

  @action
  async save(data) {
    const category = this.category;
    this.error = null;
    this.busy = true;
    try {
      const response = await ajax(ENDPOINT, {
        type: "PUT",
        contentType: "application/json",
        data: JSON.stringify({
          category,
          revision: this.#revisions[category],
          ...data[category],
        }),
      });
      const { revision, active_level, profiles } =
        response.categories[category];
      this.#revisions[category] = revision;
      this.#savedCategories[category] = { active_level, profiles };
      await this.#formApi.set(category, { active_level, profiles });
      this.#formApi.commitField(category);
      this.savedCategory = category;
      this.conflict = false;
      this.latestSaved = null;
      this.a11y.announce(i18n(`${I18N_PREFIX}.saved`), "polite");
    } catch (error) {
      this.conflict = error?.jqXHR?.status === 409;
      this.error = this.conflict
        ? i18n(`${I18N_PREFIX}.conflict`)
        : this.#errorText(error);
      this.a11y.announce(this.error, "assertive");
    } finally {
      this.busy = false;
    }
  }

  @action
  async refreshSavedVersion() {
    const category = this.category;
    this.busy = true;
    try {
      const response = await ajax(ENDPOINT);
      this.#revisions[category] = response.categories[category].revision;
      this.latestSaved = {
        category,
        configuration: response.categories[category],
      };
      this.conflict = false;
      this.error = null;
      this.a11y.announce(i18n(`${I18N_PREFIX}.refreshed`), "polite");
    } catch (error) {
      this.error = this.#errorText(error);
      this.a11y.announce(this.error, "assertive");
    } finally {
      this.busy = false;
    }
  }

  #errorText(error) {
    return (
      error?.jqXHR?.responseJSON?.errors?.join("\n") ||
      i18n(`${I18N_PREFIX}.request_failed`)
    );
  }

  <template>
    {{#if this.currentUser.admin}}
      <div
        class="admin-config-page__main-area ai-moderation-modes"
        data-test-ai-moderation-modes
        ...attributes
      >
        <DPageSubheader
          @descriptionLabel={{i18n "isbf_moderation.admin.modes.description"}}
          @titleLabel={{i18n "isbf_moderation.admin.modes.title"}}
        />
        <label for="ai-moderation-mode-category">{{i18n
            "isbf_moderation.admin.modes.category"
          }}</label>
        <DNativeSelect
          data-test-ai-mode-category
          id="ai-moderation-mode-category"
          @disabled={{this.busy}}
          @onChange={{this.selectCategory}}
          @value={{this.category}}
          as |select|
        >
          {{#each this.categories as |category|}}
            <select.Option
              @value={{category.value}}
            >{{category.label}}</select.Option>
          {{/each}}
        </DNativeSelect>
        <Form
          @commitOnSubmit={{false}}
          @data={{this.formData}}
          @onRegisterApi={{this.registerForm}}
          @onSubmit={{this.save}}
          @validate={{this.validate}}
          as |form|
        >
          <form.Object @name={{this.category}} as |categoryFields|>
            <AdminConfigAreaCard
              @heading="isbf_moderation.admin.modes.configuration"
            >
              <:content>
                <categoryFields.Field
                  @description={{i18n
                    "isbf_moderation.admin.modes.active_level_description"
                  }}
                  @disabled={{this.busy}}
                  @name="active_level"
                  @title={{i18n "isbf_moderation.admin.modes.active_level"}}
                  @type="select"
                  as |field|
                >
                  <field.Control
                    data-test-ai-mode-active-level
                    @includeNone={{false}}
                    as |select|
                  >
                    {{#each this.levels as |level|}}
                      <select.Option
                        @value={{level.value}}
                      >{{level.label}}</select.Option>
                    {{/each}}
                  </field.Control>
                </categoryFields.Field>
                <label for="ai-moderation-mode-edit-level">{{i18n
                    "isbf_moderation.admin.modes.edited_level"
                  }}</label>
                <DNativeSelect
                  data-test-ai-mode-edit-level
                  id="ai-moderation-mode-edit-level"
                  @disabled={{this.busy}}
                  @onChange={{this.selectEditedLevel}}
                  @value={{this.editedLevel}}
                  as |select|
                >
                  {{#each this.levels as |level|}}
                    <select.Option
                      @value={{level.value}}
                    >{{level.label}}</select.Option>
                  {{/each}}
                </DNativeSelect>
                <categoryFields.Object @name="profiles" as |profilesFields|>
                  <profilesFields.Object
                    @name={{this.editedLevel}}
                    as |profileFields|
                  >
                    <profileFields.Field
                      @description={{i18n
                        "isbf_moderation.admin.modes.policy_description"
                        count=this.maxPolicyLength
                      }}
                      @disabled={{this.busy}}
                      @format="full"
                      @name="policy"
                      @title={{i18n "isbf_moderation.admin.modes.policy"}}
                      @type="textarea"
                      as |field|
                    >
                      <field.Control data-test-ai-mode-policy rows="12" />
                    </profileFields.Field>
                    <profileFields.Field
                      @disabled={{this.busy}}
                      @name="action"
                      @title={{i18n "isbf_moderation.admin.modes.action"}}
                      @type="select"
                      as |field|
                    >
                      <field.Control
                        data-test-ai-mode-action
                        @includeNone={{false}}
                        as |select|
                      >
                        {{#each this.actions as |option|}}
                          <select.Option
                            @value={{option.value}}
                          >{{option.label}}</select.Option>
                        {{/each}}
                      </field.Control>
                    </profileFields.Field>
                  </profilesFields.Object>
                </categoryFields.Object>
                <DButton
                  class="btn-default"
                  data-test-ai-mode-restore
                  @action={{this.restoreProfile}}
                  @disabled={{this.busy}}
                  @label="isbf_moderation.admin.modes.restore"
                />
              </:content>
            </AdminConfigAreaCard>
          </form.Object>
          {{#if this.error}}
            <form.Alert
              data-test-ai-mode-error
              @type="error"
            >{{this.error}}</form.Alert>
          {{/if}}
          {{#if this.conflict}}
            <DButton
              class="btn-default"
              data-test-ai-mode-refresh-conflict
              @action={{this.refreshSavedVersion}}
              @disabled={{this.busy}}
              @label="isbf_moderation.admin.modes.refresh_saved_version"
            />
          {{/if}}
          {{#if this.latestSaved}}
            <form.Alert @type="info">{{i18n
                "isbf_moderation.admin.modes.refreshed"
              }}</form.Alert>
            <details data-test-ai-mode-saved-version>
              <summary>{{i18n
                  "isbf_moderation.admin.modes.saved_version"
                }}</summary>
              <p>{{i18n
                  "isbf_moderation.admin.modes.saved_active_level"
                  level=this.latestSavedActiveLevel
                }}</p>
              {{#each this.latestSavedProfiles as |profile|}}
                <h3>{{profile.label}}</h3>
                <p>{{profile.action}}</p>
                <pre>{{profile.policy}}</pre>
              {{/each}}
            </details>
          {{/if}}
          {{#if this.showSaved}}
            <form.Alert data-test-ai-mode-saved @type="success">{{i18n
                "isbf_moderation.admin.modes.saved"
              }}</form.Alert>
          {{/if}}
          <form.Actions>
            <form.Submit
              data-test-ai-mode-save
              @disabled={{this.busy}}
              @label="isbf_moderation.admin.modes.save"
            />
          </form.Actions>
        </Form>
      </div>
    {{/if}}
  </template>
}
