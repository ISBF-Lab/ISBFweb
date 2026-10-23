import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import {
  calendarEditorSections,
  calendarItemsFromSections,
  calendarItemsWithTopicTitle,
  officialCalendarEventOptionLabel,
  officialCalendarItemTitle,
} from "../lib/official-calendar";

export default class ISBFOfficialCalendarEditor extends Component {
  @service site;

  @tracked error = null;
  @tracked saving = false;
  @tracked
  section = this.args.model.section === "deadline" ? "deadline" : "event";
  #formApi;
  #nextPosition = 0;
  @tracked _itemCount = null;
  @tracked _events = null;

  @cached
  get formData() {
    return calendarEditorSections(
      calendarItemsWithTopicTitle(
        this.args.model.items,
        this.args.model.getTopicTitle?.() ?? "",
        { draft: true },
      ),
    );
  }

  get isEventSection() {
    return this.section === "event";
  }

  get canAdd() {
    const count =
      this._itemCount ??
      this.formData.events.length + this.formData.deadlines.length;
    return !this.saving && count < (this.site.isbf_calendar?.max_items ?? 20);
  }

  get eventOptions() {
    return (this._events ?? this.formData.events).map((event, index) => ({
      value: event.editor_key,
      label: officialCalendarEventOptionLabel(event, index),
    }));
  }

  @action
  registerApi(api) {
    this.#formApi = api;
    this.#nextPosition =
      this.formData.events.length + this.formData.deadlines.length;
  }

  @action
  selectSection(section) {
    this.section = section;
  }

  @action
  navigateTabs(event) {
    if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
      return;
    }
    event.preventDefault();
    this.section =
      event.key === "Home"
        ? "event"
        : event.key === "End"
          ? "deadline"
          : this.isEventSection
            ? "deadline"
            : "event";
    event.currentTarget
      .querySelector('[data-section="' + this.section + '"]')
      .focus();
  }

  @action
  updateCount(name, value, data) {
    this._itemCount = data.events.length + data.deadlines.length;
    this._events = data.events.map((item) => ({ ...item }));
    this.error = null;
    const match = name.match(/^((?:events|deadlines)\.\d+)\.all_day$/);
    if (match) {
      const item = this.#formApi.get(match[1]);
      for (const field of ["start", "end"]) {
        if (item[field]) {
          this.#formApi.set(
            match[1] + "." + field,
            value
              ? item[field].slice(0, 10)
              : item[field].slice(0, 10) + "T09:00",
          );
        }
      }
    }
  }

  @action
  addItem() {
    if (!this.canAdd) {
      return;
    }
    const position = this.#nextPosition++;
    const event = this.isEventSection;
    const collection = event ? "events" : "deadlines";
    this.#formApi.set(
      collection,
      this.#formApi.get(collection).concat({
        title: officialCalendarItemTitle(
          this.args.model.getTopicTitle?.() ?? "",
          event ? "event" : "deadline",
          { draft: true },
        ),
        schedule_kind: event ? "event" : "deadline",
        all_day: false,
        start: "",
        end: "",
        editor_position: position,
        ...(event
          ? { editor_key: "event-" + position, location: "", organizer: "" }
          : { related_event: "" }),
      }),
    );
  }

  @action
  removeItem(collection, index) {
    if (this.saving) {
      return;
    }
    const rows = this.#formApi.get(collection);
    if (collection === "events") {
      const key = rows[index].editor_key;
      this.#formApi.set(
        "deadlines",
        this.#formApi
          .get("deadlines")
          .filter((item) => item.related_event !== key),
      );
    }
    this.#formApi.set(
      collection,
      rows.filter((_, i) => i !== index),
    );
  }

  @action
  async save(data) {
    if (this.saving) {
      return;
    }
    let items;
    try {
      items = calendarItemsFromSections(
        data,
        this.args.model.getTopicTitle?.() ?? "",
      );
    } catch (error) {
      if (error.section) {
        this.section = error.section;
      }
      this.error = i18n(themePrefix("isbf_v2.schedule_invalid_item"));
      return;
    }
    const max = this.site.isbf_calendar?.max_items ?? 20;
    if (items.length > max) {
      this.error = i18n(themePrefix("isbf_v2.schedule_too_many_items"), {
        max,
      });
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      await this.args.model.onSave(items);
      if (!this.isDestroying) {
        this.args.closeModal();
      }
    } catch {
      if (!this.isDestroying) {
        this.error = i18n(themePrefix("isbf_v2.schedule_save_error"));
      }
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      class="isbf-official-calendar-editor"
      @closeModal={{@closeModal}}
      @title={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
    >
      <:body>
        <p>{{i18n (themePrefix "isbf_v2.schedule_timezone_hint")}}</p>
        <div
          aria-label={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
          class="isbf-official-calendar-editor__tabs"
          role="tablist"
          {{on "keydown" this.navigateTabs}}
        >
          <DButton
            aria-controls="isbf-calendar-event-panel"
            aria-selected={{if this.isEventSection "true" "false"}}
            data-section="event"
            id="isbf-calendar-event-tab"
            role="tab"
            tabindex={{if this.isEventSection "0" "-1"}}
            @action={{fn this.selectSection "event"}}
            @label={{themePrefix "isbf_v2.schedule_activity_time"}}
          />
          <DButton
            aria-controls="isbf-calendar-deadline-panel"
            aria-selected={{if this.isEventSection "false" "true"}}
            data-section="deadline"
            id="isbf-calendar-deadline-tab"
            role="tab"
            tabindex={{if this.isEventSection "-1" "0"}}
            @action={{fn this.selectSection "deadline"}}
            @label={{themePrefix "isbf_v2.schedule_registration_deadline"}}
          />
        </div>
        <Form
          @data={{this.formData}}
          @onRegisterApi={{this.registerApi}}
          @onSet={{this.updateCount}}
          @onSubmit={{this.save}}
          as |form|
        >
          <div
            aria-labelledby="isbf-calendar-event-tab"
            hidden={{not this.isEventSection}}
            id="isbf-calendar-event-panel"
            role="tabpanel"
            tabindex="0"
          ><form.Collection @name="events" as |collection index item|><div
                class="isbf-official-calendar-editor__item"
              >
                <collection.Field
                  @name="all_day"
                  @title={{i18n (themePrefix "isbf_v2.schedule_date_only")}}
                  @type="checkbox"
                  as |field|
                ><field.Control /></collection.Field>
                <collection.Field
                  @name="start"
                  @title={{i18n (themePrefix "isbf_v2.schedule_start")}}
                  @type={{if item.all_day "input-date" "input-datetime-local"}}
                  @validation={{if this.isEventSection "required"}}
                  as |field|
                ><div
                    class="isbf-official-calendar-editor__datetime"
                    data-empty={{not item.start}}
                  >
                    <field.Control />
                    <span
                      aria-hidden="true"
                      class="isbf-official-calendar-editor__date-placeholder"
                    >{{i18n
                        (themePrefix "isbf_v2.schedule_date_placeholder")
                      }}{{#unless item.all_day}} --:--{{/unless}}</span>
                  </div></collection.Field>
                <collection.Field
                  @name="end"
                  @title={{i18n (themePrefix "isbf_v2.schedule_end_optional")}}
                  @type={{if item.all_day "input-date" "input-datetime-local"}}
                  as |field|
                ><div
                    class="isbf-official-calendar-editor__datetime"
                    data-empty={{not item.end}}
                  >
                    <field.Control />
                    <span
                      aria-hidden="true"
                      class="isbf-official-calendar-editor__date-placeholder"
                    >{{i18n
                        (themePrefix "isbf_v2.schedule_date_placeholder")
                      }}{{#unless item.all_day}} --:--{{/unless}}</span>
                  </div></collection.Field>
                <collection.Field
                  @name="location"
                  @title={{i18n (themePrefix "isbf_v2.schedule_location")}}
                  @type="input"
                  as |field|
                ><field.Control maxlength="255" /></collection.Field>
                <collection.Field
                  @name="organizer"
                  @title={{i18n (themePrefix "isbf_v2.schedule_organizer")}}
                  @type="input"
                  as |field|
                ><field.Control maxlength="120" /></collection.Field>
                <DButton
                  class="isbf-official-calendar-editor__remove"
                  @action={{fn this.removeItem "events" index}}
                  @disabled={{this.saving}}
                  @icon="trash-can"
                  @label={{themePrefix "isbf_v2.schedule_remove_item"}}
                />
              </div></form.Collection></div>
          <div
            aria-labelledby="isbf-calendar-deadline-tab"
            hidden={{this.isEventSection}}
            id="isbf-calendar-deadline-panel"
            role="tabpanel"
            tabindex="0"
          ><form.Collection @name="deadlines" as |collection index item|><div
                class="isbf-official-calendar-editor__item"
              >
                <collection.Field
                  @name="all_day"
                  @title={{i18n (themePrefix "isbf_v2.schedule_date_only")}}
                  @type="checkbox"
                  as |field|
                ><field.Control /></collection.Field>
                <collection.Field
                  @name="start"
                  @title={{i18n (themePrefix "isbf_v2.schedule_due")}}
                  @type={{if item.all_day "input-date" "input-datetime-local"}}
                  @validation={{if this.isEventSection null "required"}}
                  as |field|
                ><div
                    class="isbf-official-calendar-editor__datetime"
                    data-empty={{not item.start}}
                  >
                    <field.Control />
                    <span
                      aria-hidden="true"
                      class="isbf-official-calendar-editor__date-placeholder"
                    >{{i18n
                        (themePrefix "isbf_v2.schedule_date_placeholder")
                      }}{{#unless item.all_day}} --:--{{/unless}}</span>
                  </div></collection.Field>
                <collection.Field
                  @name="related_event"
                  @title={{i18n (themePrefix "isbf_v2.schedule_related_event")}}
                  @type="select"
                  as |field|
                ><field.Control as |select|><select.Option @value="">{{i18n
                        (themePrefix "isbf_v2.schedule_independent_deadline")
                      }}</select.Option>{{#each
                      this.eventOptions
                      as |option|
                    }}<select.Option
                        @value={{option.value}}
                      >{{option.label}}</select.Option>{{/each}}</field.Control></collection.Field>
                <DButton
                  class="isbf-official-calendar-editor__remove"
                  @action={{fn this.removeItem "deadlines" index}}
                  @disabled={{this.saving}}
                  @icon="trash-can"
                  @label={{themePrefix "isbf_v2.schedule_remove_item"}}
                />
              </div></form.Collection></div>
          <DButton
            class="isbf-official-calendar-editor__add"
            @action={{this.addItem}}
            @disabled={{not this.canAdd}}
            @icon="plus"
            @label={{themePrefix "isbf_v2.schedule_add_item"}}
          />
          {{#if this.error}}<p
              class="isbf-official-calendar-editor__error"
              role="alert"
            >{{this.error}}</p>{{/if}}
          <form.Submit
            @disabled={{this.saving}}
            @label={{themePrefix "isbf_v2.schedule_save_items"}}
          />
        </Form>
      </:body>
    </DModal>
  </template>
}
