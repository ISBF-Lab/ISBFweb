import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class AcademyOfficialPostQuota extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked error;
  @tracked formData;
  @tracked loading = true;
  @tracked quota;
  @tracked saved = false;
  @tracked saving = false;

  #formApi;
  #userId;

  constructor(owner, args) {
    super(owner, args);
    this.#userId = args.user?.id;
    if (this.visible) {
      this.load();
    }
  }

  get visible() {
    return (
      this.currentUser?.admin &&
      this.siteSettings.academy_roles_enabled &&
      this.args.user?.id > 0
    );
  }

  get remaining() {
    return (
      this.quota.remaining ??
      i18n("academy_roles.official_post_quota.unlimited")
    );
  }

  get resetLabel() {
    const date = new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
      timeZone: this.quota.timezone,
    }).format(new Date(this.quota.resets_at));
    return i18n("academy_roles.official_post_quota.resets_at", {
      date,
      timezone: this.quota.timezone,
    });
  }

  get showSaved() {
    return this.saved && !this.#formApi?.isDirty;
  }

  @action
  async load() {
    if (!this.#isCurrent() || this.saving) {
      return;
    }
    this.error = null;
    this.loading = true;
    try {
      const response = await ajax(this.#url());
      if (this.#isCurrent()) {
        this.quota = response.official_post_quota;
        this.formData = { limit: this.quota.limit ?? 0 };
      }
    } catch (error) {
      if (this.#isCurrent()) {
        this.error = extractError(error);
      }
    } finally {
      if (this.#isCurrent()) {
        this.loading = false;
      }
    }
  }

  @action
  registerForm(api) {
    this.#formApi = api;
  }

  @action
  async save({ limit }) {
    if (!this.#isCurrent() || this.loading || this.saving) {
      return;
    }
    this.error = null;
    this.saved = false;
    this.saving = true;
    try {
      const response = await ajax(this.#url(), {
        type: "PUT",
        contentType: "application/json",
        data: JSON.stringify({ limit }),
      });
      if (this.#isCurrent()) {
        this.quota = response.official_post_quota;
        this.#formApi.commit();
        this.saved = true;
      }
    } catch (error) {
      if (this.#isCurrent()) {
        this.error = extractError(error);
      }
    } finally {
      if (this.#isCurrent()) {
        this.saving = false;
      }
    }
  }

  @action
  validate({ limit }, { addError }) {
    if (!Number.isInteger(limit) || limit < 0 || limit > 2147483647) {
      addError("limit", {
        title: i18n("academy_roles.official_post_quota.limit"),
        message: i18n("academy_roles.official_post_quota.invalid_limit"),
      });
    }
  }

  #isCurrent() {
    return (
      !this.isDestroying && this.visible && this.args.user.id === this.#userId
    );
  }

  #url() {
    return `/academy-roles/admin/users/${this.#userId}/official-post-quota`;
  }

  <template>
    {{#if this.visible}}
      <div class="display-row academy-official-post-quota" ...attributes>
        <div class="field">{{i18n
            "academy_roles.official_post_quota.title"
          }}</div>
        <div class="value">
          {{#if this.loading}}
            <p role="status">{{i18n
                "academy_roles.official_post_quota.loading"
              }}</p>
          {{/if}}
          {{#if this.error}}
            <p class="alert alert-error" role="alert">{{this.error}}</p>
            {{#unless this.quota}}
              <DButton
                @action={{this.load}}
                @disabled={{this.loading}}
                @label="academy_roles.official_post_quota.retry"
              />
            {{/unless}}
          {{/if}}
          {{#if this.quota}}
            {{#if this.quota.exempt}}
              <p>{{i18n "academy_roles.official_post_quota.exempt"}}</p>
            {{/if}}
            {{#unless this.quota.official}}
              <p>{{i18n "academy_roles.official_post_quota.not_official"}}</p>
            {{/unless}}
            <p>{{i18n
                "academy_roles.official_post_quota.usage"
                remaining=this.remaining
                used=this.quota.used
              }}</p>
            <p>{{this.resetLabel}}</p>
            <Form
              @commitOnSubmit={{false}}
              @data={{this.formData}}
              @onRegisterApi={{this.registerForm}}
              @onSubmit={{this.save}}
              @validate={{this.validate}}
              as |form|
            >
              <form.Field
                @description={{i18n
                  "academy_roles.official_post_quota.description"
                }}
                @disabled={{this.saving}}
                @name="limit"
                @title={{i18n "academy_roles.official_post_quota.limit"}}
                @type="input-number"
                as |field|
              >
                <field.Control max="2147483647" min="0" step="1" />
              </form.Field>
              {{#if this.showSaved}}
                <form.Alert @type="success">{{i18n
                    "academy_roles.official_post_quota.saved"
                  }}</form.Alert>
              {{/if}}
              <form.Submit
                @disabled={{this.saving}}
                @label="academy_roles.official_post_quota.save"
              />
            </Form>
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
