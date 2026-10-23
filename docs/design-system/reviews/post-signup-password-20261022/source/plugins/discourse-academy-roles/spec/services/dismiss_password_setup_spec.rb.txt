# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::DismissPasswordSetup do
  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:user, :academy_password_setup_user)
    fab!(:official_group, :group)
    fab!(:official_category, :category)

    let(:params) { {} }
    let(:dependencies) { { guardian: user.guardian } }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    context "without an authenticated user" do
      let(:dependencies) { { guardian: Guardian.new } }

      it { is_expected.to fail_a_policy(:can_dismiss_own_password_setup) }
    end

    context "with an impersonated account" do
      before { user.is_impersonating = true }

      it { is_expected.to fail_a_policy(:can_dismiss_own_password_setup) }
    end

    context "when the account was deleted" do
      before { user.destroy! }

      it { is_expected.to fail_to_find_a_model(:user) }
    end

    context "when the account can dismiss its reminder" do
      it { is_expected.to run_successfully }

      it "persists the dismissal without changing the password or login" do
        token = UserAuthToken.generate!(user_id: user.id)

        result

        expect(user.reload.custom_fields).not_to have_key(
          DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
        )
        expect(user).not_to have_password
        expect(UserAuthToken.exists?(token.id)).to eq(true)
      end
    end

    context "when the reminder has already been dismissed" do
      before { DiscourseAcademyRoles::PasswordSetup.complete_for(user) }

      it { is_expected.to run_successfully }
    end
  end
end
