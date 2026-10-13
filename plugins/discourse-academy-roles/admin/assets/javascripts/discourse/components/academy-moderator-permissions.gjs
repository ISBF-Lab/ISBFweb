import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

const GROUPS = {
  access: ["internal_boards", "user_admin", "hidden_content"],
  content: ["review", "edit_others", "delete_others", "manage_topics"],
  users: [
    "edit_users",
    "suspend_users",
    "silence_users",
    "delete_users",
    "anonymize_users",
  ],
  structure: ["manage_categories", "manage_groups"],
  business: [
    "publish_activities",
    "publish_official",
    "review_resources",
    "manage_resources",
  ],
  sensitive: ["view_emails", "trace_anonymous"],
};

export default class AcademyModeratorPermissions extends Component {
  @service a11y;
  @service currentUser;

  @tracked saved = false;
  @tracked values;

  #formApi;

  get formData() {
    return this.values ?? this.args.model.values;
  }

  get groups() {
    return Object.entries(GROUPS).map(([name, capabilities]) => ({
      heading: `academy_roles.moderator_permissions.groups.${name}`,
      fields: capabilities.map((capability) => ({
        name: this.args.model.settings[capability],
        title: i18n(
          `academy_roles.moderator_permissions.capabilities.${capability}`
        ),
      })),
    }));
  }

  get showSaved() {
    return this.saved && !this.#formApi?.isDirty;
  }

  @action
  registerForm(api) {
    this.#formApi = api;
  }

  @action
  async save(data) {
    const settings = {};
    for (const name of Object.values(this.args.model.settings)) {
      if (data[name] !== this.formData[name]) {
        settings[name] = { value: data[name] };
      }
    }
    if (!Object.keys(settings).length) {
      return;
    }
    try {
      await ajax("/admin/site_settings/bulk_update", {
        type: "PUT",
        data: { settings },
      });
      this.#formApi.commit();
      this.values = { ...data };
      this.saved = true;
      this.a11y.announce(
        i18n("academy_roles.moderator_permissions.saved"),
        "polite"
      );
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    {{#if this.currentUser.admin}}
      <div
        class="admin-config-page__main-area academy-moderator-permissions"
        ...attributes
      >
        <DPageSubheader
          @descriptionLabel={{i18n
            "academy_roles.moderator_permissions.description"
          }}
          @titleLabel={{i18n "academy_roles.moderator_permissions.title"}}
        />
        <p>{{i18n "academy_roles.moderator_permissions.fixed"}}</p>
        <Form
          @commitOnSubmit={{false}}
          @data={{this.formData}}
          @onRegisterApi={{this.registerForm}}
          @onSubmit={{this.save}}
          as |form|
        >
          {{#each this.groups as |group|}}
            <AdminConfigAreaCard
              class="academy-moderator-permissions__group"
              @heading={{group.heading}}
            >
              <:content>
                {{#each group.fields as |field|}}
                  <form.Field
                    @name={{field.name}}
                    @title={{field.title}}
                    @type="toggle"
                    as |control|
                  >
                    <control.Control />
                  </form.Field>
                {{/each}}
              </:content>
            </AdminConfigAreaCard>
          {{/each}}
          {{#if this.showSaved}}
            <form.Alert @type="success">{{i18n
                "academy_roles.moderator_permissions.saved"
              }}</form.Alert>
          {{/if}}
          <form.Submit @label="academy_roles.moderator_permissions.save" />
        </Form>
      </div>
    {{/if}}
  </template>
}
