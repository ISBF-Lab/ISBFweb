import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import { alumniCities, alumniRegions } from "../lib/alumni";

export default class ISBFAlumniProfile extends Component {
  @service currentUser;

  @tracked
  profile = {
    display_name: "",
    country_code: "CN",
    region_code: "",
    city_code: "",
    city_name: "",
    bio: "",
    industry: "",
    visible: false,
  };
  @tracked loading = true;
  @tracked loaded = false;
  @tracked saving = false;
  @tracked error = false;

  constructor() {
    super(...arguments);
    this.load();
  }

  get regions() {
    return alumniRegions(this.args.config, this.profile.country_code);
  }

  get cities() {
    return alumniCities(
      this.args.config,
      this.profile.country_code,
      this.profile.region_code
    );
  }

  get chineseLocation() {
    return this.profile.country_code === "CN";
  }

  get disabled() {
    return !this.loaded || this.loading || this.saving;
  }

  @action
  async load() {
    this.loading = true;
    this.error = false;
    try {
      const response = await ajax("/isbf/alumni/me");
      if (this.isDestroying) {
        return;
      }
      this.profile = {
        ...this.profile,
        country_code: response.country_code || "CN",
        region_code: response.country_code === "CN" ? response.region_code : "",
        city_code: response.city_code || "",
        city_name: response.city_name || "",
        bio: response.bio || "",
        industry: response.industry || "",
        visible: response.visible === true,
        display_name:
          response.display_name ||
          this.currentUser.name ||
          this.currentUser.username,
      };
      this.loaded = true;
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }

  @action
  change(field, event) {
    const value =
      field === "visible" ? event.target.checked : event.target.value;
    const next = { ...this.profile, [field]: value };
    if (field === "country_code") {
      next.region_code = "";
    }
    if (field === "country_code" || field === "region_code") {
      next.city_code = "";
      next.city_name = "";
    }
    this.profile = next;
  }

  @action
  async save(event) {
    event.preventDefault();
    if (this.disabled) {
      return;
    }
    this.saving = true;
    this.error = false;
    try {
      await ajax("/isbf/alumni/me", { type: "PUT", data: this.profile });
      if (!this.isDestroying) {
        this.args.onSaved();
      }
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.saving = false;
      }
    }
  }

  <template>
    <DModal
      class="isbf-alumni-profile"
      @closeModal={{@onClose}}
      @submitOnEnter={{false}}
      @title={{i18n (themePrefix "isbf_v2.alumni_my_profile")}}
    >
      <:body>
        {{#if this.loading}}<p role="status">{{i18n
              (themePrefix "isbf_v2.learning_loading")
            }}</p>
        {{else if this.loaded}}
          <form {{on "submit" this.save}}>
            <label>{{i18n (themePrefix "isbf_v2.alumni_name")}}<input
                disabled={{this.saving}}
                maxlength="60"
                required
                type="text"
                value={{this.profile.display_name}}
                {{on "input" (fn this.change "display_name")}}
              /></label>
            <label>{{i18n (themePrefix "isbf_v2.alumni_country")}}<select
                disabled={{this.saving}}
                required
                value={{this.profile.country_code}}
                {{on "change" (fn this.change "country_code")}}
              >
                {{#each @config.countries as |country|}}<option
                    selected={{eq this.profile.country_code country.code}}
                    value={{country.code}}
                  >{{country.name}}</option>{{/each}}
              </select></label>
            {{#if this.regions.length}}<label>{{i18n
                  (themePrefix "isbf_v2.alumni_region")
                }}<select
                  disabled={{this.saving}}
                  required
                  value={{this.profile.region_code}}
                  {{on "change" (fn this.change "region_code")}}
                >
                  <option value="">{{i18n
                      (themePrefix "isbf_v2.alumni_select")
                    }}</option>
                  {{#each this.regions as |region|}}<option
                      selected={{eq this.profile.region_code region.code}}
                      value={{region.code}}
                    >{{region.name}}</option>{{/each}}
                </select></label>{{/if}}
            <label>{{i18n (themePrefix "isbf_v2.alumni_city")}}
              {{#if this.chineseLocation}}
                <select
                  disabled={{this.saving}}
                  value={{this.profile.city_code}}
                  {{on "change" (fn this.change "city_code")}}
                >
                  <option value="">{{i18n
                      (themePrefix "isbf_v2.alumni_city_optional")
                    }}</option>
                  {{#each this.cities as |city|}}<option
                      selected={{eq this.profile.city_code city.code}}
                      value={{city.code}}
                    >{{city.name}}</option>{{/each}}
                </select>
              {{else}}
                <input
                  disabled={{this.saving}}
                  maxlength="80"
                  type="text"
                  value={{this.profile.city_name}}
                  {{on "input" (fn this.change "city_name")}}
                />
              {{/if}}
            </label>
            <label>{{i18n (themePrefix "isbf_v2.alumni_industry")}}<input
                disabled={{this.saving}}
                maxlength="60"
                required
                type="text"
                value={{this.profile.industry}}
                {{on "input" (fn this.change "industry")}}
              /></label>
            <label>{{i18n (themePrefix "isbf_v2.alumni_bio")}}
              <textarea
                disabled={{this.saving}}
                maxlength="500"
                rows="4"
                value={{this.profile.bio}}
                {{on "input" (fn this.change "bio")}}
              ></textarea>
            </label>
            <label class="isbf-alumni-profile__visible"><input
                checked={{this.profile.visible}}
                disabled={{this.saving}}
                type="checkbox"
                {{on "change" (fn this.change "visible")}}
              />{{i18n (themePrefix "isbf_v2.alumni_visible")}}</label>
            <div class="isbf-alumni-profile__actions"><DButton
                @action={{@onClose}}
                @translatedLabel={{i18n "cancel"}}
              /><button
                class="btn btn-primary"
                disabled={{this.disabled}}
                type="submit"
              >{{i18n "save"}}</button></div>
          </form>
        {{/if}}
        {{#if this.error}}<p role="alert">{{i18n
              (themePrefix "isbf_v2.alumni_save_error")
            }}</p>{{#unless this.loaded}}<DButton
              @action={{this.load}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
            />{{/unless}}{{/if}}
      </:body>
    </DModal>
  </template>
}
