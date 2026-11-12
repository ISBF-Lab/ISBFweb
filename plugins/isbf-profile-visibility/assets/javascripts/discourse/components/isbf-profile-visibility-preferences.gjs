import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import bodyClass from "discourse/helpers/body-class";
import { or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const FIELDS = {
  bio: "isbf_hide_profile_bio",
  summary: "isbf_hide_profile_summary",
  activity: "isbf_hide_profile_activity",
};

export default class IsbfProfileVisibilityPreferences extends Component {
  @service currentUser;
  @service siteSettings;

  // The form shows what stays public, the stored fields are what is hidden.
  formData = {
    hide_profile: this.args.model.user_option?.hide_profile ?? false,
    ...Object.fromEntries(
      Object.keys(FIELDS).map((section) => [
        section,
        !this.args.model.isbf_profile_visibility?.[section],
      ])
    ),
  };

  sections = Object.keys(FIELDS).map((section) => ({
    name: section,
    title: i18n(`isbf_profile_visibility.${section}.title`),
    description: i18n(`isbf_profile_visibility.${section}.description`),
  }));

  get visible() {
    return (
      this.siteSettings.isbf_profile_visibility_enabled &&
      this.siteSettings.allow_users_to_hide_profile &&
      !this.currentUser?.needs_required_fields_check
    );
  }

  @action
  setVisibility(name, value) {
    const model = this.args.model;

    if (name === "hide_profile") {
      model.set("user_option.hide_profile", value);
    } else {
      model.set("custom_fields", {
        ...model.custom_fields,
        [FIELDS[name]]: !value,
      });
    }
  }

  <template>
    {{#if this.visible}}
      {{bodyClass "isbf-profile-visibility"}}
      <Form
        class="profile-visibility"
        data-setting-name="user-profile-visibility"
        @data={{this.formData}}
        @onSet={{this.setVisibility}}
        as |form|
      >
        <form.Section @title={{i18n "isbf_profile_visibility.title"}}>
          <form.Field
            @disabled={{@model.isSaving}}
            @name="hide_profile"
            @title={{i18n "user.hide_profile"}}
            @type="checkbox"
            as |field|
          >
            <field.Control>
              {{i18n "isbf_profile_visibility.hide_profile_description"}}
            </field.Control>
          </form.Field>

          <form.CheckboxGroup
            @description={{i18n "isbf_profile_visibility.note"}}
            @title={{i18n "isbf_profile_visibility.sections_title"}}
            as |group|
          >
            {{#each this.sections key="name" as |section|}}
              <group.Field
                @disabled={{or @model.user_option.hide_profile @model.isSaving}}
                @name={{section.name}}
                @title={{section.title}}
                @type="checkbox"
                as |field|
              >
                <field.Control>{{section.description}}</field.Control>
              </group.Field>
            {{/each}}
          </form.CheckboxGroup>
        </form.Section>
      </Form>
    {{/if}}
  </template>
}
