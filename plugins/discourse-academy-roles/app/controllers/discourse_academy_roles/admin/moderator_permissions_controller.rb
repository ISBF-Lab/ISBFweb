# frozen_string_literal: true

module DiscourseAcademyRoles::Admin
  class ModeratorPermissionsController < ::Admin::AdminController
    requires_plugin DiscourseAcademyRoles::PLUGIN_NAME

    def index
      settings = DiscourseAcademyRoles::ModeratorPermissions::SETTINGS
      render_json_dump(
        settings: settings,
        values: settings.values.to_h { |name| [name, SiteSetting.public_send(name)] },
      )
    end
  end
end
