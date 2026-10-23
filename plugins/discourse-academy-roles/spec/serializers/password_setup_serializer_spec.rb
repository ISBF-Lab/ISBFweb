# frozen_string_literal: true

RSpec.describe CurrentUserSerializer do
  fab!(:user, :academy_password_setup_user)
  fab!(:other_user, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#as_json" do
    it "exposes the reminder only to the eligible current account" do
      serialized = described_class.new(user, scope: user.guardian, root: false).as_json

      expect(serialized[:academy_password_setup_pending]).to eq(true)
    end

    it "hides reminder eligibility from other users" do
      serialized = described_class.new(user, scope: other_user.guardian, root: false).as_json

      expect(serialized[:academy_password_setup_pending]).to eq(false)
      expect(serialized.fetch(:custom_fields)).not_to have_key(
        DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
      )
    end

    it "keeps the pending field out of public profiles" do
      serialized = UserSerializer.new(user, scope: other_user.guardian, root: false).as_json

      expect(serialized).not_to have_key(:academy_password_setup_pending)
      expect(serialized.fetch(:custom_fields)).not_to have_key(
        DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
      )
    end

    it "clears the serialized reminder when a password is set through another flow" do
      user.update!(password: "a password set in account settings 2026")

      serialized = described_class.new(user, scope: user.guardian, root: false).as_json

      expect(serialized[:academy_password_setup_pending]).to eq(false)
    end

    it "hides the reminder from impersonated sessions" do
      user.is_impersonating = true

      serialized = described_class.new(user, scope: user.guardian, root: false).as_json

      expect(serialized[:academy_password_setup_pending]).to eq(false)
    end
  end
end
