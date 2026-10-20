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
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFResourceDirectoryDialog extends Component {
  static {
    g(this.prototype, "error", [tracked], function () {
      return null;
    });
  }
  #error = (i(this, "error"), void 0);
  static {
    g(this.prototype, "grade", [tracked]);
  }
  #grade = (i(this, "grade"), void 0);
  static {
    g(this.prototype, "name", [tracked], function () {
      return "";
    });
  }
  #name = (i(this, "name"), void 0);
  static {
    g(this.prototype, "saving", [tracked], function () {
      return false;
    });
  }
  #saving = (i(this, "saving"), void 0);
  formData = {
    name: "",
    grade: this.args.grade
  };
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
    return this.args.library ? `/isbf/library/${this.args.kind === "category" ? "categories" : "groups"}` : "/isbf/learning/courses";
  }
  get title() {
    return i18n(themePrefix(this.args.library ? `isbf_v2.library_${this.args.request ? "request" : "add"}_${this.args.kind}` : this.args.request ? "isbf_v2.learning_request_course" : "isbf_v2.learning_add_course"));
  }
  get submitLabel() {
    return i18n(themePrefix(this.args.request ? "isbf_v2.learning_submit_request" : "isbf_v2.learning_save"));
  }
  get saveDisabled() {
    const length = [...this.name.trim()].length;
    return this.saving || !length || length > 80 || this.args.library && this.args.kind === "group" && !this.grade;
  }
  formChanged(name, value) {
    if (name === "name") {
      this.name = value;
    } else if (name === "grade") {
      this.grade = value;
    }
  }
  static {
    n(this.prototype, "formChanged", [action]);
  }
  close() {
    if (this.saving) {
      return;
    }
    this.#closed = true;
    this.args.onClose();
  }
  static {
    n(this.prototype, "close", [action]);
  }
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
          ...(this.args.library ? this.args.kind === "group" ? {
            category_id: this.grade
          } : {} : {
            grade: this.grade
          })
        }
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (!this.args.request && !this.args.library && response?.course?.id && response.success === undefined && response.pending === undefined) {
        response = {
          ...response,
          success: true,
          pending: false
        };
      }
      if (response?.success !== true || typeof response.pending !== "boolean" || (response.pending ? !response.reviewable_id : !(this.args.library ? response[this.args.kind]?.id : response.course?.id))) {
        throw new Error("Unexpected learning course response");
      }
      this.#closed = true;
      this.args.onSubmitted(response, this.args.library && this.args.kind === "category" && !response.pending ? response.category.id : this.grade);
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.error = error?.jqXHR?.responseJSON?.errors?.[0] || i18n(themePrefix(this.args.library ? "isbf_v2.library_directory_error" : "isbf_v2.learning_course_save_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.saving = false;
      }
    }
  }
  static {
    n(this.prototype, "save", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
                  @library
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
          {{#unless @library}}
            <form.Field
              @disabled={{this.saving}}
              @format="full"
              @name="grade"
              @title={{i18n (themePrefix "isbf_v2.learning_grade")}}
              @type="custom"
              as |field|
            >
              <field.Control>
                <ISBFResourceParentPicker
                  @disabled={{this.saving}}
                  @grades={{@grades}}
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
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-learning-course-dialog\"],[17,1]],[[\"@closeModal\",\"@dismissable\",\"@title\"],[[30,0,[\"close\"]],[28,[32,1],[[30,0,[\"saving\"]]],null],[30,0,[\"title\"]]]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[8,[32,2],[[16,1,[30,0,[\"formId\"]]]],[[\"@data\",\"@onSet\",\"@onSubmit\"],[[30,0,[\"formData\"]],[30,0,[\"formChanged\"]],[30,0,[\"save\"]]]],[[\"default\"],[[[[1,\"\\n      \"],[8,[30,2,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\",\"@validation\"],[[30,0,[\"saving\"]],\"full\",\"name\",[28,[32,3],[[28,[32,4],[[52,[30,3],\"isbf_v2.library_directory_name\",\"isbf_v2.learning_course_name\"]],null]],null],\"input-text\",\"required\"]],[[\"default\"],[[[[1,\"\\n        \"],[8,[30,4,[\"Control\"]],[[24,\"maxlength\",\"80\"]],null,null],[1,\"\\n      \"]],[4]]]]],[1,\"\\n\"],[41,[51,[30,3]],[[[1,\"        \"],[8,[30,2,[\"Field\"]],null,[[\"@disabled\",\"@format\",\"@name\",\"@title\",\"@type\"],[[30,0,[\"saving\"]],\"full\",\"grade\",[28,[32,3],[[28,[32,4],[\"isbf_v2.learning_grade\"],null]],null],\"custom\"]],[[\"default\"],[[[[1,\"\\n          \"],[8,[30,5,[\"Control\"]],null,null,[[\"default\"],[[[[1,\"\\n            \"],[8,[32,5],null,[[\"@disabled\",\"@grades\",\"@onChange\",\"@value\"],[[30,0,[\"saving\"]],[30,6],[30,5,[\"set\"]],[30,5,[\"value\"]]]],null],[1,\"\\n          \"]],[]]]]],[1,\"\\n        \"]],[5]]]]],[1,\"\\n\"]],[]],null],[41,[30,0,[\"error\"]],[[[1,\"        \"],[8,[30,2,[\"Alert\"]],null,[[\"@type\"],[\"error\"]],[[\"default\"],[[[[1,[30,0,[\"error\"]]]],[]]]]],[1,\"\\n\"]],[]],null],[1,\"    \"]],[2]]]]],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,6],[[24,0,\"btn-primary\"]],[[\"@disabled\",\"@form\",\"@translatedLabel\",\"@type\"],[[30,0,[\"saveDisabled\"]],[30,0,[\"formId\"]],[30,0,[\"submitLabel\"]],\"submit\"]],null],[1,\"\\n    \"],[8,[32,6],[[24,0,\"btn-default\"]],[[\"@action\",\"@disabled\",\"@translatedLabel\"],[[30,0,[\"close\"]],[30,0,[\"saving\"]],[28,[32,3],[[28,[32,4],[\"isbf_v2.compose_cancel\"],null]],null]]],null],[1,\"\\n  \"]],[]]]]]],[\"&attrs\",\"form\",\"@library\",\"field\",\"field\",\"@grades\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DModal,
        not,
        Form,
        i18n,
        themePrefix,
        ISBFResourceParentPicker,
        DButton
      }),
      "isStrictMode": true
    }), this);
  }
}