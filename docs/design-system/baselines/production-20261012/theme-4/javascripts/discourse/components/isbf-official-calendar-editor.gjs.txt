import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import {
  calendarEditorItems,
  calendarItemsFromEditor,
} from "../lib/official-calendar";

export default class ISBFOfficialCalendarEditor extends Component {
  @service site;

  @tracked error = null;
  #formApi;

  @tracked _itemCount = null;

  @cached
  get formData() {
    return { items: calendarEditorItems(this.args.model.items) };
  }

  get canAdd() {
    return (
      (this._itemCount ?? this.args.model.items.length) <
      (this.site.isbf_calendar?.max_items ?? 20)
    );
  }

  @action
  registerApi(api) {
    this.#formApi = api;
  }

  @action
  updateCount(name, value, data) {
    this._itemCount = data.items.reduce(
      (count, item) =>
        count +
        (item.schedule_kind === "event" && item.has_registration_deadline
          ? 2
          : 1),
      0
    );
    this.error = null;
    const match = name.match(
      /^(items\.\d+(?:\.registration_deadline)?)\.all_day$/
    );
    if (match) {
      const item = this.#formApi.get(match[1]);
      for (const field of ["start", "end"]) {
        if (item[field]) {
          this.#formApi.set(
            `${match[1]}.${field}`,
            value
              ? item[field].slice(0, 10)
              : `${item[field].slice(0, 10)}T09:00`
          );
        }
      }
    }
  }

  @action
  addItem() {
    if (this.canAdd) {
      this.#formApi.set(
        "items",
        this.#formApi.get("items").concat({
          title: "",
          schedule_kind: "event",
          all_day: false,
          start: "",
          end: "",
          location: "",
          organizer: "",
          has_registration_deadline: false,
          registration_deadline: {
            title: "",
            schedule_kind: "deadline",
            all_day: false,
            start: "",
            end: "",
          },
        })
      );
    }
  }

  @action
  removeItem(index) {
    this.#formApi.set(
      "items",
      this.#formApi.get("items").filter((_, i) => i !== index)
    );
  }

  @action
  save(data) {
    let items;
    try {
      items = calendarItemsFromEditor(data.items);
    } catch {
      this.error = i18n(themePrefix("isbf_v2.schedule_invalid_time"));
      return;
    }
    const max = this.site.isbf_calendar?.max_items ?? 20;
    if (items.length > max) {
      this.error = i18n(themePrefix("isbf_v2.schedule_too_many_items"), {
        max,
      });
      return;
    }
    this.args.model.onSave(items);
    this.args.closeModal();
  }

  <template>
    <DModal
      class="isbf-official-calendar-editor"
      @closeModal={{@closeModal}}
      @title={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
    >
      <:body>
        <p>{{i18n (themePrefix "isbf_v2.schedule_timezone_hint")}}</p>
        <Form
          @data={{this.formData}}
          @onRegisterApi={{this.registerApi}}
          @onSet={{this.updateCount}}
          @onSubmit={{this.save}}
          as |form|
        >
          <form.Collection @name="items" as |collection index item|>
            <div class="isbf-official-calendar-editor__item">
              <collection.Field
                @name="title"
                @title={{i18n (themePrefix "isbf_v2.schedule_name")}}
                @type="input"
                @validation="required"
                as |field|
              >
                <field.Control maxlength="120" />
              </collection.Field>
              <collection.Field
                @name="schedule_kind"
                @title={{i18n (themePrefix "isbf_v2.schedule_type")}}
                @type="select"
                as |field|
              >
                <field.Control as |select|>
                  <select.Option @value="event">{{i18n
                      (themePrefix "isbf_v2.schedule_event")
                    }}</select.Option>
                  <select.Option @value="deadline">{{i18n
                      (themePrefix "isbf_v2.schedule_standalone_deadline")
                    }}</select.Option>
                </field.Control>
              </collection.Field>
              <collection.Field
                @name="all_day"
                @title={{i18n (themePrefix "isbf_v2.schedule_date_only")}}
                @type="checkbox"
                as |field|
              >
                <field.Control />
              </collection.Field>
              <collection.Field
                @name="start"
                @title={{i18n
                  (themePrefix
                    (if
                      (eq item.schedule_kind "deadline")
                      "isbf_v2.schedule_due"
                      "isbf_v2.schedule_start"
                    )
                  )
                }}
                @type={{if item.all_day "input-date" "input-datetime-local"}}
                @validation="required"
                as |field|
              >
                <field.Control />
              </collection.Field>
              {{#if (eq item.schedule_kind "event")}}
                <collection.Field
                  @name="end"
                  @title={{i18n (themePrefix "isbf_v2.schedule_end_optional")}}
                  @type={{if item.all_day "input-date" "input-datetime-local"}}
                  as |field|
                >
                  <field.Control />
                </collection.Field>
                <collection.Field
                  @name="location"
                  @title={{i18n (themePrefix "isbf_v2.schedule_location")}}
                  @type="input"
                  as |field|
                >
                  <field.Control maxlength="255" />
                </collection.Field>
                <collection.Field
                  @name="organizer"
                  @title={{i18n (themePrefix "isbf_v2.schedule_organizer")}}
                  @type="input"
                  as |field|
                >
                  <field.Control maxlength="120" />
                </collection.Field>
                <collection.Field
                  @name="has_registration_deadline"
                  @title={{i18n
                    (themePrefix "isbf_v2.schedule_has_registration_deadline")
                  }}
                  @type="checkbox"
                  as |field|
                >
                  <field.Control />
                </collection.Field>
                {{#if item.has_registration_deadline}}
                  <collection.Object
                    @name="registration_deadline"
                    as |registration deadline|
                  >
                    <registration.Field
                      @name="all_day"
                      @title={{i18n
                        (themePrefix "isbf_v2.schedule_registration_date_only")
                      }}
                      @type="checkbox"
                      as |field|
                    >
                      <field.Control />
                    </registration.Field>
                    <registration.Field
                      @name="start"
                      @title={{i18n
                        (themePrefix "isbf_v2.schedule_registration_deadline")
                      }}
                      @type={{if
                        deadline.all_day
                        "input-date"
                        "input-datetime-local"
                      }}
                      @validation="required"
                      as |field|
                    >
                      <field.Control />
                    </registration.Field>
                  </collection.Object>
                {{/if}}
              {{/if}}
              <DButton
                @action={{fn this.removeItem index}}
                @label={{themePrefix "isbf_v2.schedule_remove_item"}}
              />
            </div>
          </form.Collection>
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
          <form.Submit @label={{themePrefix "isbf_v2.schedule_save_items"}} />
        </Form>
      </:body>
    </DModal>
  </template>
}
