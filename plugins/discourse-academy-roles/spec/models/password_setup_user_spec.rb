# frozen_string_literal: true

RSpec.describe User do
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe ".create!" do
    it "marks a newly created passwordless account for the reminder" do
      user = nil
      events = DiscourseEvent.track_events(:user_created) { user = Fabricate(:user, password: nil) }

      expect(events.map { |event| event[:params].first }).to include(user)
      expect(DiscourseAcademyRoles::PasswordSetup.pending?(user.reload)).to eq(true)
    end

    it "leaves new accounts with a password outside the reminder flow" do
      user = Fabricate(:user)

      expect(user.reload.custom_fields).not_to have_key(
        DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
      )
    end

    it "leaves staged and system accounts outside the reminder flow" do
      users = [Fabricate(:staged, password: nil), Fabricate(:bot, password: nil)]

      expect(
        users.map do |user|
          user.reload.custom_fields[DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD]
        end,
      ).to eq([nil, nil])
    end

    it "does not backfill accounts created before the feature was enabled" do
      SiteSetting.academy_roles_enabled = false
      user = Fabricate(:user, password: nil)

      SiteSetting.academy_roles_enabled = true
      user.update!(name: "Existing account")

      expect(user.reload.custom_fields).not_to have_key(
        DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
      )
    end

    it "does not mark new accounts when local logins are disabled" do
      SiteSetting.enable_local_logins = false

      user = Fabricate(:user, password: nil)

      expect(user.reload.custom_fields).not_to have_key(
        DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
      )
    end

    it "does not mark new DiscourseConnect accounts" do
      SiteSetting.discourse_connect_url = "https://example.com/sso"
      SiteSetting.discourse_connect_secret = "a secure shared secret"
      SiteSetting.enable_discourse_connect = true

      user = Fabricate(:user, password: nil)

      expect(user.reload.custom_fields).not_to have_key(
        DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
      )
    end
  end

  describe "#update!" do
    it "consumes the reminder when another flow sets a password and preserves other custom fields" do
      user = Fabricate(:academy_password_setup_user)
      user.upsert_custom_fields("academy_name_color_enabled" => true)

      user.update!(password: "a password set in account settings 2026")

      expect(user.reload.custom_fields).to include("academy_name_color_enabled" => true)
      expect(user.custom_fields).not_to have_key(
        DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
      )

      user.user_password.destroy!

      expect(DiscourseAcademyRoles::PasswordSetup.pending?(user.reload)).to eq(false)
    end
  end
end
