# frozen_string_literal: true

class AcademyRolesEnabledValidator
  def initialize(_options = {})
  end

  def valid_value?(value)
    return true unless ActiveModel::Type::Boolean.new.cast(value)

    Group.exists?(id: SiteSetting.academy_official_group.to_i) &&
      Category.exists?(id: SiteSetting.academy_official_category.to_i)
  end

  def error_message
    I18n.t("site_settings.errors.academy_roles_not_configured")
  end
end
