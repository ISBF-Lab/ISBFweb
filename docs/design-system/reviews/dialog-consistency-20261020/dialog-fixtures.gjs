import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import ISBFLearningCourseDialog from "dialog-review/discourse/components/isbf-learning-course-dialog";
import ISBFResourceDirectoryDialog from "dialog-review/discourse/components/isbf-resource-directory-dialog";

export const Resource = <template>
  <ISBFResourceDirectoryDialog
    @grade={{@model.grade}}
    @grades={{@model.grades}}
    @kind={{@model.kind}}
    @library={{@model.library}}
    @onClose={{@closeModal}}
    @onSubmitted={{@model.onSubmitted}}
    @request={{@model.request}}
  />
</template>;

export const Course = <template>
  <ISBFLearningCourseDialog
    @grade={{@model.grade}}
    @grades={{@model.grades}}
    @onClose={{@closeModal}}
    @onSubmitted={{@model.onSubmitted}}
    @request={{@model.request}}
  />
</template>;

export const Generic = <template>
  <DModal
    class={{@model.class}}
    @closeModal={{@closeModal}}
    @title="弹窗样式与长内容检查"
  >
    <:body>
      {{#each @model.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}
    </:body>
    <:footer>
      <DButton class="btn-primary" @translatedLabel="保存变更" />
      <DButton class="btn-default" @action={{@closeModal}} @translatedLabel="取消" />
    </:footer>
  </DModal>
</template>;
