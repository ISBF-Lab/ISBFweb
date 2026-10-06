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
  calendarItemFromEditor,
} from "../lib/official-calendar";

export default class ISBFOfficialCalendarEditor extends Component {
  @service site;

  @tracked error = false;
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
    this._itemCount = data.items.length;
    this.error = false;
    const match = name.match(/^items\.(\d+)\.all_day$/);
    if (match) {
      const item = data.items[Number(match[1])];
      for (const field of ["start", "end"]) {
        if (item[field]) {
          this.#formApi.set(
            `items.${match[1]}.${field}`,
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
      items = data.items.map(calendarItemFromEditor);
    } catch {
      this.error = true;
      return;
    }
    this.args.model.onSave(items);
    this.args.closeModal();
  }

  <template>
    <DModal
      class="isbf-official-calendar-editor"
      @closeModal={{@closeModal}}
      @title={{themePrefix "isbf_v2.schedule_editor_title"}}
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
                      (themePrefix "isbf_v2.schedule_deadline")
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
            >{{i18n (themePrefix "isbf_v2.schedule_invalid_time")}}</p>{{/if}}
          <form.Submit @label={{themePrefix "isbf_v2.schedule_save_items"}} />
        </Form>
      </:body>
    </DModal>
  </template>
}
