# frozen_string_literal: true

require "digest"
require "json"

payload = JSON.parse(File.read(ARGV.fetch(0)))
mode = ARGV.fetch(1)
raise "Unknown theme update mode" if %w[apply rollback check].exclude?(mode)
raise "Active theme changed" unless SiteSetting.default_theme_id == payload.fetch("theme_id")

theme = Theme.find(payload.fetch("theme_id"))
fields = payload.fetch("fields")
unless fields.map { |field| field.fetch("id") }.sort == [200, 201, 206, 305, 306, 316]
  raise "Unexpected theme update scope"
end

before =
  ThemeField
    .pluck(:id, :value)
    .to_h
    .transform_values { |value| Digest::SHA256.hexdigest(value.to_s) }
if mode == "apply"
  if DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.any? { |name|
       SiteSetting.public_send(name)
     }
    raise "Initial moderator permissions are not disabled"
  end
end
Theme.transaction do
  fields.each do |item|
    field = theme.theme_fields.find(item.fetch("id"))
    unless field.name == item.fetch("name") && field.target_id == 6 && field.type_id == 6
      raise "Theme field identity changed"
    end

    expected = mode == "rollback" ? item.fetch("after") : item.fetch("before")
    next if mode == "rollback" && field.value == item.fetch("before")
    raise "Theme field source changed" unless field.value == expected
    next if mode == "check"

    value = mode == "rollback" ? item.fetch("before") : item.fetch("after")
    theme.set_field(target: :extra_js, name: field.name, type_id: field.type_id, value:)
  end
  theme.save! unless mode == "check"
  if mode == "apply" && SiteSetting.academy_activity_category.to_i.zero?
    unless Category.exists?(payload.fetch("activity_category"))
      raise "Configured activity category unavailable"
    end
    SiteSetting.academy_activity_category = payload.fetch("activity_category")
  elsif mode == "rollback"
    if payload["activity_before"]
      SiteSetting.academy_activity_category = payload.fetch("activity_before")
    else
      SiteSetting.remove_override!(:academy_activity_category)
    end
  end
end
after =
  ThemeField
    .pluck(:id, :value)
    .to_h
    .transform_values { |value| Digest::SHA256.hexdigest(value.to_s) }
allowed_ids = fields.map { |field| field.fetch("id") }
raise "Theme field inventory changed" unless before.keys.sort == after.keys.sort
unless before.except(*allowed_ids) == after.except(*allowed_ids)
  raise "Unrelated theme field changed"
end

permissions =
  DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.to_h do |name|
    [name, SiteSetting.public_send(name)]
  end
if mode == "apply"
  raise "Initial moderator permissions are not disabled" if permissions.values.any?
end
puts JSON.generate(
       theme_id: theme.id,
       updated_fields: mode == "check" ? 0 : fields.length,
       unrelated_fields_preserved: true,
       permissions_disabled: permissions.values.none?,
       activity_category: SiteSetting.academy_activity_category,
     )
