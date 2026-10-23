import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";

export default class ReviewableIsbfLearningCourse extends Component {
  get gradeLabel() {
    const grade = this.args.reviewable.payload?.grade;
    return [1, 2, 3, 4].includes(grade)
      ? i18n(themePrefix(`isbf_v2.learning_grade_${grade}`))
      : "";
  }

  <template>
    <dl>
      <dt>{{i18n (themePrefix "isbf_v2.learning_course_name")}}</dt>
      <dd>{{@reviewable.payload.course_name}}</dd>
      <dt>{{i18n (themePrefix "isbf_v2.learning_grade")}}</dt>
      <dd>{{this.gradeLabel}}</dd>
    </dl>
  </template>
}
