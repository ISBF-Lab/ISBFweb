import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";
import ResumeContributorChooser from "./resume-contributor-chooser";

export default class ResumeContributorFields extends Component {
  @tracked selectedUser = this.args.contributorUser || null;
  @tracked studentNumber = this.args.data.student_number || "";

  get usernames() {
    return this.selectedUser ? [this.selectedUser.username] : [];
  }

  @action
  changeStudentNumber(value, { set }) {
    set("student_number", value);
    set("contributor_user_id", "");
    this.studentNumber = value?.trim() || "";
    this.selectedUser = null;
  }

  @action
  selectUser(setValue, usernames, users) {
    this.selectedUser = usernames?.length ? users?.[0] : null;
    setValue(this.selectedUser ? String(this.selectedUser.id) : "");
  }

  <template>
    <div class="isbf-resume-contributor-fields" ...attributes>
      <@form.Field
        @format="full"
        @helpText={{i18n "isbf_resume.sharing.fields.contributor.help"}}
        @name="contributor"
        @title={{i18n "isbf_resume.sharing.fields.contributor.title"}}
        @type="input-text"
        as |field|
      >
        <field.Control
          disabled={{@disabled}}
          maxlength={{80}}
          placeholder={{i18n
            "isbf_resume.sharing.fields.contributor.placeholder"
          }}
        />
      </@form.Field>
      <@form.Field
        @format="full"
        @helpText={{i18n "isbf_resume.sharing.fields.student_number.help"}}
        @name="student_number"
        @onSet={{this.changeStudentNumber}}
        @title={{i18n "isbf_resume.sharing.fields.student_number.title"}}
        @type="input-text"
        as |field|
      >
        <field.Control
          disabled={{@disabled}}
          maxlength={{64}}
          placeholder={{i18n
            "isbf_resume.sharing.fields.student_number.placeholder"
          }}
        />
      </@form.Field>
      {{#if this.studentNumber}}
        <@form.Field
          @format="full"
          @helpText={{i18n "isbf_resume.sharing.contributor_lookup_help"}}
          @name="contributor_user_id"
          @title={{i18n "isbf_resume.sharing.choose_contributor"}}
          @type="custom"
          as |field|
        >
          <field.Control>
            <ResumeContributorChooser
              @onChange={{fn this.selectUser field.set}}
              @options={{hash
                maximum=1
                disabled=@disabled
                translatedNone=(i18n "isbf_resume.sharing.choose_contributor")
              }}
              @studentNumber={{this.studentNumber}}
              @value={{this.usernames}}
            />
          </field.Control>
        </@form.Field>
      {{/if}}
    </div>
  </template>
}
