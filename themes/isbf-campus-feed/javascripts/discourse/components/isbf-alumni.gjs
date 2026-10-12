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
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { alumniConfig, alumniLocation, alumniRegions } from "../lib/alumni";
import ISBFAlumniMap from "./isbf-alumni-map";
import ISBFAlumniProfile from "./isbf-alumni-profile";

export default class ISBFAlumni extends Component {
  @service appEvents;
  @service currentUser;
  @service site;

  @tracked country = "CN";
  @tracked region = "";
  @tracked users = [];
  @tracked loading = false;
  @tracked error = false;
  @tracked hasMore = false;
  @tracked editing = false;
  @tracked geography = null;
  @tracked geographyError = false;

  #page = 0;
  #request = 0;
  #trigger;

  constructor() {
    super(...arguments);
    if (this.config && this.currentUser) {
      this.loadGeography();
      this.loadDirectory();
    } else if (this.config) {
      this.login();
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
  }

  get config() {
    return alumniConfig(this.site);
  }

  get mapConfig() {
    return this.geography
      ? { ...this.config, countries: this.geography.countries }
      : null;
  }

  get countries() {
    return this.mapConfig?.countries || this.config?.countries || [];
  }

  get regions() {
    return alumniRegions(this.mapConfig, this.country);
  }

  get directoryUsers() {
    return this.users.map((user) => ({
      ...user,
      location: alumniLocation(user),
      href: `/u/${encodeURIComponent(user.username)}`,
    }));
  }

  @action
  async loadGeography() {
    this.geographyError = false;
    try {
      const response = await ajax(this.config.geography_url);
      if (!this.isDestroying) {
        this.geography = response;
      }
    } catch {
      if (!this.isDestroying) {
        this.geographyError = true;
      }
    }
  }

  @action
  login() {
    this.appEvents.trigger("show-login");
  }

  @action
  countryChanged(event) {
    this.selectLocation({ country: event.target.value });
  }

  @action
  regionChanged(event) {
    this.selectLocation({ country: this.country, region: event.target.value });
  }

  @action
  selectLocation({ country = "", region = "" }) {
    this.country = country;
    this.region = country === "CN" ? region : "";
    this.loadDirectory();
  }

  @action
  async loadDirectory(append = false) {
    if (!this.currentUser || !this.config || (append && this.loading)) {
      return;
    }
    const request = ++this.#request;
    const page = append ? this.#page + 1 : 1;
    this.loading = true;
    this.error = false;
    if (!append) {
      this.users = [];
      this.hasMore = false;
    }
    try {
      const response = await ajax("/isbf/alumni/directory", {
        data: {
          country: this.country,
          region: this.region,
          page,
        },
      });
      if (request !== this.#request) {
        return;
      }
      this.users = append
        ? [...this.users, ...response.users]
        : response.users || [];
      this.hasMore = response.has_more === true;
      this.#page = page;
    } catch {
      if (request === this.#request) {
        this.error = true;
      }
    } finally {
      if (request === this.#request) {
        this.loading = false;
      }
    }
  }

  @action
  retry() {
    this.loadDirectory(this.users.length > 0);
  }

  @action
  openProfile() {
    this.#trigger = document.activeElement;
    this.editing = true;
  }

  @action
  closeProfile() {
    this.editing = false;
    this.#trigger?.focus();
  }

  @action
  profileSaved() {
    this.closeProfile();
    this.loadDirectory();
  }

  <template>
    <main class="isbf-alumni">
      <header class="isbf-alumni__header">
        <a class="isbf-alumni__back" href="/isbf/workbench">
          {{dIcon "arrow-left"}}<h1>{{i18n
              (themePrefix "isbf_v2.workbench_alumni")
            }}</h1>
        </a>
        {{#if this.currentUser.isbf_alumni_member}}
          {{#if this.mapConfig}}
            <DButton
              @action={{this.openProfile}}
              @translatedLabel={{i18n
                (themePrefix "isbf_v2.alumni_my_profile")
              }}
            />
          {{/if}}
        {{/if}}
      </header>
      {{#if this.currentUser}}
        {{#if this.config}}
          {{#if this.editing}}<ISBFAlumniProfile
              @config={{this.mapConfig}}
              @onClose={{this.closeProfile}}
              @onSaved={{this.profileSaved}}
            />{{/if}}
          <div class="isbf-alumni__filters">
            <label>{{i18n (themePrefix "isbf_v2.alumni_country")}}
              <select
                value={{this.country}}
                {{on "change" this.countryChanged}}
              >
                <option value="">{{i18n
                    (themePrefix "isbf_v2.alumni_all")
                  }}</option>
                {{#each this.countries as |country|}}<option
                    selected={{eq this.country country.code}}
                    value={{country.code}}
                  >{{country.name}}</option>{{/each}}
              </select>
            </label>
            {{#if this.regions.length}}<label>{{i18n
                  (themePrefix "isbf_v2.alumni_region")
                }}
                <select
                  value={{this.region}}
                  {{on "change" this.regionChanged}}
                ><option value="">{{i18n
                      (themePrefix "isbf_v2.alumni_all")
                    }}</option>
                  {{#each this.regions as |region|}}<option
                      selected={{eq this.region region.code}}
                      value={{region.code}}
                    >{{region.name}}</option>{{/each}}
                </select>
              </label>{{/if}}
          </div>
          {{#if this.mapConfig}}<ISBFAlumniMap
              @config={{this.mapConfig}}
              @country={{this.country}}
              @onSelect={{this.selectLocation}}
              @region={{this.region}}
            />{{else if this.geographyError}}<p
              class="isbf-alumni__notice"
              role="alert"
            >{{i18n (themePrefix "isbf_v2.alumni_map_error")}}</p><DButton
              @action={{this.loadGeography}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
            />{{/if}}
          <section
            aria-busy={{this.loading}}
            aria-label={{i18n (themePrefix "isbf_v2.alumni_directory")}}
            class="isbf-alumni__directory"
          >
            {{#each this.directoryUsers key="id" as |user|}}
              <article class="isbf-alumni__person"><a
                  href={{user.href}}
                >{{user.display_name}}</a><span>{{user.location}}</span><span
                >{{user.industry}}</span></article>
            {{/each}}
            {{#if this.loading}}<p role="status">{{i18n
                  (themePrefix "isbf_v2.learning_loading")
                }}</p>
            {{else if this.error}}<p role="alert">{{i18n
                  (themePrefix "isbf_v2.alumni_load_error")
                }}</p><DButton
                @action={{this.retry}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
              />
            {{else if this.hasMore}}<DButton
                @action={{fn this.loadDirectory true}}
                @translatedLabel={{i18n (themePrefix "isbf_v2.load_more")}}
              />
            {{else if (eq this.users.length 0)}}<p>{{i18n
                  (themePrefix "isbf_v2.alumni_empty")
                }}</p>{{/if}}
          </section>
        {{else}}<p class="isbf-alumni__notice">{{i18n
              (themePrefix "isbf_v2.alumni_unavailable")
            }}</p>{{/if}}
      {{else}}<div class="isbf-alumni__notice"><p>{{i18n
              (themePrefix "isbf_v2.alumni_login")
            }}</p><DButton
            @action={{this.login}}
            @translatedLabel={{i18n "log_in"}}
          /></div>{{/if}}
    </main>
  </template>
}
