import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import Form from "discourse/components/form";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import {
  MAX_NAME_COLOR_STOPS,
  NAME_COLOR,
  NAME_COLOR_ENABLED,
  nameColorDraft,
  nameColorFormData,
  nameColorStopField,
  nameGradientStops,
  normalizedNameColor,
  validNameColor,
} from "../../lib/name-color";

export default class AcademyNameColor extends Component {
  @service a11y;
  @service currentUser;
  @service siteSettings;

  @tracked gradient = nameColorFormData(this.args.outletArgs.model).gradient;
  @tracked
  colorCount =
    nameGradientStops(nameColorDraft(this.args.outletArgs.model).color)
      ?.length || 2;

  formData = nameColorFormData(this.args.outletArgs.model);

  #formApi;

  get colorFields() {
    return Array.from({ length: this.colorCount }, (_, index) => ({
      name: nameColorStopField(index),
      number: index + 1,
    }));
  }

  get addColorLabel() {
    return i18n("academy_roles.name_color.add_color", {
      count: this.colorCount,
      max: MAX_NAME_COLOR_STOPS,
    });
  }

  get cannotAddColor() {
    return (
      this.colorCount >= MAX_NAME_COLOR_STOPS ||
      this.args.outletArgs.model.isSaving
    );
  }

  get canRemoveColor() {
    return this.colorCount > 2;
  }

  get canCustomize() {
    return (
      this.currentUser &&
      get(this.currentUser, "academy_can_customize_name_color") === true
    );
  }

  get draft() {
    return nameColorDraft(this.args.outletArgs.model);
  }

  get previewName() {
    const model = this.args.outletArgs.model;
    return model.name?.trim() || model.username;
  }

  get previewGradient() {
    return (
      this.draft.enabled &&
      this.canCustomize &&
      nameGradientStops(this.draft.color)
    );
  }

  get previewStyle() {
    const { enabled, color } = this.draft;
    const value = enabled
      ? (this.canCustomize && normalizedNameColor(color)) ||
        "var(--isbf-v2-accent, var(--tertiary))"
      : "var(--isbf-v2-text, var(--primary))";
    const stops = nameGradientStops(value);
    if (stops) {
      return trustHTML(
        `color: ${stops[0]}; --academy-name-gradient: ${value};`
      );
    }
    return trustHTML(`color: ${value};`);
  }

  get visible() {
    return (
      this.siteSettings.academy_roles_enabled &&
      this.currentUser?.id === this.args.outletArgs.model.id &&
      get(this.currentUser, "academy_can_wear_name_color") === true
    );
  }

  @action
  registerFormApi(api) {
    this.#formApi = api;
  }

  @action
  resetColor() {
    this.colorCount = 2;
    return this.#formApi.setProperties({
      gradient: false,
      color: "",
      endColor: "",
      direction: "90",
      ...Object.fromEntries(
        Array.from({ length: MAX_NAME_COLOR_STOPS - 2 }, (_, index) => [
          nameColorStopField(index + 2),
          "",
        ])
      ),
    });
  }

  @action
  async addColor() {
    if (this.cannotAddColor) {
      return;
    }
    const name = nameColorStopField(this.colorCount);
    this.colorCount++;
    await this.#formApi.set(name, "");
    this.a11y.announce(
      i18n("academy_roles.name_color.color_added", { count: this.colorCount })
    );
  }

  @action
  async removeColor() {
    if (!this.canRemoveColor || this.args.outletArgs.model.isSaving) {
      return;
    }
    this.colorCount--;
    await this.#formApi.set(nameColorStopField(this.colorCount), "");
    this.a11y.announce(
      i18n("academy_roles.name_color.color_removed", { count: this.colorCount })
    );
  }

  @action
  setPreference(name, value, data) {
    const model = this.args.outletArgs.model;
    if (name === "gradient") {
      this.gradient = value;
    }
    const color = data.gradient
      ? `linear-gradient(${data.direction}deg, ${this.colorFields.map((field) => data[field.name] ?? "").join(", ")})`
      : data.color;
    model.set("custom_fields", {
      ...model.custom_fields,
      [name === "enabled" ? NAME_COLOR_ENABLED : NAME_COLOR]:
        name === "enabled" ? value : color,
    });
  }

  @action
  validateColor(name, value, { addError }) {
    if (
      !validNameColor(value) ||
      nameGradientStops(value) ||
      (this.gradient && !value)
    ) {
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
        @validateOn="change"
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
            @description={{i18n
              "academy_roles.name_color.gradient_description"
            }}
            @disabled={{@outletArgs.model.isSaving}}
            @name="gradient"
            @title={{i18n "academy_roles.name_color.gradient"}}
            @type="checkbox"
            as |field|
          >
            <field.Control />
          </form.Field>
          {{#if this.gradient}}
            <form.Field
              @disabled={{@outletArgs.model.isSaving}}
              @name="direction"
              @title={{i18n "academy_roles.name_color.direction"}}
              @type="select"
              @validation="required"
              as |field|
            >
              <field.Control @includeNone={{false}} as |control|>
                <control.Option @value="90">{{i18n
                    "academy_roles.name_color.left_to_right"
                  }}</control.Option>
                <control.Option @value="180">{{i18n
                    "academy_roles.name_color.top_to_bottom"
                  }}</control.Option>
              </field.Control>
            </form.Field>
            {{#each this.colorFields key="name" as |colorField|}}
              <form.Field
                @disabled={{@outletArgs.model.isSaving}}
                @name={{colorField.name}}
                @title={{i18n
                  "academy_roles.name_color.color_stop"
                  number=colorField.number
                }}
                @type="color"
                @validate={{this.validateColor}}
                @validation="required"
                as |field|
              >
                <field.Control @prefixHex={{true}} />
              </form.Field>
            {{/each}}
            <DButton
              class="btn-flat academy-name-color__stop-action academy-name-color__add"
              @action={{this.addColor}}
              @disabled={{this.cannotAddColor}}
              @translatedLabel={{this.addColorLabel}}
            />
            {{#if this.canRemoveColor}}
              <DButton
                class="btn-flat academy-name-color__stop-action academy-name-color__remove"
                @action={{this.removeColor}}
                @disabled={{@outletArgs.model.isSaving}}
                @label="academy_roles.name_color.remove_color"
              />
            {{/if}}
          {{else}}
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
          {{/if}}
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
            class={{dConcatClass
              "academy-name-color__name"
              (if this.previewGradient "has-gradient")
            }}
            style={{this.previewStyle}}
          >{{this.previewName}}</span>
        </div>
      </Form>
    {{/if}}
  </template>
}
