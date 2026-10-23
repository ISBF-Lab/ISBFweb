import { fn } from "@ember/helper";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import ISBFResourceParentPicker from "./isbf-resource-parent-picker";

export default <template>
  <aside aria-label={{@page.directoryLabel}} class="isbf-learning__courses">
    <div class="isbf-resource-parent">
      <div class="isbf-resource-parent__picker">
        <ISBFResourceParentPicker
          @grades={{@page.parents}}
          @label={{@page.parentLabel}}
          @onChange={{@page.changeGrade}}
          @value={{@page.grade}}
        />
      </div>
      {{#if @page.canManageResources}}<DButton
          class="btn-flat isbf-learning__edit-grade"
          @action={{@page.editGrade}}
          @icon="pencil"
          @translatedTitle={{i18n
            (themePrefix
              (if
                @page.isLibrary
                "isbf_v2.library_edit_category"
                "isbf_v2.learning_edit_grade"
              )
            )
          }}
        />{{/if}}
    </div>
    {{#if @page.coursesLoading}}<p role="status">{{i18n
          (themePrefix "isbf_v2.learning_loading")
        }}</p>{{/if}}
    {{#if @page.coursesError}}
      <p role="alert">{{i18n (themePrefix "isbf_v2.learning_load_error")}}</p>
      <DButton
        @action={{@page.loadCourses}}
        @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
      />
    {{else}}
      <nav aria-label={{@page.directoryLabel}}>
        {{#each @page.courseItems as |course|}}
          <DButton
            class={{if
              course.selected
              "btn-flat isbf-learning__course is-active"
              "btn-flat isbf-learning__course"
            }}
            @action={{fn @page.selectCourse course.id}}
            @ariaPressed={{course.selected}}
            @translatedLabel={{course.name}}
          />
        {{else}}
          {{#unless @page.coursesLoading}}<p>{{i18n
                (themePrefix
                  (if
                    @page.isLibrary
                    "isbf_v2.library_no_groups"
                    "isbf_v2.learning_no_courses"
                  )
                )
              }}</p>{{/unless}}
        {{/each}}
      </nav>
    {{/if}}
    {{#if @page.canAddDirectories}}<DButton
        class="btn-flat isbf-learning__add-course"
        @action={{@page.openAddDialog}}
        @icon="plus"
        @translatedLabel={{i18n (themePrefix "isbf_v2.resource_add")}}
      />{{/if}}
    {{#if @page.coursePending}}<p
        class="isbf-learning__notice"
        role="status"
      >{{i18n
          (themePrefix
            (if
              @page.isLibrary
              "isbf_v2.library_directory_pending"
              "isbf_v2.learning_course_pending"
            )
          )
        }}</p>{{/if}}
  </aside>
</template>
