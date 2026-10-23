import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFLearningDirectoryDeletion extends Component {
  @service currentUser;

  @tracked error;
  @tracked loading = false;
  @tracked plan;
  @tracked saving = false;
  @tracked step = 1;

  #closed = false;
  #requesting = false;

  constructor() {
    super(...arguments);
    this.loadPlan();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get canManage() {
    return Boolean(
      this.currentUser &&
      (get(this.currentUser, "admin") ||
        get(this.currentUser, "academy_moderator_permissions.manage_resources"))
    );
  }

  get endpoint() {
    return `/isbf/${this.args.library ? "library" : "learning"}/${this.args.library ? (this.args.kind === "grade" ? "categories" : "groups") : this.args.kind === "grade" ? "grades" : "courses"}/${encodeURIComponent(this.args.entry.id)}`;
  }

  get title() {
    return i18n(
      themePrefix(
        this.args.library
          ? this.args.kind === "grade"
            ? "isbf_v2.library_delete_category"
            : "isbf_v2.library_delete_group"
          : this.args.kind === "grade"
            ? "isbf_v2.learning_delete_grade"
            : "isbf_v2.learning_delete_course"
      )
    );
  }

  get message() {
    return i18n(
      themePrefix(
        `isbf_v2.${this.args.library ? "library" : "learning"}_delete_step_${this.step}`
      ),
      {
        name: this.plan.name,
        courses: this.plan.course_count,
        resources: this.plan.resource_count,
      }
    );
  }

  get warning() {
    return i18n(
      themePrefix(
        this.args.library
          ? this.args.kind === "grade"
            ? "isbf_v2.library_delete_category_warning"
            : "isbf_v2.library_delete_group_warning"
          : this.args.kind === "grade"
            ? "isbf_v2.learning_delete_grade_warning"
            : "isbf_v2.learning_delete_course_warning"
      )
    );
  }

  get confirmLabel() {
    return i18n(
      themePrefix(
        this.step === this.plan?.required_confirmations
          ? "isbf_v2.learning_confirm_delete"
          : "isbf_v2.learning_delete_continue"
      )
    );
  }

  @action
  close() {
    if (!this.saving) {
      this.#closed = true;
      this.args.onClose();
    }
  }

  @action
  async loadPlan() {
    if (this.#closed || this.#requesting || !this.canManage) {
      return;
    }
    this.#requesting = true;
    this.loading = true;
    this.plan = null;
    this.step = 1;
    try {
      const plan = await ajax(`${this.endpoint}/deletion-plan`);
      if (
        ![2, 3].includes(plan.required_confirmations) ||
        !plan.confirmation_token
      ) {
        throw new Error("Unexpected deletion plan");
      }
      if (!this.#closed) {
        this.plan = plan;
      }
    } catch {
      if (!this.#closed) {
        this.error = i18n(
          themePrefix("isbf_v2.learning_directory_delete_load_error")
        );
      }
    } finally {
      this.#requesting = false;
      if (!this.#closed) {
        this.loading = false;
      }
    }
  }

  @action
  async confirm() {
    if (this.#closed || this.saving || !this.plan || !this.canManage) {
      return;
    }
    if (this.step < this.plan.required_confirmations) {
      this.step++;
      return;
    }
    this.saving = true;
    this.error = null;
    try {
      const result = await ajax(this.endpoint, {
        type: "DELETE",
        data: {
          confirmation_token: this.plan.confirmation_token,
          confirmation_count: this.step,
          cascade: this.plan.has_children,
        },
      });
      if (result.success !== true) {
        throw new Error("Unexpected directory deletion response");
      }
      if (!this.#closed) {
        this.#closed = true;
        this.args.onDeleted(result);
      }
    } catch (error) {
      if (!this.#closed) {
        this.error =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          error?.responseJSON?.errors?.[0] ||
          i18n(themePrefix("isbf_v2.learning_directory_delete_error"));
        await this.loadPlan();
      }
    } finally {
      if (!this.#closed) {
        this.saving = false;
      }
    }
  }

  <template>
    <DModal
      class="isbf-learning-share-dialog isbf-learning-directory-deletion"
      @closeModal={{this.close}}
      @inline={{true}}
      @submitOnEnter={{false}}
      @title={{this.title}}
    >
      <:body>
        {{#if this.error}}<p role="alert">{{this.error}}</p>{{/if}}
        {{#if this.loading}}<p role="status">{{i18n
              (themePrefix "isbf_v2.learning_loading")
            }}</p>{{/if}}
        {{#if this.plan}}
          <p aria-live="polite">{{this.message}}</p>
          {{#if (eq this.step 3)}}
            <p><strong
                class="isbf-learning-directory-deletion__warning"
              >{{this.warning}}</strong></p>
          {{/if}}
        {{/if}}
        <div
          class="isbf-learning-share-dialog__actions isbf-learning-directory-deletion__actions"
        >
          <DButton
            @action={{this.close}}
            @disabled={{this.saving}}
            @translatedLabel={{i18n
              (themePrefix "isbf_v2.learning_delete_back")
            }}
          />
          {{#if this.plan}}
            <DButton
              class="btn-danger isbf-learning-directory-deletion__confirm"
              @action={{this.confirm}}
              @disabled={{if this.canManage this.saving true}}
              @translatedLabel={{this.confirmLabel}}
            />
          {{else}}
            <DButton
              @action={{this.loadPlan}}
              @disabled={{this.loading}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.learning_retry")}}
            />
          {{/if}}
        </div>
      </:body>
    </DModal>
  </template>
}
