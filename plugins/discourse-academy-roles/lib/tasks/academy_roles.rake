# frozen_string_literal: true

desc "Configure a closed academy site with official and ordinary categories"
task "academy_roles:setup" => :environment do
  official_group =
    Group.find_or_create_by!(name: "academy_official") { |group| group.full_name = "学院官方认证" }
  official_group.update!(
    public_admission: false,
    public_exit: false,
    allow_membership_requests: false,
    automatic_membership_email_domains: "",
    grant_trust_level: 0,
  )

  ordinary_category =
    Category.find_or_create_by!(slug: "general") do |category|
      category.name = "普通"
      category.user = Discourse.system_user
    end
  official_category =
    Category.find_or_create_by!(slug: "official") do |category|
      category.name = "官方"
      category.user = Discourse.system_user
    end

  ordinary_category.update!(name: "普通")
  official_category.update!(name: "官方")

  ordinary_category.set_permissions(everyone: :full)
  official_category.set_permissions({ everyone: :create_post }.merge(official_group => :full))

  SiteSetting.login_required = true
  SiteSetting.invite_only = true
  SiteSetting.enable_local_logins = true
  SiteSetting.must_approve_users = false
  SiteSetting.default_trust_level = 0
  SiteSetting.default_invitee_trust_level = 0
  SiteSetting.create_topic_allowed_groups = "1|2|10"
  SiteSetting.approve_post_count = 0
  SiteSetting.approve_unless_allowed_groups = "1|2|10"
  SiteSetting.approve_new_topics_unless_allowed_groups = "1|2|10"
  SiteSetting.auto_silence_fast_typers_on_first_post = false
  SiteSetting.flag_post_allowed_groups = "1|2|10"
  SiteSetting.personal_message_enabled_groups = "1|2|10"
  SiteSetting.invite_allowed_groups = "1|2"
  SiteSetting.edit_all_topic_groups = "1|2"
  SiteSetting.edit_all_post_groups = "1|2"
  SiteSetting.edit_wiki_post_allowed_groups = "1|2"
  SiteSetting.moderators_manage_groups = false
  SiteSetting.allow_uncategorized_topics = false
  SiteSetting.academy_official_group = official_group.id
  SiteSetting.academy_official_category = official_category.id

  User
    .where(admin: false, moderator: false)
    .find_each { |user| DiscourseAcademyRoles.lock_member_trust_level(user) }

  SiteSetting.academy_roles_enabled = true

  Badge.where(id: [Badge::BasicUser, Badge::Member, Badge::Regular, Badge::Leader]).update_all(
    enabled: false,
  )

  puts "Academy roles configured. Site admins can issue one-use invitations and manage #{official_group.name}."
end
