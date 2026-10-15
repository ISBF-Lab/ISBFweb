import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

export default class ResumeShareMetadata extends Component {
  get fields() {
    return ["industry", "position", "salary", "experience"]
      .filter((field) => this.args.share[field])
      .map((field) => ({
        key: field,
        label: i18n(`isbf_resume.sharing.fields.${field}.title`),
        value: this.args.share[field],
      }));
  }

  <template>
    {{#if this.fields.length}}
      <dl class="isbf-resume-share-metadata" ...attributes>
        {{#each this.fields key="key" as |field|}}
          <div class="isbf-resume-share-metadata__field"><dt
            >{{field.label}}</dt><dd>{{field.value}}</dd></div>
        {{/each}}
      </dl>
    {{/if}}
  </template>
}
