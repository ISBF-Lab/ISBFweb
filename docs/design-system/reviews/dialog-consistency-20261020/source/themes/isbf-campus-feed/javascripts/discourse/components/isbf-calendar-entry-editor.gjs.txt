import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dUniqueId from "discourse/ui-kit/helpers/d-unique-id";
import { i18n } from "discourse-i18n";

export default class ISBFCalendarEntryEditor extends Component {
  @tracked error = false;
  @tracked saving = false;

  formId = dUniqueId();

  #formApi;

  @cached
  get formData() {
    const entry = this.args.model.entry;
    const selectedDate = this.args.model.selectedDate;
    return {
      title: entry?.title || "",
      note: entry?.note || "",
      allDay: entry?.all_day || false,
      start: entry
        ? entry.all_day
          ? entry.starts_at.slice(0, 10)
          : this.#localInput(entry.starts_at)
        : `${selectedDate}T09:00`,
      end: entry
        ? entry.all_day
          ? new Date(new Date(entry.ends_at).getTime() - 86400000)
              .toISOString()
              .slice(0, 10)
          : this.#localInput(entry.ends_at)
        : `${selectedDate}T10:00`,
    };
  }

  @action
  beforeClose() {
    return !this.saving;
  }

  @action
  async formChanged(name, value) {
    if (name === "allDay") {
      const start = this.#formApi.get("start").slice(0, 10);
      const end = this.#formApi.get("end").slice(0, 10);
      await this.#formApi.set("start", value ? start : `${start}T09:00`);
      await this.#formApi.set("end", value ? end : `${end}T10:00`);
    }
  }

  @action
  registerForm(api) {
    this.#formApi = api;
  }

  @action
  async save(data) {
    if (this.saving) {
      return;
    }
    this.error = false;
    let startsAt;
    let endsAt;
    try {
      startsAt = data.allDay
        ? `${data.start}T00:00:00.000Z`
        : new Date(data.start).toISOString();
      endsAt = data.allDay
        ? new Date(
            new Date(`${data.end}T00:00:00.000Z`).getTime() + 86400000
          ).toISOString()
        : new Date(data.end).toISOString();
      if (!data.title.trim() || endsAt <= startsAt) {
        this.error = true;
        return;
      }
    } catch {
      this.error = true;
      return;
    }

    this.saving = true;
    const entry = this.args.model.entry;
    try {
      await ajax(
        entry ? `/isbf/api/entries/${entry.id}.json` : "/isbf/api/entries.json",
        {
          type: entry ? "PATCH" : "POST",
          data: {
            entry: {
              title: data.title.trim(),
              note: data.note.trim(),
              starts_at: startsAt,
              ends_at: endsAt,
              all_day: data.allDay,
            },
          },
        }
      );
      if (!this.isDestroying) {
        this.args.closeModal();
        await this.args.model.onSaved();
      }
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.saving = false;
      }
    }
  }

  #localInput(value) {
    const date = new Date(value);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}T${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
  }

  <template>
    <DModal
      class="isbf-calendar-entry-editor"
      ...attributes
      @beforeClose={{this.beforeClose}}
      @closeModal={{@closeModal}}
      @dismissable={{not this.saving}}
      @title={{i18n (themePrefix "isbf_v2.calendar_personal")}}
    >
      <:body>
        <Form
          id={{this.formId}}
          @data={{this.formData}}
          @onRegisterApi={{this.registerForm}}
          @onSet={{this.formChanged}}
          @onSubmit={{this.save}}
          as |form data|
        >
          <form.Field
            @disabled={{this.saving}}
            @format="full"
            @name="title"
            @title={{i18n (themePrefix "isbf_v2.calendar_title")}}
            @type="input-text"
            @validation="required"
            as |field|
          >
            <field.Control maxlength="120" />
          </form.Field>
          <form.Field
            @disabled={{this.saving}}
            @format="full"
            @name="allDay"
            @title={{i18n (themePrefix "isbf_v2.calendar_all_day")}}
            @type="checkbox"
            as |field|
          >
            <field.Control />
          </form.Field>
          <form.Field
            @disabled={{this.saving}}
            @format="full"
            @name="start"
            @title={{i18n (themePrefix "isbf_v2.calendar_start")}}
            @type={{if data.allDay "input-date" "input-datetime-local"}}
            @validation="required"
            as |field|
          >
            <field.Control />
          </form.Field>
          <form.Field
            @disabled={{this.saving}}
            @format="full"
            @name="end"
            @title={{i18n (themePrefix "isbf_v2.calendar_end")}}
            @type={{if data.allDay "input-date" "input-datetime-local"}}
            @validation="required"
            as |field|
          >
            <field.Control />
          </form.Field>
          <form.Field
            @disabled={{this.saving}}
            @format="full"
            @name="note"
            @title={{i18n (themePrefix "isbf_v2.calendar_note")}}
            @type="textarea"
            as |field|
          >
            <field.Control maxlength="2000" rows="3" />
          </form.Field>
          {{#if this.error}}
            <form.Alert @type="error">{{i18n
                (themePrefix "isbf_v2.calendar_save_error")
              }}</form.Alert>
          {{/if}}
        </Form>
      </:body>
      <:footer>
        <DButton
          class="btn-primary"
          @disabled={{this.saving}}
          @form={{this.formId}}
          @label={{themePrefix "isbf_v2.calendar_save"}}
          @type="submit"
        />
        <DButton
          class="btn-default"
          @action={{@closeModal}}
          @disabled={{this.saving}}
          @label={{themePrefix "isbf_v2.calendar_cancel"}}
        />
      </:footer>
    </DModal>
  </template>
}
