import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import Form from "discourse/components/form";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import {
  NAME_COLOR,
  NAME_COLOR_ENABLED,
  nameColorDraft,
  normalizedNameColor,
  validNameColor,
} from "../../lib/name-color";

export default class AcademyNameColor extends Component {
  @service currentUser;
  @service siteSettings;

  formData = nameColorDraft(this.args.outletArgs.model);

  #formApi;

  get canCustomize() {
    return this.currentUser?.academy_can_customize_name_color === true;
  }

  get draft() {
    return nameColorDraft(this.args.outletArgs.model);
  }

  get previewName() {
    const model = this.args.outletArgs.model;
    return model.name?.trim() || model.username;
  }

  get previewStyle() {
    const { enabled, color } = this.draft;
    const value = enabled
      ? (this.canCustomize && normalizedNameColor(color)) ||
        "var(--isbf-v2-accent, var(--tertiary))"
      : "var(--isbf-v2-text, var(--primary))";
    return trustHTML(`color: ${value};`);
  }

  get visible() {
    return (
      this.siteSettings.academy_roles_enabled &&
      this.currentUser?.id === this.args.outletArgs.model.id &&
      this.currentUser?.academy_can_wear_name_color === true
    );
  }

  @action
  registerFormApi(api) {
    this.#formApi = api;
  }

  @action
  resetColor() {
    return this.#formApi.set("color", "");
  }

  @action
  setPreference(name, value) {
    const model = this.args.outletArgs.model;
    model.set("custom_fields", {
      ...model.custom_fields,
      [name === "enabled" ? NAME_COLOR_ENABLED : NAME_COLOR]: value,
    });
  }

  @action
  validateColor(name, value, { addError }) {
    if (!validNameColor(value)) {
      addError(name, {
        title: i18n("academy_roles.name_color.color"),
        message: i18n("academy_roles.name_color.invalid_color"),
      });
    }
  }

  <template>
    {{#if this.visible}}
      <Form
        class="academy-name-color"
        @data={{this.formData}}
        @onRegisterApi={{this.registerFormApi}}
        @onSet={{this.setPreference}}
        @onSubmit={{@outletArgs.save}}
        @validateOn="input"
        as |form|
      >
        <h3 class="academy-name-color__title">{{i18n
            "academy_roles.name_color.title"
          }}</h3>
        <form.Field
          @description={{i18n "academy_roles.name_color.description"}}
          @disabled={{@outletArgs.model.isSaving}}
          @name="enabled"
          @title={{i18n "academy_roles.name_color.enabled"}}
          @type="checkbox"
          as |field|
        >
          <field.Control />
        </form.Field>
        {{#if this.canCustomize}}
          <form.Field
            @description={{i18n "academy_roles.name_color.color_description"}}
            @disabled={{@outletArgs.model.isSaving}}
            @name="color"
            @title={{i18n "academy_roles.name_color.color"}}
            @type="color"
            @validate={{this.validateColor}}
            as |field|
          >
            <field.Control @prefixHex={{true}} />
          </form.Field>
          <DButton
            class="btn-flat academy-name-color__reset"
            @action={{this.resetColor}}
            @disabled={{@outletArgs.model.isSaving}}
            @label="academy_roles.name_color.reset"
          />
        {{/if}}
        <div class="academy-name-color__preview">
          <span>{{i18n "academy_roles.name_color.preview"}}</span>
          <span
            class="academy-name-color__name"
            style={{this.previewStyle}}
          >{{this.previewName}}</span>
        </div>
      </Form>
    {{/if}}
  </template>
}
