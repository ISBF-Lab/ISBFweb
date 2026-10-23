import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dUniqueId from "discourse/ui-kit/helpers/d-unique-id";
import { i18n } from "discourse-i18n";
import ISBFResourceParentPicker from "./isbf-resource-parent-picker";

export default class ISBFResourceDirectoryDialog extends Component {
  @tracked error = null;
  @tracked grade;
  @tracked name = "";
  @tracked saving = false;

  formData = { name: "", grade: this.args.grade };
  formId = dUniqueId();

  #closed = false;

  constructor() {
    super(...arguments);
    this.grade = this.args.grade;
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get endpoint() {
    return this.args.library
      ? `/isbf/library/${this.args.kind === "category" ? "categories" : "groups"}`
      : `/isbf/learning/${this.isCategory ? "grades" : "courses"}`;
  }

  get isCategory() {
    return this.args.kind === "category";
  }

  get title() {
    return i18n(
      themePrefix(
        this.isCategory
          ? "isbf_v2.library_add_category"
          : this.args.request
            ? "isbf_v2.learning_request_course"
            : "isbf_v2.learning_add_course"
      )
    );
  }

  get submitLabel() {
    return i18n(
      themePrefix(
        this.args.request
          ? "isbf_v2.learning_submit_request"
          : "isbf_v2.learning_save"
      )
    );
  }

  get saveDisabled() {
    const length = [...this.name.trim()].length;
    return (
      this.saving || !length || length > 80 || (!this.isCategory && !this.grade)
    );
  }

  @action
  formChanged(name, value) {
    if (this.saving) {
      return;
    }
    if (name === "name") {
      this.name = value;
    } else if (name === "grade") {
      this.grade = value;
    }
  }

  @action
  close() {
    if (this.saving) {
      return;
    }
    this.#closed = true;
    this.args.onClose();
  }

  @action
  async save() {
    if (this.#closed || this.saveDisabled) {
      return;
    }
    this.error = null;
    this.saving = true;
    try {
      let response = await ajax(this.endpoint, {
        type: "POST",
        data: {
          name: this.name.trim(),
          ...(this.isCategory
            ? {}
            : this.args.library
              ? this.args.kind === "group"
                ? { category_id: this.grade }
                : {}
              : { grade: this.grade }),
        },
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (
        !this.args.request &&
        !this.args.library &&
        !this.isCategory &&
        response?.course?.id &&
        response.success === undefined &&
        response.pending === undefined
      ) {
        response = { ...response, success: true, pending: false };
      }
      if (
        response?.success !== true ||
        typeof response.pending !== "boolean" ||
        (response.pending
          ? !response.reviewable_id
          : !(this.args.library
              ? response[this.args.kind]?.id
              : this.isCategory
                ? response.grade?.id
                : response.course?.id))
      ) {
        throw new Error("Unexpected learning course response");
      }
      this.#closed = true;
      this.args.onSubmitted(
        response,
        this.isCategory && !response.pending
          ? this.args.library
            ? response.category.id
            : response.grade.id
          : this.grade
      );
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.error =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          i18n(
            themePrefix(
              this.args.library
                ? "isbf_v2.library_directory_error"
                : "isbf_v2.learning_course_save_error"
            )
          );
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.saving = false;
      }
    }
  }

  <template>
    <DModal
      class="isbf-learning-course-dialog"
      ...attributes
      @closeModal={{this.close}}
      @dismissable={{not this.saving}}
      @title={{this.title}}
    >
      <:body>
        <Form
          id={{this.formId}}
          @data={{this.formData}}
          @onSet={{this.formChanged}}
          @onSubmit={{this.save}}
          as |form|
        >
          <form.Field
            @disabled={{this.saving}}
            @format="full"
            @name="name"
            @title={{i18n
              (themePrefix
                (if
                  this.isCategory
                  "isbf_v2.library_directory_name"
                  "isbf_v2.learning_course_name"
                )
              )
            }}
            @type="input-text"
            @validation="required"
            as |field|
          >
            <field.Control maxlength="80" />
          </form.Field>
          {{#unless this.isCategory}}
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="grade"
              @title={{i18n (themePrefix "isbf_v2.library_category")}}
              @type="custom"
              as |field|
            >
              <field.Control>
                <ISBFResourceParentPicker
                  @disabled={{this.saving}}
                  @grades={{@grades}}
                  @inline={{true}}
                  @label={{i18n (themePrefix "isbf_v2.library_category")}}
                  @onChange={{field.set}}
                  @value={{field.value}}
                />
              </field.Control>
            </form.Field>
          {{/unless}}
          {{#if this.error}}
            <form.Alert @type="error">{{this.error}}</form.Alert>
          {{/if}}
        </Form>
      </:body>
      <:footer>
        <DButton
          class="btn-primary"
          @disabled={{this.saveDisabled}}
          @form={{this.formId}}
          @translatedLabel={{this.submitLabel}}
          @type="submit"
        />
        <DButton
          class="btn-default"
          @action={{this.close}}
          @disabled={{this.saving}}
          @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
        />
      </:footer>
    </DModal>
  </template>
}
