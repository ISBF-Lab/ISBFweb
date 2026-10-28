import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import Form from "discourse/components/form";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class AcademyStudentGroupForm extends Component {
  @tracked error;
  data = {
    mode: "graduation",
    input_kind: "list",
    student_numbers: "",
    prefix: "",
    file: null,
  };

  @action
  async changed(value, { name, set }) {
    await set(name, value);
    this.error = null;
    this.args.onInvalidate();
  }

  @action
  async selectFile(set, event) {
    await set(event.target.files?.[0] ?? null);
    this.error = null;
    this.args.onInvalidate();
  }

  @action
  submit(data) {
    this.error = null;
    if (
      data.input_kind === "csv" &&
      (!data.file ||
        !/\.csv$/i.test(data.file.name) ||
        data.file.size > this.args.options.max_bytes)
    ) {
      this.error = i18n("academy_roles.student_groups.invalid_file");
      return;
    }
    if (
      data.input_kind === "list" &&
      (!data.student_numbers.trim() ||
        data.student_numbers.trim().split(/[\s,，;；]+/).length >
          this.args.options.max_rows)
    ) {
      this.error = i18n("academy_roles.student_groups.invalid_list");
      return;
    }
    if (data.input_kind === "prefix" && !data.prefix.trim()) {
      this.error = i18n("academy_roles.student_groups.invalid_prefix");
      return;
    }
    if (data.mode === "graduation" && !this.args.options.alumni_group_id) {
      this.error =
        this.args.options.alumni_error ||
        i18n("academy_roles.student_groups.alumni_unavailable");
      return;
    }
    const payload = new FormData();
    for (const key of ["mode", "input_kind", "student_numbers", "prefix"]) {
      payload.append(key, data[key] || "");
    }
    if (data.input_kind === "csv") {
      payload.append("file", data.file);
    }
    for (const operation of ["add", "remove"]) {
      for (const group of this.args.options.groups) {
        if (
          data[`${operation}_${group.id}`] &&
          (data.mode === "groups" || operation === "remove")
        ) {
          if (
            data.mode === "graduation" &&
            group.id === this.args.options.alumni_group_id
          ) {
            continue;
          }
          payload.append(`${operation}_group_ids[]`, group.id);
        }
      }
    }
    return this.args.onPreview(payload);
  }

  <template>
    <div class="academy-student-group-form">
      <p>{{i18n "academy_roles.student_groups.limits"}}</p>
      {{#if this.error}}<p
          class="alert alert-error"
          role="alert"
        >{{this.error}}</p>{{/if}}
      <Form @data={{this.data}} @onSubmit={{this.submit}} as |form draft|>
        <form.Field
          @disabled={{@busy}}
          @name="mode"
          @onSet={{this.changed}}
          @title={{i18n "academy_roles.student_groups.mode"}}
          @type="select"
          as |field|
        >
          <field.Control @includeNone={{false}} as |select|>
            <select.Option @value="graduation">{{i18n
                "academy_roles.student_groups.graduation"
              }}</select.Option>
            <select.Option @value="groups">{{i18n
                "academy_roles.student_groups.groups"
              }}</select.Option>
          </field.Control>
        </form.Field>
        {{#if (eq draft.mode "graduation")}}
          <p>{{i18n "academy_roles.student_groups.graduation_description"}}</p>
          {{#if @options.alumni_error}}<p
              class="alert alert-error"
              role="alert"
            >{{@options.alumni_error}}</p>{{/if}}
          {{#each @options.groups as |group|}}
            {{#unless (eq group.id @options.alumni_group_id)}}
              <form.Field
                @disabled={{@busy}}
                @name={{concat "remove_" group.id}}
                @onSet={{this.changed}}
                @title={{i18n
                  "academy_roles.student_groups.remove_named"
                  name=group.name
                }}
                @type="checkbox"
                as |field|
              ><field.Control /></form.Field>
            {{/unless}}
          {{/each}}
        {{else}}
          {{#each @options.groups as |group|}}
            <form.Field
              @disabled={{@busy}}
              @name={{concat "add_" group.id}}
              @onSet={{this.changed}}
              @title={{i18n
                "academy_roles.student_groups.add_named"
                name=group.name
              }}
              @type="checkbox"
              as |field|
            ><field.Control /></form.Field>
            <form.Field
              @disabled={{@busy}}
              @name={{concat "remove_" group.id}}
              @onSet={{this.changed}}
              @title={{i18n
                "academy_roles.student_groups.remove_named"
                name=group.name
              }}
              @type="checkbox"
              as |field|
            ><field.Control /></form.Field>
          {{/each}}
        {{/if}}
        <form.Field
          @disabled={{@busy}}
          @name="input_kind"
          @onSet={{this.changed}}
          @title={{i18n "academy_roles.student_groups.input_kind"}}
          @type="select"
          as |field|
        >
          <field.Control @includeNone={{false}} as |select|>
            <select.Option @value="list">{{i18n
                "academy_roles.student_groups.list"
              }}</select.Option>
            <select.Option @value="csv">{{i18n
                "academy_roles.student_groups.csv"
              }}</select.Option>
            <select.Option @value="prefix">{{i18n
                "academy_roles.student_groups.prefix"
              }}</select.Option>
          </field.Control>
        </form.Field>
        {{#if (eq draft.input_kind "list")}}
          <form.Field
            @disabled={{@busy}}
            @name="student_numbers"
            @onSet={{this.changed}}
            @title={{i18n "academy_roles.student_groups.list"}}
            @type="textarea"
            @validation="required"
            as |field|
          ><field.Control /></form.Field>
        {{else if (eq draft.input_kind "prefix")}}
          <form.Field
            @disabled={{@busy}}
            @name="prefix"
            @onSet={{this.changed}}
            @title={{i18n "academy_roles.student_groups.prefix"}}
            @type="input"
            @validation="required"
            as |field|
          ><field.Control /></form.Field>
          <p>{{i18n "academy_roles.student_groups.prefix_description"}}</p>
        {{else}}
          <form.Field
            @disabled={{@busy}}
            @name="file"
            @title={{i18n "academy_roles.student_groups.csv"}}
            @type="custom"
            @validation="required"
            as |field|
          >
            <field.Control><input
                accept=".csv,text/csv"
                aria-describedby={{field.errorId}}
                disabled={{@busy}}
                id={{field.id}}
                type="file"
                {{on "change" (fn this.selectFile field.set)}}
              /></field.Control>
          </form.Field>
        {{/if}}
        <form.Submit
          @disabled={{@busy}}
          @label="academy_roles.student_groups.preview"
        />
      </Form>
    </div>
  </template>
}
