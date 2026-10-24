import AdminAreaSettings from "discourse/admin/components/admin-area-settings";
import PluginOutlet from "discourse/components/plugin-outlet";
import lazyHash from "discourse/helpers/lazy-hash";
import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DPageHeader from "discourse/ui-kit/d-page-header";
import { i18n } from "discourse-i18n";

export default <template>
  <PluginOutlet
    @name="admin-notification-settings"
    @outletArgs={{lazyHash controller=@controller}}
  >
    <DPageHeader
      @descriptionLabel={{i18n "admin.config.notifications.header_description"}}
      @hideTabs={{true}}
      @titleLabel={{i18n "admin.config.notifications.title"}}
    >
      <:breadcrumbs>
        <DBreadcrumbsItem @label={{i18n "admin_title"}} @path="/admin" />
        <DBreadcrumbsItem
          @label={{i18n "admin.config.notifications.title"}}
          @path="/admin/config/notifications"
        />
      </:breadcrumbs>
    </DPageHeader>

    <div class="admin-config-page__main-area">
      <AdminAreaSettings
        @adminSettingsFilterChangedCallback={{@controller.adminSettingsFilterChangedCallback}}
        @area="notifications"
        @filter={{@controller.filter}}
        @path="/admin/config/notifications"
        @showBreadcrumb={{false}}
      />
    </div>
  </PluginOutlet>
</template>
