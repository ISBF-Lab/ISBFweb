import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  learningConfig,
  learningResourceQuery,
  libraryConfig,
} from "../lib/learning-resources";
import ISBFLearningCollectionFormDialog from "./isbf-learning-collection-form-dialog";
import ISBFLearningDirectoryDeletion from "./isbf-learning-directory-deletion";
import ISBFLearningDirectoryEditor from "./isbf-learning-directory-editor";
import ISBFLearningManagementDialog from "./isbf-learning-management-dialog";
import ISBFResourceAddDialog from "./isbf-resource-add-dialog";
import ISBFResourceCatalog from "./isbf-resource-catalog";
import ISBFResourceDirectoryDialog from "./isbf-resource-directory-dialog";
import ISBFResourceList from "./isbf-resource-list";

export default class ISBFResourcePage extends Component {
  @service appEvents;
  @service currentUser;
  @service isbfBackNavigation;
  @service site;

  @tracked coursePending = false;
  @tracked courses = [];
  @tracked coursesError = false;
  @tracked coursesLoading = false;
  @tracked grade = 1;
  @tracked categories = [];
  @tracked directoryKind = "group";
  @tracked selectedCourseId = null;
  @tracked showCourseDialog = false;
  @tracked showAddDialog = false;
  @tracked query = "";
  @tracked resources = [];
  @tracked resourcesError = false;
  @tracked resourcesLoading = false;
  @tracked hasMore = false;
  @tracked shareContext = null;
  @tracked sharePending = false;
  @tracked myContributions = false;
  @tracked grades = [];
  @tracked editingDirectory = null;
  @tracked deletingDirectory = null;
  @tracked showCollectionFormDialog = false;

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
    return this.isLibrary
      ? libraryConfig(this.site)
      : learningConfig(this.site);
  }

  get isLibrary() {
    return this.args.library === true;
  }

  get endpoint() {
    return this.isLibrary ? "/isbf/library" : "/isbf/learning";
  }

  get parents() {
    return this.isLibrary
      ? this.categories.map((category) => ({
          ...category,
          label: category.name,
        }))
      : this.grades;
  }

  get pageTitle() {
    return i18n(
      themePrefix(
        this.isLibrary
          ? "isbf_v2.workbench_library"
          : "isbf_v2.workbench_learning_resources"
      )
    );
  }

  get parentLabel() {
    return i18n(themePrefix("isbf_v2.library_category"));
  }

  get directoryLabel() {
    return i18n(
      themePrefix(
        this.isLibrary ? "isbf_v2.library_groups" : "isbf_v2.workbench_courses"
      )
    );
  }

  get groupSubmitDisabled() {
    return !this.grade;
  }

  get canAddDirectories() {
    return this.currentUser?.admin === true;
  }

  get categoryActionLabel() {
    return i18n(
      themePrefix(
        this.canManageCourses
          ? "isbf_v2.library_add_category"
          : "isbf_v2.library_request_category"
      )
    );
  }

  get searchLabel() {
    return i18n(
      themePrefix(
        this.isLibrary ? "isbf_v2.library_search" : "isbf_v2.learning_search"
      )
    );
  }

  get canManageCourses() {
    return Boolean(
      this.currentUser?.admin ||
      this.currentUser?.academy_moderator_permissions?.manage_resources
    );
  }

  get canManageResources() {
    return Boolean(
      this.currentUser?.admin ||
      this.currentUser?.academy_moderator_permissions?.manage_resources
    );
  }

  get canManageCollectionForm() {
    return Boolean(
      this.currentUser &&
      (get(this.currentUser, "admin") ||
        get(this.currentUser, "academy_moderator_permissions.manage_resources"))
    );
  }

  get canSubmitResources() {
    if (!this.currentUser?.academy_moderator_role || this.currentUser?.admin) {
      return true;
    }
    return Boolean(
      this.site.categories?.find(
        (category) => category.id === this.config?.category_id
      )?.canCreateTopic
    );
  }

  get canSubmitCourses() {
    return Boolean(
      this.currentUser &&
      this.canSubmitResources &&
      (this.isLibrary || this.grade !== null) &&
      (this.canManageCourses ||
        (this.isLibrary
          ? this.config?.catalog_requests
          : this.config?.course_requests) === true)
    );
  }

  get courseActionLabel() {
    return i18n(
      themePrefix(
        this.isLibrary
          ? this.canManageCourses
            ? "isbf_v2.library_add_group"
            : "isbf_v2.library_request_group"
          : this.canManageCourses
            ? "isbf_v2.learning_add_course"
            : "isbf_v2.learning_request_course"
      )
    );
  }

  get courseItems() {
    return this.courses
      .filter(
        (course) =>
          (this.isLibrary ? course.category_id : course.grade) === this.grade
      )
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
          !this.canManageResources
          ? "isbf_v2.learning_apply_share"
          : "isbf_v2.learning_share"
      )
    );
  }

  get shareDisabled() {
    if (!this.canManageResources) {
      return false;
    }
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
    if (this.myContributions) {
      return i18n(themePrefix("isbf_v2.learning_my_contributions"));
    }
    return this.searching
      ? i18n(themePrefix("isbf_v2.learning_search_results"))
      : this.selectedCourse?.name ||
          i18n(
            themePrefix(
              this.isLibrary
                ? "isbf_v2.library_select_group"
                : "isbf_v2.learning_select_course"
            )
          );
  }

  get backHref() {
    return this.isbfBackNavigation.href("/isbf/workbench");
  }

  @action
  editCollectionForm() {
    if (this.canManageCollectionForm) {
      this.showCollectionFormDialog = true;
    }
  }

  @action
  closeCollectionFormDialog() {
    this.showCollectionFormDialog = false;
  }

  @action
  goBack(event) {
    this.isbfBackNavigation.back(event);
  }

  @action
  login() {
    this.appEvents.trigger("show-login");
  }

  @action
  async loadCourses() {
    if (this.isDestroying) {
      return;
    }
    const request = ++this.#coursesRequest;
    this.coursesLoading = true;
    this.coursesError = false;
    try {
      const response = this.isLibrary
        ? await ajax(`${this.endpoint}/categories`)
        : await ajax(`${this.endpoint}/courses`);
      let groups;
      if (this.isLibrary && request === this.#coursesRequest) {
        groups = await ajax(`${this.endpoint}/groups`);
      }
      if (request !== this.#coursesRequest) {
        return;
      }
      if (this.isLibrary) {
        this.categories = response.categories || [];
        if (!this.categories.some((category) => category.id === this.grade)) {
          this.grade = this.categories[0]?.id || null;
        }
      }
      this.courses = this.isLibrary
        ? groups.groups || []
        : response.courses || [];
      if (!this.isLibrary) {
        this.grades = response.grades || this.config.grades;
        if (!this.grades.some((grade) => grade.id === this.grade)) {
          this.grade = this.grades[0]?.id || null;
        }
      }
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
    this.myContributions = false;
    this.grade = id;
    this.#restoreCourse();
    if (!this.searching) {
      this.#loadResources();
    }
  }

  @action
  selectCourse(id) {
    this.myContributions = false;
    this.selectedCourseId = id;
    if (!this.searching) {
      this.#loadResources();
    }
  }

  @action
  changeQuery(event) {
    this.myContributions = false;
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
  toggleContributions() {
    clearTimeout(this.#searchTimer);
    this.myContributions = !this.myContributions;
    this.query = "";
    this.#loadResources();
  }

  @action
  editCourse(course) {
    if (this.canManageResources) {
      this.#courseTrigger = document.activeElement;
      this.editingDirectory = { kind: "course", entry: course };
    }
  }

  @action
  editGrade() {
    const entry = this.parents.find((parent) => parent.id === this.grade);
    if (this.canManageResources && entry) {
      this.#courseTrigger = document.activeElement;
      this.editingDirectory = {
        kind: "grade",
        entry,
      };
    }
  }

  @action
  closeDirectoryEditor() {
    this.editingDirectory = null;
    this.#courseTrigger?.focus();
  }

  @action
  deleteDirectory() {
    if (this.canManageResources && this.editingDirectory) {
      this.deletingDirectory = this.editingDirectory;
      this.editingDirectory = null;
    }
  }

  @action
  closeDirectoryDeletion() {
    this.deletingDirectory = null;
    this.#courseTrigger?.focus();
  }

  @action
  directoryDeleted() {
    this.closeDirectoryDeletion();
    this.#resourcesRequest++;
    this.resources = [];
    this.loadCourses();
  }

  @action
  directorySaved(response, grade) {
    this.closeDirectoryEditor();
    this.grade = grade;
    this.loadCourses();
  }

  @action
  openAddDialog() {
    if (
      !this.canAddDirectories ||
      this.showAddDialog ||
      this.showCourseDialog
    ) {
      return;
    }
    this.#courseTrigger = document.activeElement;
    this.showAddDialog = true;
  }

  @action
  closeAddDialog() {
    this.showAddDialog = false;
    this.#courseTrigger?.focus();
  }

  @action
  openCourseDialog(kind = "group") {
    if (!this.canAddDirectories || this.showCourseDialog) {
      return;
    }
    this.directoryKind = typeof kind === "string" ? kind : "group";
    if (this.directoryKind === "group" && !this.grade) {
      return;
    }
    this.coursePending = false;
    if (!this.showAddDialog) {
      this.#courseTrigger = document.activeElement;
    }
    this.showAddDialog = false;
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
      myContributions: this.myContributions,
    };
  }

  @action
  editResource(resource) {
    if (
      this.isDestroying ||
      !this.canManageResources ||
      this.config?.resource_admin_management !== true ||
      this.shareContext ||
      resource?.can_delete !== true ||
      !(this.isLibrary ? resource.group?.id : resource.course?.id)
    ) {
      return;
    }
    this.#shareTrigger = document.activeElement;
    this.sharePending = false;
    this.shareContext = {
      course: this.isLibrary ? resource.group : resource.course,
      resource,
      selectedCourseId: this.selectedCourseId,
      query: this.query.trim(),
      coursesRequest: this.#coursesRequest,
      myContributions: this.myContributions,
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
      context.myContributions === this.myContributions &&
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
    if (this.isDestroying) {
      return;
    }
    const request = ++this.#resourcesRequest;
    const page = append ? this.#page + 1 : 0;
    this.resourcesError = false;
    if (!append) {
      this.resources = [];
      this.hasMore = false;
    }
    if (!this.myContributions && !this.searching && !this.selectedCourseId) {
      this.resourcesLoading = false;
      return;
    }
    this.resourcesLoading = true;
    try {
      const response = await ajax(
        `${this.endpoint}/${this.myContributions ? "contributions" : "resources"}`,
        {
          data: this.myContributions
            ? { page }
            : this.isLibrary && !this.searching
              ? { group_id: this.selectedCourseId, page }
              : learningResourceQuery(this.selectedCourseId, this.query, page),
        }
      );
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
          aria-label={{i18n "back_button"}}
          class="isbf-learning__back"
          href={{this.backHref}}
          {{on "click" this.goBack}}
        >
          {{dIcon "arrow-left"}}
          <h1>{{this.pageTitle}}</h1>
        </a>
        {{#if this.currentUser}}
          {{#if this.config}}
            <div class="isbf-learning__search">
              <input
                aria-label={{this.searchLabel}}
                placeholder={{this.searchLabel}}
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
            (themePrefix
              (if
                this.isLibrary
                "isbf_v2.library_unavailable"
                "isbf_v2.learning_unavailable"
              )
            )
          }}</p>
      {{else if this.currentUser}}
        {{#if this.showCollectionFormDialog}}<ISBFLearningCollectionFormDialog
            @library={{this.isLibrary}}
            @onClose={{this.closeCollectionFormDialog}}
            @onSaved={{this.closeCollectionFormDialog}}
          />{{/if}}
        {{#if this.shareContext}}
          <ISBFLearningManagementDialog
            @course={{this.shareContext.course}}
            @courses={{this.courses}}
            @grades={{this.parents}}
            @library={{this.isLibrary}}
            @onClose={{this.closeShareDialog}}
            @onSubmitted={{this.resourceSubmitted}}
            @resource={{this.shareContext.resource}}
          />
        {{/if}}
        {{#if this.editingDirectory}}<ISBFLearningDirectoryEditor
            @entry={{this.editingDirectory.entry}}
            @grades={{this.parents}}
            @kind={{this.editingDirectory.kind}}
            @library={{this.isLibrary}}
            @onClose={{this.closeDirectoryEditor}}
            @onDelete={{this.deleteDirectory}}
            @onSaved={{this.directorySaved}}
          />{{/if}}
        {{#if this.deletingDirectory}}<ISBFLearningDirectoryDeletion
            @entry={{this.deletingDirectory.entry}}
            @kind={{this.deletingDirectory.kind}}
            @library={{this.isLibrary}}
            @onClose={{this.closeDirectoryDeletion}}
            @onDeleted={{this.directoryDeleted}}
          />{{/if}}
        {{#if this.showAddDialog}}
          <ISBFResourceAddDialog
            @courseDisabled={{this.groupSubmitDisabled}}
            @onChoose={{this.openCourseDialog}}
            @onClose={{this.closeAddDialog}}
          />
        {{/if}}
        {{#if this.showCourseDialog}}<ISBFResourceDirectoryDialog
            @grade={{this.grade}}
            @grades={{this.parents}}
            @kind={{this.directoryKind}}
            @library={{this.isLibrary}}
            @onClose={{this.closeCourseDialog}}
            @onSubmitted={{this.courseSubmitted}}
            @request={{false}}
          />{{/if}}
        <div class="isbf-learning__body">
          <ISBFResourceCatalog @page={{this}} />
          <ISBFResourceList @page={{this}} />
        </div>
      {{else}}
        <div class="isbf-learning__notice">
          <p>{{i18n
              (themePrefix
                (if
                  this.isLibrary
                  "isbf_v2.library_login_required"
                  "isbf_v2.learning_login_required"
                )
              )
            }}</p>
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
