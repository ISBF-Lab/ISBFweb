import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import ISBFLearningCourseDialog from "dialog-review/discourse/components/isbf-learning-course-dialog";
import ISBFResourceDirectoryDialog from "dialog-review/discourse/components/isbf-resource-directory-dialog";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
export const Resource = setComponentTemplate(createTemplateFactory(
/*
  <ISBFResourceDirectoryDialog
  @grade={{@model.grade}}
  @grades={{@model.grades}}
  @kind={{@model.kind}}
  @library={{@model.library}}
  @onClose={{@closeModal}}
  @onSubmitted={{@model.onSubmitted}}
  @request={{@model.request}}
/>
*/
{
  "id": null,
  "block": "[[[8,[32,0],null,[[\"@grade\",\"@grades\",\"@kind\",\"@library\",\"@onClose\",\"@onSubmitted\",\"@request\"],[[30,1,[\"grade\"]],[30,1,[\"grades\"]],[30,1,[\"kind\"]],[30,1,[\"library\"]],[30,2],[30,1,[\"onSubmitted\"]],[30,1,[\"request\"]]]],null]],[\"@model\",\"@closeModal\"],[]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    ISBFResourceDirectoryDialog
  }),
  "isStrictMode": true
}), templateOnly());
export const Course = setComponentTemplate(createTemplateFactory(
/*
  <ISBFLearningCourseDialog
  @grade={{@model.grade}}
  @grades={{@model.grades}}
  @onClose={{@closeModal}}
  @onSubmitted={{@model.onSubmitted}}
  @request={{@model.request}}
/>
*/
{
  "id": null,
  "block": "[[[8,[32,0],null,[[\"@grade\",\"@grades\",\"@onClose\",\"@onSubmitted\",\"@request\"],[[30,1,[\"grade\"]],[30,1,[\"grades\"]],[30,2],[30,1,[\"onSubmitted\"]],[30,1,[\"request\"]]]],null]],[\"@model\",\"@closeModal\"],[]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    ISBFLearningCourseDialog
  }),
  "isStrictMode": true
}), templateOnly());
export const Generic = setComponentTemplate(createTemplateFactory(
/*
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
*/
{
  "id": null,
  "block": "[[[8,[32,0],[[16,0,[30,1,[\"class\"]]]],[[\"@closeModal\",\"@title\"],[[30,2],\"弹窗样式与长内容检查\"]],[[\"body\",\"footer\"],[[[[1,\"\\n    \"],[42,[28,[31,1],[[28,[31,1],[[30,1,[\"paragraphs\"]]],null]],null],null,[[[10,2],[12],[1,[30,3]],[13]],[3]],null],[1,\"\\n  \"]],[]],[[[1,\"\\n    \"],[8,[32,1],[[24,0,\"btn-primary\"]],[[\"@translatedLabel\"],[\"保存变更\"]],null],[1,\"\\n    \"],[8,[32,1],[[24,0,\"btn-default\"]],[[\"@action\",\"@translatedLabel\"],[[30,2],\"取消\"]],null],[1,\"\\n  \"]],[]]]]]],[\"@model\",\"@closeModal\",\"paragraph\"],[\"each\",\"-track-array\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    DModal,
    DButton
  }),
  "isStrictMode": true
}), templateOnly());