import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  learningConfig,
  learningEditableResource,
  learningResourceQuery,
} from "../lib/learning-resources";
import ISBFLearningCourseDialog from "./isbf-learning-course-dialog";
import ISBFLearningGradePicker from "./isbf-learning-grade-picker";
import ISBFLearningResource from "./isbf-learning-resource";
import ISBFLearningShareDialog from "./isbf-learning-share-dialog";

export default class ISBFLearning extends Component {
  @service appEvents;
  @service currentUser;
  @service site;

  @tracked coursePending = false;
  @tracked courses = [];
  @tracked coursesError = false;
  @tracked coursesLoading = false;
  @tracked grade = 1;
  @tracked selectedCourseId = null;
  @tracked showCourseDialog = false;
  @tracked query = "";
  @tracked resources = [];
  @tracked resourcesError = false;
  @tracked resourcesLoading = false;
  @tracked hasMore = false;
  @tracked shareContext = null;
  @tracked sharePending = false;

  #coursesRequest = 0;
  #courseTrigger;
  #page = 0;
  #resourcesRequest = 0;
  #searchTimer;
  #shareTrigger;

  constructor() {
    super(...arguments);
    if (this.config && this.currentUser) {
      this.loadCourses();
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#coursesRequest++;
    this.#resourcesRequest++;
    clearTimeout(this.#searchTimer);
  }

  get config() {
    return learningConfig(this.site);
  }

  get canManageCourses() {
    return Boolean(
      this.currentUser?.admin ||
      this.currentUser?.academy_moderator_permissions?.manage_resources
    );
  }

  get canSubmitResources() {
    if (!this.currentUser?.academy_moderator_role || this.currentUser.admin) {
      return true;
    }
    return Boolean(
      this.site.categories.find(
        (category) => category.id === this.config?.category_id
      )?.canCreateTopic
    );
  }

  get canSubmitCourses() {
    return Boolean(
      this.currentUser &&
      this.canSubmitResources &&
      (this.canManageCourses || this.config?.course_requests === true)
    );
  }

  get courseActionLabel() {
    return i18n(
      themePrefix(
        this.canManageCourses
          ? "isbf_v2.learning_add_course"
          : "isbf_v2.learning_request_course"
      )
    );
  }

  get courseItems() {
    return this.courses
      .filter((course) => course.grade === this.grade)
      .map((course) => ({
        ...course,
        selected: course.id === this.selectedCourseId,
      }));
  }

  get selectedCourse() {
    return this.courses.find((course) => course.id === this.selectedCourseId);
  }

  get shareLabel() {
    return i18n(
      themePrefix(
        this.config?.resource_admin_management === true &&
          !(
            this.currentUser?.admin ||
            this.currentUser?.academy_moderator_permissions?.manage_resources
          )
          ? "isbf_v2.learning_apply_share"
          : "isbf_v2.learning_share"
      )
    );
  }

  get shareDisabled() {
    return (
      !this.selectedCourse ||
      !this.canSubmitResources ||
      this.config?.link_sharing !== true
    );
  }

  get searching() {
    return Boolean(this.query.trim());
  }

  get contentTitle() {
    return this.searching
      ? i18n(themePrefix("isbf_v2.learning_search_results"))
      : this.selectedCourse?.name ||
          i18n(themePrefix("isbf_v2.learning_select_course"));
  }

  @action
  login() {
    this.appEvents.trigger("show-login");
  }

  @action
  async loadCourses() {
    const request = ++this.#coursesRequest;
    this.coursesLoading = true;
    this.coursesError = false;
    try {
      const response = await ajax("/isbf/learning/courses");
      if (request !== this.#coursesRequest) {
        return;
      }
      this.courses = response.courses || [];
      this.#restoreCourse();
      this.#loadResources();
    } catch {
      if (request === this.#coursesRequest) {
        this.coursesError = true;
      }
    } finally {
      if (request === this.#coursesRequest) {
        this.coursesLoading = false;
      }
    }
  }

  @action
  changeGrade(id) {
    this.grade = id;
    this.#restoreCourse();
    if (!this.searching) {
      this.#loadResources();
    }
  }

  @action
  selectCourse(id) {
    this.selectedCourseId = id;
    if (!this.searching) {
      this.#loadResources();
    }
  }

  @action
  changeQuery(event) {
    this.query = event.target.value;
    clearTimeout(this.#searchTimer);
    this.#resourcesRequest++;
    this.resources = [];
    this.hasMore = false;
    this.resourcesError = false;
    this.resourcesLoading = true;
    this.#searchTimer = setTimeout(() => this.#loadResources(), 300);
  }

  @action
  clearQuery() {
    clearTimeout(this.#searchTimer);
    this.query = "";
    this.#loadResources();
  }

  @action
  retryResources() {
    this.#loadResources(this.resources.length > 0);
  }

  @action
  loadMore() {
    this.#loadResources(true);
  }

  @action
  openCourseDialog() {
    if (!this.canSubmitCourses || this.showCourseDialog) {
      return;
    }
    this.coursePending = false;
    this.#courseTrigger = document.activeElement;
    this.showCourseDialog = true;
  }

  @action
  closeCourseDialog() {
    this.showCourseDialog = false;
    this.#courseTrigger?.focus();
  }

  @action
  courseSubmitted(response, grade) {
    if (this.isDestroying || !this.showCourseDialog) {
      return;
    }
    this.closeCourseDialog();
    this.coursePending = response.pending === true;
    if (!this.coursePending) {
      this.grade = grade;
      this.loadCourses();
    }
  }

  @action
  share() {
    if (this.shareDisabled || this.shareContext) {
      return;
    }
    this.#shareTrigger = document.activeElement;
    this.sharePending = false;
    this.shareContext = {
      course: this.selectedCourse,
      selectedCourseId: this.selectedCourseId,
      query: this.query.trim(),
      coursesRequest: this.#coursesRequest,
    };
  }

  @action
  editResource(resource) {
    if (
      this.isDestroying ||
      !this.currentUser?.admin ||
      this.config?.resource_admin_management !== true ||
      this.shareContext ||
      resource?.can_delete !== true ||
      !learningEditableResource(resource) ||
      !resource.course?.id
    ) {
      return;
    }
    this.#shareTrigger = document.activeElement;
    this.sharePending = false;
    this.shareContext = {
      course: resource.course,
      resource,
      selectedCourseId: this.selectedCourseId,
      query: this.query.trim(),
      coursesRequest: this.#coursesRequest,
    };
  }

  @action
  closeShareDialog() {
    this.shareContext = null;
    this.#shareTrigger?.focus();
  }

  @action
  resourceSubmitted(response) {
    // Preserve both flags for this existing late submission callback guard.
    // eslint-disable-next-line discourse/no-redundant-destroyed-check
    if (this.isDestroying || this.isDestroyed || !this.shareContext) {
      return;
    }
    const context = this.shareContext;
    this.closeShareDialog();
    this.sharePending = response.pending === true;
    if (
      !this.sharePending &&
      (context.selectedCourseId ?? context.course.id) ===
        this.selectedCourseId &&
      context.query === this.query.trim() &&
      context.coursesRequest === this.#coursesRequest
    ) {
      clearTimeout(this.#searchTimer);
      this.#loadResources();
    }
  }

  @action
  resourceDeleted() {
    if (this.isDestroying) {
      return;
    }
    clearTimeout(this.#searchTimer);
    this.#loadResources();
  }

  #restoreCourse() {
    if (!this.courseItems.some((course) => course.selected)) {
      this.selectedCourseId = this.courseItems[0]?.id || null;
    }
  }

  async #loadResources(append = false) {
    const request = ++this.#resourcesRequest;
    const page = append ? this.#page + 1 : 0;
    this.resourcesError = false;
    if (!append) {
      this.resources = [];
      this.hasMore = false;
    }
    if (!this.searching && !this.selectedCourseId) {
      this.resourcesLoading = false;
      return;
    }
    this.resourcesLoading = true;
    try {
      const response = await ajax("/isbf/learning/resources", {
        data: learningResourceQuery(this.selectedCourseId, this.query, page),
      });
      if (request !== this.#resourcesRequest) {
        return;
      }
      const resources = response.resources || [];
      this.resources = append ? [...this.resources, ...resources] : resources;
      this.hasMore = response.has_more === true;
      this.#page = page;
    } catch {
      if (request === this.#resourcesRequest) {
        this.resourcesError = true;
      }
    } finally {
      if (request === this.#resourcesRequest) {
        this.resourcesLoading = false;
      }
    }
  }

  <template>
    <main class="isbf-learning">
      <header class="isbf-learning__header">
        <a
          aria-label={{i18n (themePrefix "isbf_v2.learning_back")}}
          class="isbf-learning__back"
          href="/isbf/workbench"
        >
          {{dIcon "arrow-left"}}
          <h1>{{i18n (themePrefix "isbf_v2.workbench_learning_resources")}}</h1>
        </a>
        {{#if this.currentUser}}
          {{#if this.config}}
            <div class="isbf-learning__search">
              <input
                aria-label={{i18n (themePrefix "isbf_v2.learning_search")}}
                placeholder={{i18n (themePrefix "isbf_v2.learning_search")}}
                type="search"
                value={{this.query}}
                {{on "input" this.changeQuery}}
              />
              {{#if this.query}}<DButton
                  class="btn-flat"
                  @action={{this.clearQuery}}
                  @icon="xmark"
                  @translatedTitle={{i18n
                    (themePrefix "isbf_v2.explore_clear")
                  }}
                />{{/if}}
            </div>
          {{/if}}
        {{/if}}
      </header>
      {{#if (not this.config)}}
        <p class="isbf-learning__notice">{{i18n
            (themePrefix "isbf_v2.learning_unavailable")
          }}</p>
      {{else if this.currentUser}}
        {{#if this.shareContext}}<ISBFLearningShareDialog
            @course={{this.shareContext.course}}
            @onClose={{this.closeShareDialog}}
            @onSubmitted={{this.resourceSubmitted}}
            @resource={{this.shareContext.resource}}
          />{{/if}}
        {{#if this.showCourseDialog}}<ISBFLearningCourseDialog
            @grade={{this.grade}}
            @grades={{this.config.grades}}
            @onClose={{this.closeCourseDialog}}
            @onSubmitted={{this.courseSubmitted}}
            @request={{not this.canManageCourses}}
          />{{/if}}
        <div class="isbf-learning__body">
          <aside
            aria-label={{i18n (themePrefix "isbf_v2.workbench_courses")}}
            class="isbf-learning__courses"
          >
            <ISBFLearningGradePicker
              @grades={{this.config.grades}}
              @onChange={{this.changeGrade}}
              @value={{this.grade}}
            />
            {{#if this.coursesLoading}}<p role="status">{{i18n
                  (themePrefix "isbf_v2.learning_loading")
                }}</p>{{/if}}
            {{#if this.coursesError}}
              <p role="alert">{{i18n
                  (themePrefix "isbf_v2.learning_load_error")
                }}</p>
              <DButton
                @action={{this.loadCourses}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
              />
            {{else}}
              <nav
                aria-label={{i18n (themePrefix "isbf_v2.workbench_courses")}}
              >
                {{#each this.courseItems as |course|}}
                  <DButton
                    class={{if
                      course.selected
                      "btn-flat isbf-learning__course is-active"
                      "btn-flat isbf-learning__course"
                    }}
                    @action={{fn this.selectCourse course.id}}
                    @ariaPressed={{course.selected}}
                    @translatedLabel={{course.name}}
                  />
                {{else}}
                  {{#unless this.coursesLoading}}<p>{{i18n
                        (themePrefix "isbf_v2.learning_no_courses")
                      }}</p>{{/unless}}
                {{/each}}
              </nav>
            {{/if}}
            {{#if this.canSubmitCourses}}<DButton
                class="btn-flat isbf-learning__add-course"
                @action={{this.openCourseDialog}}
                @icon="plus"
                @translatedLabel={{this.courseActionLabel}}
              />{{/if}}
            {{#if this.coursePending}}<p
                class="isbf-learning__notice"
                role="status"
              >{{i18n
                  (themePrefix "isbf_v2.learning_course_pending")
                }}</p>{{/if}}
          </aside>
          <section
            aria-busy={{this.resourcesLoading}}
            aria-label={{this.contentTitle}}
            class="isbf-learning__content"
          >
            <div class="isbf-learning__content-header">
              <h2>{{this.contentTitle}}</h2>
              <DButton
                class="btn-primary isbf-learning__share"
                @action={{this.share}}
                @disabled={{this.shareDisabled}}
                @translatedLabel={{this.shareLabel}}
              />
            </div>
            {{#unless this.config.link_sharing}}<p
                class="isbf-learning__notice"
                role="status"
              >{{i18n
                  (themePrefix "isbf_v2.learning_share_unavailable")
                }}</p>{{/unless}}
            {{#if this.sharePending}}<p
                class="isbf-learning__notice"
                role="status"
              >{{i18n
                  (themePrefix "isbf_v2.learning_share_pending")
                }}</p>{{/if}}
            {{#if this.searching}}<p class="isbf-learning__hint">{{i18n
                  (themePrefix "isbf_v2.learning_search_hint")
                }}</p>{{/if}}
            {{#each this.resources key="id" as |resource|}}<ISBFLearningResource
                @grades={{this.config.grades}}
                @onDeleted={{this.resourceDeleted}}
                @onEdit={{this.editResource}}
                @resource={{resource}}
                @searching={{this.searching}}
              />{{/each}}
            {{#if this.resourcesLoading}}<p
                class="isbf-learning__notice"
                role="status"
              >{{i18n (themePrefix "isbf_v2.learning_loading")}}</p>
            {{else if this.resourcesError}}
              <p class="isbf-learning__notice" role="alert">{{i18n
                  (themePrefix "isbf_v2.learning_load_error")
                }}</p>
              <DButton
                @action={{this.retryResources}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
              />
            {{else if this.resources.length}}
              {{#if this.hasMore}}<DButton
                  class="isbf-learning__load-more"
                  @action={{this.loadMore}}
                  @translatedLabel={{i18n (themePrefix "isbf_v2.load_more")}}
                />{{/if}}
            {{else}}<p class="isbf-learning__notice">{{i18n
                  (themePrefix "isbf_v2.learning_empty")
                }}</p>{{/if}}
          </section>
        </div>
      {{else}}
        <div class="isbf-learning__notice">
          <p>{{i18n (themePrefix "isbf_v2.learning_login_required")}}</p>
          <DButton
            class="btn-primary"
            @action={{this.login}}
            @translatedLabel={{i18n "log_in"}}
          />
        </div>
      {{/if}}
    </main>
  </template>
}
