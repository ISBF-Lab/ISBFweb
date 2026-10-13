import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ISBFLearningGradePicker from "./isbf-learning-grade-picker";

export default class ISBFLearningCourseDialog extends Component {
  @tracked error = null;
  @tracked grade;
  @tracked name = "";
  @tracked saving = false;

  #closed = false;

  constructor() {
    super(...arguments);
    this.grade = this.args.grade;
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get title() {
    return i18n(
      themePrefix(
        this.args.request
          ? "isbf_v2.learning_request_course"
          : "isbf_v2.learning_add_course",
      ),
    );
  }

  get submitLabel() {
    return i18n(
      themePrefix(
        this.args.request
          ? "isbf_v2.learning_submit_request"
          : "isbf_v2.learning_save",
      ),
    );
  }

  get saveDisabled() {
    const length = [...this.name.trim()].length;
    return this.saving || !length || length > 80;
  }

  @action
  changeGrade(id) {
    if (!this.saving) {
      this.grade = id;
    }
  }

  @action
  changeName(event) {
    this.name = event.target.value;
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
  focusName(element) {
    element.focus();
  }

  @action
  handleKeydown(event) {
    if (event.key === "Escape" && !this.saving) {
      event.stopPropagation();
      this.close();
    }
  }

  @action
  async save(event) {
    event.preventDefault();
    if (this.#closed || this.saveDisabled) {
      return;
    }
    this.error = null;
    this.saving = true;
    try {
      let response = await ajax("/isbf/learning/courses", {
        type: "POST",
        data: { name: this.name.trim(), grade: this.grade },
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      if (
        !this.args.request &&
        response?.course?.id &&
        response.success === undefined &&
        response.pending === undefined
      ) {
        response = { ...response, success: true, pending: false };
      }
      if (
        response?.success !== true ||
        typeof response.pending !== "boolean" ||
        (response.pending ? !response.reviewable_id : !response.course?.id)
      ) {
        throw new Error("Unexpected learning course response");
      }
      this.#closed = true;
      this.args.onSubmitted(response, this.grade);
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.error =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          i18n(themePrefix("isbf_v2.learning_course_save_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.saving = false;
      }
    }
  }

  <template>
    <section
      aria-label={{this.title}}
      class="isbf-learning-course-dialog"
      role="dialog"
      tabindex="-1"
      {{on "keydown" this.handleKeydown}}
    >
      <h2>{{this.title}}</h2>
      <form {{on "submit" this.save}}>
        <label>
          <span>{{i18n (themePrefix "isbf_v2.learning_course_name")}}</span>
          <input
            disabled={{this.saving}}
            maxlength="80"
            required
            type="text"
            value={{this.name}}
            {{on "input" this.changeName}}
            {{didInsert this.focusName}}
          />
        </label>
        <ISBFLearningGradePicker
          @grades={{@grades}}
          @onChange={{this.changeGrade}}
          @value={{this.grade}}
        />
        {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
        <div class="isbf-learning-course-dialog__actions">
          <DButton
            @action={{this.close}}
            @disabled={{this.saving}}
            @translatedLabel={{i18n (themePrefix "isbf_v2.compose_cancel")}}
          />
          <DButton
            class="btn-primary"
            @disabled={{this.saveDisabled}}
            @translatedLabel={{this.submitLabel}}
            @type="submit"
          />
        </div>
      </form>
    </section>
  </template>
}
