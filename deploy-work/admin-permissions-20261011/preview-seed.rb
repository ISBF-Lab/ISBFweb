# frozen_string_literal: true

require "json"
require "securerandom"

unless ActiveRecord::Base.connection_db_config.database ==
         "discourse_admin_permissions_preview_20261011" &&
         ActiveRecord::Base.connection.select_value("SELECT inet_server_port()").to_i == 15_431
  raise "Preview seed must only run in the isolated preview database"
end
raise "Preview already initialized" if User.where("id > 0").exists? || Theme.exists?(4)

art = Rails.root.join("deploy-work/admin-permissions-20261011")
snapshot = JSON.parse(File.read(art.join("current-theme.json")))
configuration =
  JSON.parse(
    File.readlines(art.join("preview-theme-config.txt")).find { |line| line.start_with?("{") },
  )

ActiveRecord::Base.transaction do
  SiteSetting.disable_emails = "yes"
  SiteSetting.force_https = false
  SiteSetting.login_required = true
  SiteSetting.default_locale = "zh_CN"
  SiteSetting.title = "ISBF permission preview"
  SiteSetting.must_approve_users = false

  developer =
    User.create!(
      username: "preview_developer",
      name: "开发者预览",
      email: "developer@example.invalid",
      password: SecureRandom.hex(30),
      admin: true,
      moderator: true,
      active: true,
      approved: true,
      trust_level: 4,
    )
  moderator =
    User.create!(
      username: "preview_moderator",
      name: "管理员预览",
      email: "moderator@example.invalid",
      password: SecureRandom.hex(30),
      moderator: true,
      active: true,
      approved: true,
      trust_level: 1,
    )
  member =
    User.create!(
      username: "preview_member",
      name: "普通用户预览",
      email: "member@example.invalid",
      password: SecureRandom.hex(30),
      active: true,
      approved: true,
      trust_level: 1,
    )
  [developer, moderator, member].each { |user| Group.refresh_automatic_groups_for_user!(user) }

  official =
    Group.create!(name: "preview_official", visibility_level: Group.visibility_levels[:public])
  Group.create!(name: "alumni", visibility_level: Group.visibility_levels[:public])
  {
    5 => ["Campus events", "campus-events"],
    6 => %w[Official official],
    7 => %w[Learning learning],
    8 => %w[Marketplace marketplace],
  }.each do |id, (name, slug)|
    category = Category.create!(id: id, name: name, slug: slug, user: developer)
    permissions = { everyone: CategoryGroup.permission_types[:full] }
    if [5, 6, 7].include?(id)
      permissions[:everyone] = CategoryGroup.permission_types[:readonly]
      permissions[:staff] = CategoryGroup.permission_types[:full]
      permissions[official.name] = CategoryGroup.permission_types[:full] if id == 6
    end
    category.set_permissions(permissions)
    category.save!
  end
  SiteSetting.academy_official_group = official.id
  SiteSetting.academy_official_category = 6
  SiteSetting.academy_roles_enabled = true
  SiteSetting.isbf_learning_category_id = 7
  SiteSetting.isbf_marketplace_category_id = 8
  DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.each do |name|
    SiteSetting.public_send("#{name}=", false)
  end

  theme =
    Theme.new(
      id: snapshot.fetch("theme_id"),
      name: "ISBF Campus Feed permission preview",
      user_id: developer.id,
      user_selectable: true,
      color_scheme_id: 1,
      dark_color_scheme_id: 2,
    )
  snapshot
    .fetch("fields")
    .each do |field|
      theme.theme_fields.build(field.slice("id", "name", "target_id", "type_id", "value"))
    end
  theme.save!
  configuration
    .fetch("settings")
    .each do |setting|
      next if setting["name"] == "brand_logo"
      value = setting["name"] == "brand_show_logo" ? false : setting.fetch("value")
      theme.update_setting(setting.fetch("name"), value)
    end
  SiteSetting.default_theme_id = theme.id

  2.times do |index|
    PostCreator.create!(
      developer,
      title: "Synthetic permission preview product #{index + 1}",
      raw: "This product is synthetic data for the isolated permission preview.",
      category: 8,
      isbf_marketplace_price: "88.00",
      isbf_marketplace_images: [],
      isbf_marketplace_home: true,
    )
  end

  payload = {
    theme_id: theme.id,
    fields:
      snapshot
        .fetch("fields")
        .filter_map do |field|
          next if [200, 201, 206, 305, 306, 316].exclude?(field["id"])
          {
            id: field.fetch("id"),
            name: field.fetch("name"),
            before: field.fetch("value"),
            after:
              File.read(
                Rails.root.join("themes/isbf-campus-feed/javascripts", field.fetch("name")),
              ),
          }
        end,
    activity_category: 5,
    activity_before: nil,
  }
  File.write(art.join("preview-theme-update.json"), JSON.generate(payload))
end
puts JSON.generate(synthetic_users: 3, synthetic_products: 2, production_user_data_copied: false)
