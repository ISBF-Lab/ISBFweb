# frozen_string_literal: true

RSpec.describe UserMerger do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :registered_academy_student)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#merge!" do
    it "protects the bound identity when it is the source or target account" do
      [
        [registration.user, member],
        [member, registration.user]
      ].each do |source, target|
        expect do described_class.new(source, target).merge! end.to raise_error(
          Discourse::InvalidParameters,
          I18n.t("academy_roles.student_invites.merge_not_allowed")
        )

        expect(User.exists?(source.id)).to eq(true)
        expect(registration.reload.user_id).to eq(registration.user.id)
      end
    end
  end
end
