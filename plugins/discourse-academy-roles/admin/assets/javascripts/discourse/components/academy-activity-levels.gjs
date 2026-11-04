import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { registerDestructor } from "@ember/destroyable";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { cancel, later } from "@ember/runloop";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import {
  configurationPayload,
  formDataFor,
  newLevel,
} from "../lib/activity-level-rules";
import AcademyActivityCosmetics from "./academy-activity-cosmetics";
import AcademyActivityLevelEditor from "./academy-activity-level-editor";

const ENDPOINT = "/academy-roles/admin/activity-levels";

export default class AcademyActivityLevels extends Component {
  @service a11y;
  @service currentUser;
  @service dialog;

  @tracked error;
  @tracked model;
  @tracked formData;
  @tracked run;
  @tracked saved = false;
  @tracked busy = false;
  @tracked pollingError = false;

  #confirmedDeletedIds = [];
  #formApi;
  #pollTimer;

  constructor(owner, args) {
    super(owner, args);
    this.model = args.model;
    this.formData = formDataFor(args.model);
    this.run = args.model.recalculation;
    this.#schedulePoll();
    registerDestructor(this, () => cancel(this.#pollTimer));
  }

  get showSaved() {
    return this.saved && !this.#formApi?.isDirty;
  }

  get statusText() {
    return this.run
      ? i18n(`academy_roles.activity_levels.statuses.${this.run.status}`)
      : "";
  }

  get progressText() {
    return this.run
      ? i18n("academy_roles.activity_levels.progress", this.run)
      : "";
  }

  get canRetry() {
    return ["failed", "completed_with_errors"].includes(this.run?.status);
  }

  get minimumContinuousCheckGapHours() {
    return this.model.minimum_continuous_check_gap_hours ?? 36;
  }

  @action
  registerForm(api) {
    this.#formApi = api;
  }

  @action
  addLevel(form) {
    form.addItemToCollection("levels", newLevel());
  }

  @action
  async deleteLevel(fields, index, level) {
    this.busy = true;
    try {
      let count = 0;
      if (level.id) {
        const impact = await ajax(`${ENDPOINT}/deletion-impact`, {
          data: { level_id: level.id },
        });
        if (impact.revision !== this.model.revision) {
          this.error = i18n("academy_roles.activity_levels.conflict");
          return;
        }
        count = impact.assigned_users;
        if (impact.references?.length) {
          this.error = i18n(
            "academy_roles.activity_cosmetics.referenced_level",
            { references: impact.references.join(", ") }
          );
          return;
        }
      }
      this.dialog.deleteConfirm({
        message: i18n("academy_roles.activity_levels.delete_confirmation", {
          level: index,
          count,
        }),
        didConfirm: () => {
          if (level.id) {
            this.#confirmedDeletedIds.push(level.id);
          }
          fields.remove(index);
        },
      });
    } catch (error) {
      this.error = this.#errorText(error);
    } finally {
      this.busy = false;
    }
  }

  @action
  reset() {
    this.#confirmedDeletedIds = [];
    this.error = null;
    this.saved = false;
  }

  @action
  validate(data, { addError }) {
    this.error = null;
    const numeric = (value, min, max = 2147483647) =>
      Number.isInteger(value) && value >= min && value <= max;
    for (const [index, level] of data.levels.entries()) {
      const invalid = (field) => {
        const message = i18n("academy_roles.activity_levels.invalid_level", {
          level: index,
        });
        addError(`levels.${index}.${field}`, { title: `LV${index}`, message });
        this.error = message;
      };
      if (typeof level.name !== "string" || level.name.length > 80) {
        invalid("name");
      }
      if (!index) {
        continue;
      }
      for (const [field, minimum, maximum] of [
        ["period_days", 1, 36500],
        ["continuous_days", 0, 36500],
        [
          "max_check_gap_hours",
          level.continuous_days > 0 ? this.minimumContinuousCheckGapHours : 1,
          876000,
        ],
        ["demotion_buffer_percent", 0, 100],
      ]) {
        if (!numeric(level[field], minimum, maximum)) {
          invalid(field);
        }
      }
      if (
        !level.basic_conditions.length &&
        !level.advanced_conditions.length &&
        !level.continuous_days
      ) {
        invalid("name");
      }
      for (const group of ["basic_conditions", "advanced_conditions"]) {
        for (const [conditionIndex, condition] of level[group].entries()) {
          const definition = this.model.catalog.find(
            (entry) => entry.key === condition.metric
          );
          for (const [field, minimum, maximum] of [
            ["value", 0, definition.percentage ? 100 : 2147483647],
            ...(definition.percentage ? [["cap", 0, 2147483647]] : []),
            ...(definition.months ? [["months", 1, 1200]] : []),
          ]) {
            if (!numeric(condition[field], minimum, maximum)) {
              const message = i18n(
                "academy_roles.activity_levels.invalid_number"
              );
              addError(`levels.${index}.${group}.${conditionIndex}.${field}`, {
                title: message,
                message,
              });
              this.error = message;
            }
          }
        }
      }
    }
  }

  @action
  async save(data) {
    this.error = null;
    this.busy = true;
    try {
      const response = await ajax(ENDPOINT, {
        type: "PUT",
        contentType: "application/json",
        data: JSON.stringify(
          configurationPayload(
            data,
            this.model.revision,
            this.#confirmedDeletedIds
          )
        ),
      });
      this.#formApi.commit();
      this.model = response;
      this.formData = formDataFor(response);
      this.run = response.recalculation;
      this.#confirmedDeletedIds = [];
      this.saved = true;
      this.a11y.announce(i18n("academy_roles.activity_levels.saved"), "polite");
      this.#schedulePoll();
    } catch (error) {
      this.error = this.#errorText(error);
    } finally {
      this.busy = false;
    }
  }

  @action
  async retry() {
    this.busy = true;
    try {
      const response = await ajax(`${ENDPOINT}/recalculate`, { type: "POST" });
      this.run = response.recalculation;
      this.pollingError = false;
      this.#schedulePoll();
    } catch (error) {
      this.error = this.#errorText(error);
    } finally {
      this.busy = false;
    }
  }

  @action
  async refreshStatus() {
    try {
      const response = await ajax(`${ENDPOINT}/recalculation`);
      if (this.isDestroying) {
        return;
      }
      if (!response.recalculation && this.run) {
        return;
      }
      if (response.recalculation?.revision < this.model.revision) {
        this.#schedulePoll();
        return;
      }
      this.run = response.recalculation;
      this.pollingError = false;
      this.#schedulePoll();
    } catch {
      if (!this.isDestroying) {
        this.pollingError = true;
      }
    }
  }

  #schedulePoll() {
    cancel(this.#pollTimer);
    if (
      this.currentUser.admin &&
      ["queued", "running"].includes(this.run?.status)
    ) {
      this.#pollTimer = later(this, this.refreshStatus, 2000);
    }
  }

  #errorText(error) {
    return (
      error?.jqXHR?.responseJSON?.errors?.join("\n") ||
      i18n("academy_roles.activity_levels.save_failed")
    );
  }

  <template>
    {{#if this.currentUser.admin}}
      <div
        class="admin-config-page__main-area academy-activity-levels"
        ...attributes
      >
        <DPageSubheader
          @descriptionLabel={{i18n "academy_roles.activity_levels.description"}}
          @titleLabel={{i18n "academy_roles.activity_levels.title"}}
        />
        <Form
          @commitOnSubmit={{false}}
          @data={{this.formData}}
          @onRegisterApi={{this.registerForm}}
          @onReset={{this.reset}}
          @onSubmit={{this.save}}
          @validate={{this.validate}}
          as |form data|
        >
          <AdminConfigAreaCard @heading="academy_roles.activity_levels.general">
            <:content>
              <p>{{i18n "academy_roles.activity_levels.participants"}}</p>
              <p>{{i18n "academy_roles.activity_levels.independent_rules"}}</p>
              <form.Field
                @description={{i18n
                  "academy_roles.activity_levels.demotion_description"
                }}
                @name="allow_demotion"
                @title={{i18n "academy_roles.activity_levels.allow_demotion"}}
                @type="toggle"
                as |field|
              >
                <field.Control />
              </form.Field>
              {{#unless this.model.initialized}}
                <form.Alert @type="info">{{i18n
                    "academy_roles.activity_levels.initialize_description"
                  }}</form.Alert>
              {{/unless}}
            </:content>
          </AdminConfigAreaCard>
          <form.Object @name="cosmetics" as |fields values|>
            <AcademyActivityCosmetics
              @fields={{fields}}
              @levels={{data.levels}}
              @values={{values}}
            />
          </form.Object>
          {{#if this.error}}
            <form.Alert @type="error">{{this.error}}</form.Alert>
          {{/if}}
          <form.Collection @name="levels" as |fields index level|>
            <AcademyActivityLevelEditor
              @badges={{this.model.badge_options}}
              @busy={{this.busy}}
              @catalog={{this.model.catalog}}
              @fields={{fields}}
              @form={{form}}
              @index={{index}}
              @level={{level}}
              @minimumContinuousCheckGapHours={{this.minimumContinuousCheckGapHours}}
              @onDelete={{fn this.deleteLevel fields index level}}
            />
          </form.Collection>
          <DButton
            class="btn-default"
            @action={{fn this.addLevel form}}
            @disabled={{this.busy}}
            @label="academy_roles.activity_levels.add_level"
          />
          {{#if this.showSaved}}
            <form.Alert @type="success">{{i18n
                "academy_roles.activity_levels.saved"
              }}</form.Alert>
          {{/if}}
          <form.Actions>
            <form.Submit
              @disabled={{this.busy}}
              @label="academy_roles.activity_levels.save"
            />
            <form.Reset @disabled={{this.busy}} />
          </form.Actions>
          {{#if this.run}}
            <AdminConfigAreaCard
              @heading="academy_roles.activity_levels.recalculation"
            >
              <:content>
                <p
                  class="academy-activity-levels__status"
                  role="status"
                >{{this.statusText}}</p>
                <p>{{this.progressText}}</p>
                {{#if this.canRetry}}
                  <p>{{i18n
                      "academy_roles.activity_levels.retry_description"
                    }}</p>
                  <DButton
                    class="btn-default"
                    @action={{this.retry}}
                    @disabled={{this.busy}}
                    @label="academy_roles.activity_levels.retry"
                  />
                {{/if}}
                {{#if this.pollingError}}
                  <form.Alert @type="error">{{i18n
                      "academy_roles.activity_levels.polling_failed"
                    }}</form.Alert>
                  <DButton
                    class="btn-default"
                    @action={{this.refreshStatus}}
                    @label="academy_roles.activity_levels.refresh_status"
                  />
                {{/if}}
              </:content>
            </AdminConfigAreaCard>
          {{/if}}
        </Form>
      </div>
    {{/if}}
  </template>
}
