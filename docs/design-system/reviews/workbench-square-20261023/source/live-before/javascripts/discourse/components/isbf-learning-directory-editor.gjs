import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFLearningDirectoryEditor extends Component {
  @tracked error;
  @tracked saving = false;

  data;
  #closed = false;

  constructor() {
    super(...arguments);
    this.data = {
      name: this.args.entry.name || this.args.entry.label,
      grade: this.args.library
        ? this.args.entry.category_id
        : this.args.entry.grade,
    };
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get title() {
    return i18n(
      themePrefix(
        this.args.library
          ? this.args.kind === "grade"
            ? "isbf_v2.library_edit_category"
            : "isbf_v2.library_edit_group"
          : this.args.kind === "grade"
            ? "isbf_v2.learning_edit_grade"
            : "isbf_v2.learning_edit_course"
      )
    );
  }

  @action
  close() {
    if (!this.saving) {
      this.args.onClose();
    }
  }

  @action
  async save(data) {
    if (this.saving || this.#closed) {
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      const response = await ajax(
        `/isbf/${this.args.library ? "library" : "learning"}/${this.args.library ? (this.args.kind === "grade" ? "categories" : "groups") : this.args.kind === "grade" ? "grades" : "courses"}/${encodeURIComponent(this.args.entry.id)}`,
        { type: "PUT", data }
      );
      if (response.success !== true) {
        throw new Error("Unexpected course directory response");
      }
      if (!this.#closed) {
        this.args.onSaved(
          response,
          this.args.kind === "grade"
            ? this.args.entry.id
            : this.args.library
              ? data.grade
              : Number(data.grade)
        );
      }
    } catch (error) {
      if (!this.#closed) {
        this.error =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          i18n(themePrefix("isbf_v2.learning_course_save_error"));
      }
    } finally {
      if (!this.#closed) {
        this.saving = false;
      }
    }
  }

  <template>
    <DModal
      class="isbf-learning-share-dialog isbf-learning-directory-editor"
      @closeModal={{this.close}}
      @title={{this.title}}
    >
      <:body>
        <Form @data={{this.data}} @onSubmit={{this.save}} as |form|>
          <form.Field
            @disabled={{this.saving}}
            @name="name"
            @title={{this.title}}
            @type="input"
            @validation="required"
            as |field|
          >
            <field.Control maxlength={{80}} />
          </form.Field>
          {{#unless (eq @kind "grade")}}
            <form.Field
              @disabled={{this.saving}}
              @name="grade"
              @title={{i18n
                (themePrefix
                  (if
                    @library "isbf_v2.library_category" "isbf_v2.learning_grade"
                  )
                )
              }}
              @type="select"
              @validation="required"
              as |field|
            >
              <field.Control as |select|>
                {{#each @grades as |grade|}}<select.Option
                    @value={{grade.id}}
                  >{{grade.label}}</select.Option>{{/each}}
              </field.Control>
            </form.Field>
          {{/unless}}
          {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
          <form.Actions>
            {{#if @onDelete}}
              <DButton
                class="btn-danger isbf-learning-directory-editor__delete"
                @action={{@onDelete}}
                @disabled={{this.saving}}
                @translatedLabel={{i18n
                  (themePrefix "isbf_v2.learning_confirm_delete")
                }}
              />
            {{/if}}
            <DButton
              @action={{this.close}}
              @disabled={{this.saving}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
            />
            <form.Submit
              @label={{themePrefix "isbf_v2.learning_save_changes"}}
            />
          </form.Actions>
        </Form>
      </:body>
    </DModal>
  </template>
}
