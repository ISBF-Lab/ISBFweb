import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import SiteSettingComponent from "discourse/admin/components/site-setting";
import SiteSetting from "discourse/admin/models/site-setting";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import { i18n } from "discourse-i18n";

const ENTRY_KEYS = [
  "learning_resources",
  "library",
  "courses",
  "careers",
  "resume",
  "campus_services",
  "student_identity",
  "alumni",
  "marketplace",
  "teamup",
  "mbti",
  "ai_assistant",
  "guides",
];

export default class WorkbenchMaintenance extends Component {
  @service adminSiteSettingStore;
  @service currentUser;
  @service router;

  @tracked expanded = false;
  @tracked loading = false;
  @tracked settings;

  get showPanel() {
    return (
      this.currentUser?.admin &&
      this.args.outletArgs?.theme?.default &&
      this.router.currentRouteName === "adminCustomizeThemes.show.schema" &&
      this.router.currentRoute?.params?.setting_name === "workbench_entries"
    );
  }

  @action
  async toggle() {
    this.expanded = !this.expanded;
    if (!this.expanded || this.settings || this.loading) {
      return;
    }

    this.loading = true;
    try {
      const names = ENTRY_KEYS.map((key) => `isbf_workbench_pause_${key}`);
      const categories = await SiteSetting.findAll({ names });
      const byName = new Map(
        categories.flatMap((category) =>
          category.siteSettings.map((setting) => [setting.setting, setting])
        )
      );
      const settings = ENTRY_KEYS.map((key) => {
        const setting = byName.get(`isbf_workbench_pause_${key}`);
        if (!setting) {
          throw new Error(`Missing workbench maintenance setting: ${key}`);
        }
        setting.set("label", i18n(`isbf_workbench_maintenance.entries.${key}`));
        return setting;
      });
      if (!this.isDestroying) {
        this.adminSiteSettingStore.register(settings);
        this.settings = settings;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }

  <template>
    {{#if this.showPanel}}
      <section
        aria-label={{i18n "isbf_workbench_maintenance.title"}}
        class="isbf-workbench-maintenance control-unit"
      >
        <DButton
          aria-controls="isbf-workbench-maintenance-settings"
          aria-expanded={{if this.expanded "true" "false"}}
          class="btn-default isbf-workbench-maintenance__toggle"
          @action={{this.toggle}}
          @icon={{if this.expanded "angle-up" "angle-down"}}
          @label="isbf_workbench_maintenance.title"
        />
        {{#if this.expanded}}
          <div id="isbf-workbench-maintenance-settings">
            <p>{{i18n "isbf_workbench_maintenance.description"}}</p>
            <DConditionalLoadingSpinner @condition={{this.loading}}>
              <div class="form-horizontal settings">
                {{#each this.settings key="setting" as |setting|}}
                  <SiteSettingComponent @setting={{setting}} />
                {{/each}}
              </div>
            </DConditionalLoadingSpinner>
          </div>
        {{/if}}
      </section>
    {{/if}}
  </template>
}
