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
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFCalendarEntryEditor extends Component {
  static {
    g(this.prototype, "error", [tracked], function () {
      return false;
    });
  }
  #error = (i(this, "error"), void 0);
  static {
    g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (i(this, "saving"), void 0);
  formId = dUniqueId();
  #formApi;
  get formData() {
    const entry = this.args.model.entry;
    const selectedDate = this.args.model.selectedDate;
    return {
      title: entry?.title || "",
      note: entry?.note || "",
      allDay: entry?.all_day || false,
      start: entry ? entry.all_day ? entry.starts_at.slice(0, 10) : this.#localInput(entry.starts_at) : `${selectedDate}T09:00`,
      end: entry ? entry.all_day ? new Date(new Date(entry.ends_at).getTime() - 86400000).toISOString().slice(0, 10) : this.#localInput(entry.ends_at) : `${selectedDate}T10:00`
    };
  }
  static {
    n(this.prototype, "formData", [cached]);
  }
  beforeClose() {
    return !this.saving;
  }
  static {
    n(this.prototype, "beforeClose", [action]);
  }
  async formChanged(name, value) {
    if (name === "allDay") {
      const start = this.#formApi.get("start").slice(0, 10);
      const end = this.#formApi.get("end").slice(0, 10);
      await this.#formApi.set("start", value ? start : `${start}T09:00`);
      await this.#formApi.set("end", value ? end : `${end}T10:00`);
    }
  }
  static {
    n(this.prototype, "formChanged", [action]);
  }
  registerForm(api) {
    this.#formApi = api;
  }
  static {
    n(this.prototype, "registerForm", [action]);
  }
  async save(data) {
    if (this.saving) {
      return;
    }
    this.error = false;
    let startsAt;
    let endsAt;
    try {
      startsAt = data.allDay ? `${data.start}T00:00:00.000Z` : new Date(data.start).toISOString();
      endsAt = data.allDay ? new Date(new Date(`${data.end}T00:00:00.000Z`).getTime() + 86400000).toISOString() : new Date(data.end).toISOString();
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
      await ajax(entry ? `/isbf/api/entries/${entry.id}.json` : "/isbf/api/entries.json", {
        type: entry ? "PATCH" : "POST",
        data: {
          entry: {
            title: data.title.trim(),
            note: data.note.trim(),
            starts_at: startsAt,
            ends_at: endsAt,
            all_day: data.allDay
          }
        }
      });
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
  static {
    n(this.prototype, "save", [action]);
  }
  #localInput(value) {
    const date = new Date(value);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}T${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-calendar-entry-editor\"],[17,1]],[[\"@beforeClose\",\"@closeModal\",\"@dismissable\",\"@title\"],[[30,0,[\"beforeClose\"]],[30,2],[28,[32,1],[[30,0,[\"saving\"]]],null],[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_personal\"],null]],null]]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[8,[32,4],[[16,1,[30,0,[\"formId\"]]]],[[\"@data\",\"@onRegisterApi\",\"@onSet\",\"@onSubmit\"],[[30,0,[\"formData\"]],[30,0,[\"registerForm\"]],[30,0,[\"formChanged\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"title\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_title\"],null]],null],\"input-text\",\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,5,[\"Control\"]],[[24,\"maxlength\",\"120\"]],null,null],[1,\"\\n      \"]],[5]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\"],[[30,0,[\"saving\"]],\"full\",\"allDay\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_all_day\"],null]],null],\"checkbox\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,6,[\"Control\"]],null,null,null],[1,\"\\n      \"]],[6]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"start\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_start\"],null]],null],[52,[30,4,[\"allDay\"]],\"input-date\",\"input-datetime-local\"],\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,7,[\"Control\"]],null,null,null],[1,\"\\n      \"]],[7]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"end\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_end\"],null]],null],[52,[30,4,[\"allDay\"]],\"input-date\",\"input-datetime-local\"],\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,8,[\"Control\"]],null,null,null],[1,\"\\n      \"]],[8]]]]],[1,\"\\n      \"],[8,[30,3,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\"],[[30,0,[\"saving\"]],\"full\",\"note\",[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_note\"],null]],null],\"textarea\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,9,[\"Control\"]],[[24,\"maxlength\",\"2000\"],[24,\"rows\",\"3\"]],null,null],[1,\"\\n      \"]],[9]]]]],[1,\"\\n\"],[41,[30,0,[\"error\"]],[[[1,\"        \"],[8,[30,3,[\"Alert\"]],null,[[\"@type\"],[\"error\"]],[[\"default\"],[[[[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.calendar_save_error\"],null]],null]]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"    \"]],[3,4]]]]],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,5],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@form\",\"@label\",\"@type\"],[[30,0,[\"saving\"]],[30,0,[\"formId\"]],[28,[32,3],[\"isbf_v2.calendar_save\"],null],\"submit\"]],null],[1,\"\\n    \"],[8,[32,5],[[24,0,\"btn-default\"]],[[\"@action\",\"@disabled\",\"@label\"],[[30,2],[30,0,[\"saving\"]],[28,[32,3],[\"isbf_v2.calendar_cancel\"],null]]],null],[1,\"\\n  \"]],[]]]]]],[\"&attrs\",\"@closeModal\",\"form\",\"data\",\"field\",\"field\",\"field\",\"field\",\"field\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        not,
        i18n,
        themePrefix,
        Form,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}