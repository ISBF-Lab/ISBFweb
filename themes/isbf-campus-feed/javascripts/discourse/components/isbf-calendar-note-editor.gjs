import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFCalendarNoteEditor extends Component {
  @tracked error = false;

  @cached
  get formData() {
    return { note: this.args.model.entry.note || "" };
  }

  @action
  async save(data) {
    this.error = false;
    try {
      const { entry } = await ajax(
        `/isbf/api/entries/${this.args.model.entry.id}.json`,
        {
          type: "PATCH",
          data: { entry: { note: data.note } },
        }
      );
      this.args.model.onChanged(entry);
      this.args.closeModal();
    } catch {
      this.error = true;
    }
  }

  <template>
    <DModal
      class="isbf-calendar-note-editor"
      @closeModal={{@closeModal}}
      @title={{i18n (themePrefix "isbf_v2.schedule_edit_note")}}
    >
      <:body>
        <p>{{@model.entry.title}}</p>
        <Form @data={{this.formData}} @onSubmit={{this.save}} as |form|>
          <form.Field
            @name="note"
            @title={{i18n (themePrefix "isbf_v2.calendar_note")}}
            @type="textarea"
            as |field|
          >
            <field.Control maxlength="2000" rows="4" />
          </form.Field>
          {{#if this.error}}
            <p class="isbf-calendar-note-editor__error" role="alert">{{i18n
                (themePrefix "isbf_v2.schedule_note_error")
              }}</p>
          {{/if}}
          <form.Submit @label={{themePrefix "isbf_v2.calendar_save"}} />
        </Form>
      </:body>
    </DModal>
  </template>
}
