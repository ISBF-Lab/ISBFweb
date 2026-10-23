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
  titleId = dUniqueId();

  get title() {
    return i18n(
      themePrefix(
        this.args.model.entry
          ? "isbf_v2.calendar_edit"
          : "isbf_v2.calendar_add_personal"
      )
    );
  }

  @cached
  get formData() {
    const entry = this.args.model.entry;
    const selected = this.args.model.selectedDate;
    const start = entry
      ? entry.all_day
        ? entry.starts_at.slice(0, 10)
        : this.#localInput(entry.starts_at)
      : `${selected}T09:00`;
    const end = entry
      ? entry.all_day
        ? new Date(new Date(entry.ends_at).getTime() - 86400000)
            .toISOString()
            .slice(0, 10)
        : this.#localInput(entry.ends_at)
      : `${selected}T10:00`;
    return {
      title: entry?.title || "",
      location: entry?.location || "",
      note: entry?.note || "",
      allDay: entry?.all_day || false,
      startDate: start.slice(0, 10),
      startTime: start.slice(11) || "09:00",
      endDate: end.slice(0, 10),
      endTime: end.slice(11) || "10:00",
    };
  }

  @action
  beforeClose() {
    return !this.saving;
  }

  @action
  cancel() {
    if (!this.saving) {
      this.args.closeModal();
    }
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
        ? `${data.startDate}T00:00:00.000Z`
        : new Date(`${data.startDate}T${data.startTime}`).toISOString();
      endsAt = data.allDay
        ? new Date(
            new Date(`${data.endDate}T00:00:00.000Z`).getTime() + 86400000
          ).toISOString()
        : new Date(`${data.endDate}T${data.endTime}`).toISOString();
      if (
        !data.title.trim() ||
        [...data.location.trim()].length > 255 ||
        endsAt <= startsAt
      ) {
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
              location: data.location.trim(),
              note: data.note.trim(),
              starts_at: startsAt,
              ends_at: endsAt,
              all_day: data.allDay,
            },
          },
        }
      );
      if (!this.isDestroying) {
        this.saving = false;
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
      aria-labelledby={{this.titleId}}
      class="isbf-calendar-entry-editor"
      ...attributes
      @beforeClose={{this.beforeClose}}
      @closeModal={{@closeModal}}
      @dismissable={{not this.saving}}
      @hideFooter={{true}}
      @hideHeader={{true}}
    >
      <:aboveHeader>
        <header class="isbf-calendar-entry-editor__header">
          <DButton
            class="btn-flat isbf-calendar-entry-editor__cancel"
            @action={{this.cancel}}
            @disabled={{this.saving}}
            @icon="xmark"
            @title={{themePrefix "isbf_v2.calendar_cancel"}}
          />
          <h1 id={{this.titleId}}>{{this.title}}</h1>
          <DButton
            aria-label={{i18n (themePrefix "isbf_v2.calendar_save")}}
            class="btn-primary isbf-calendar-entry-editor__save"
            @disabled={{this.saving}}
            @form={{this.formId}}
            @icon="check"
            @label={{themePrefix "isbf_v2.calendar_save"}}
            @type="submit"
          />
        </header>
      </:aboveHeader>
      <:body>
        <Form
          id={{this.formId}}
          @data={{this.formData}}
          @onSubmit={{this.save}}
          as |form data|
        >
          <section class="isbf-calendar-entry-editor__group">
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="title"
              @title={{i18n (themePrefix "isbf_v2.calendar_title")}}
              @type="input-text"
              @validation="required"
              as |field|
            ><field.Control maxlength="120" /></form.Field>
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="location"
              @showOptional={{false}}
              @title={{i18n (themePrefix "isbf_v2.calendar_location")}}
              @type="input-text"
              as |field|
            ><field.Control maxlength="255" /></form.Field>
          </section>
          <section
            class="isbf-calendar-entry-editor__group isbf-calendar-entry-editor__dates"
          >
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="allDay"
              @showOptional={{false}}
              @title={{i18n (themePrefix "isbf_v2.calendar_all_day")}}
              @type="toggle"
              as |field|
            ><field.Control role="switch" /></form.Field>
            <div class="isbf-calendar-entry-editor__date-row">
              <span>{{i18n (themePrefix "isbf_v2.calendar_start")}}</span>
              <form.Field
                @disabled={{this.saving}}
                @format="full"
                @name="startDate"
                @title={{i18n (themePrefix "isbf_v2.calendar_start_date")}}
                @type="input-date"
                @validation="required"
                as |field|
              ><field.Control /></form.Field>
              {{#unless data.allDay}}<form.Field
                  @disabled={{this.saving}}
                  @format="full"
                  @name="startTime"
                  @title={{i18n (themePrefix "isbf_v2.calendar_start_time")}}
                  @type="input-time"
                  @validation="required"
                  as |field|
                ><field.Control /></form.Field>{{/unless}}
            </div>
            <div class="isbf-calendar-entry-editor__date-row">
              <span>{{i18n (themePrefix "isbf_v2.calendar_end")}}</span>
              <form.Field
                @disabled={{this.saving}}
                @format="full"
                @name="endDate"
                @title={{i18n (themePrefix "isbf_v2.calendar_end_date")}}
                @type="input-date"
                @validation="required"
                as |field|
              ><field.Control /></form.Field>
              {{#unless data.allDay}}<form.Field
                  @disabled={{this.saving}}
                  @format="full"
                  @name="endTime"
                  @title={{i18n (themePrefix "isbf_v2.calendar_end_time")}}
                  @type="input-time"
                  @validation="required"
                  as |field|
                ><field.Control /></form.Field>{{/unless}}
            </div>
          </section>
          <section class="isbf-calendar-entry-editor__group">
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="note"
              @title={{i18n (themePrefix "isbf_v2.calendar_note")}}
              @type="textarea"
              as |field|
            ><field.Control maxlength="2000" rows="3" /></form.Field>
          </section>
          {{#if this.error}}<form.Alert @type="error">{{i18n
                (themePrefix "isbf_v2.calendar_save_error")
              }}</form.Alert>{{/if}}
        </Form>
      </:body>
    </DModal>
  </template>
}
