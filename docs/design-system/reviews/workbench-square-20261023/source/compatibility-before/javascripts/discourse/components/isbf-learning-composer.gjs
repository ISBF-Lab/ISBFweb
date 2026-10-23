import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import { isLearningComposer } from "../lib/learning-composer";

export default class ISBFLearningComposer extends Component {
  @tracked courses = [];
  @tracked error = false;
  @tracked loading = false;

  constructor() {
    super(...arguments);
    this.loadCourses();
  }

  get model() {
    return this.args.outletArgs?.model;
  }

  get visible() {
    return isLearningComposer(this.model);
  }

  get options() {
    const labels = ["大一", "大二", "大三", "大四"];
    return this.courses.map((course) => ({
      ...course,
      label: `${labels[course.grade - 1]} · ${course.name}`,
      selected: course.id === this.model?.isbf_learning_course_id,
    }));
  }

  @action
  async loadCourses() {
    if (!this.visible || this.loading) {
      return;
    }
    this.loading = true;
    this.error = false;
    try {
      const data = await ajax("/isbf/learning/courses");
      if (!this.isDestroying && !this.isDestroyed) {
        this.courses = data.courses || [];
      }
    } catch {
      if (!this.isDestroying && !this.isDestroyed) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying && !this.isDestroyed) {
        this.loading = false;
      }
    }
  }

  @action
  selectCourse(event) {
    this.model.set("isbf_learning_course_id", event.target.value);
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-learning-composer" {{didInsert this.loadCourses}}>
        <label>课程
          <select disabled={{this.loading}} {{on "change" this.selectCourse}}>
            <option value="">请选择课程</option>
            {{#each this.options as |course|}}
              <option
                value={{course.id}}
                selected={{course.selected}}
              >{{course.label}}</option>
            {{/each}}
          </select>
        </label>
        <p
        >填写资料标题。说明可选；请上传资料文件或填写外部链接。普通用户投稿将在审核通过后展示。</p>
        {{#if this.error}}<DButton
            @action={{this.loadCourses}}
            @translatedLabel="加载课程失败，重试"
          />{{/if}}
      </div>
    {{/if}}
  </template>
}
