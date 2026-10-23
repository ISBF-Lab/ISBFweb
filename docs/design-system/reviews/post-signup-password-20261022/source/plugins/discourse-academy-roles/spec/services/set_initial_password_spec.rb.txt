# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::SetInitialPassword do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:password_confirmation) }
    it { is_expected.to validate_confirmation_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_most(User.max_password_length) }

    it do
      is_expected.to validate_length_of(:password_confirmation).is_at_most(User.max_password_length)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:invite) { Fabricate(:invite, email: "initial-password-invitation@example.com") }
    fab!(:user) { Fabricate(:academy_password_setup_user, email: invite.email) }
    fab!(:official_group, :group)
    fab!(:official_category, :category)

    let(:params) { { password:, password_confirmation: password } }
    let(:dependencies) { { guardian: user.guardian, trusted_session: } }
    let(:password) { "an initial secure password 2026" }
    let(:trusted_session) { true }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    context "with an invalid contract" do
      let(:password) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "without an authenticated user" do
      let(:dependencies) { { guardian: Guardian.new, trusted_session: } }

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "when local logins are disabled" do
      before { SiteSetting.enable_local_logins = false }

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "when the plugin is disabled" do
      before { SiteSetting.academy_roles_enabled = false }

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "when DiscourseConnect is enabled" do
      before do
        SiteSetting.discourse_connect_url = "https://example.com/sso"
        SiteSetting.discourse_connect_secret = "a secure shared secret"
        SiteSetting.enable_discourse_connect = true
      end

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "with an inactive account" do
      fab!(:user) { Fabricate(:academy_password_setup_user, active: false) }

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "with a suspended account" do
      fab!(:user) { Fabricate(:academy_password_setup_user, suspended_till: 1.day.from_now) }

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "with a staged account" do
      fab!(:user) { Fabricate(:academy_password_setup_user, staged: true) }

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "with an anonymous account" do
      fab!(:user) do
        Fabricate(
          :anonymous,
          password: nil,
          custom_fields: {
            DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD => true,
          },
        )
      end

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    if defined?(IsbfAnonymous::PoolAccount)
      context "with a pooled anonymous account" do
        fab!(:user) { IsbfAnonymous::PoolAccount.for_slot!(999).user }

        it { is_expected.to fail_a_policy(:can_set_own_password) }
      end
    end

    context "with an impersonated account" do
      before { user.is_impersonating = true }

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "without forum approval" do
      before do
        SiteSetting.must_approve_users = true
        user.update!(approved: false)
      end

      it { is_expected.to fail_a_policy(:can_set_own_password) }
    end

    context "when the account was deleted" do
      before { user.destroy! }

      it { is_expected.to fail_to_find_a_model(:user) }
    end

    context "without a pending reminder" do
      before { DiscourseAcademyRoles::PasswordSetup.complete_for(user) }

      it { is_expected.to fail_a_policy(:password_setup_pending) }
    end

    context "when another request has already set the password" do
      let(:previous_password) { "a previously saved password 2026" }

      before do
        dependencies
        user.custom_fields
        User.find(user.id).update!(password: previous_password)
      end

      it "rejects the stale request and preserves the saved password" do
        expect(result).to fail_a_policy(:password_setup_pending)
        expect(user.reload.confirm_password?(previous_password)).to eq(true)
      end
    end

    context "when another request has dismissed the reminder" do
      before do
        dependencies
        user.custom_fields
        DiscourseAcademyRoles::DismissPasswordSetup.call(params: {}, guardian: user.guardian)
      end

      it "rejects the stale request without creating a password" do
        expect(result).to fail_a_policy(:password_setup_pending)
        expect(user.reload).not_to have_password
      end
    end

    context "without a trusted session" do
      let(:trusted_session) { false }

      it { is_expected.to fail_a_policy(:trusted_session) }
    end

    context "with a configured second factor" do
      before { Fabricate(:user_second_factor_totp, user:) }

      it { is_expected.to fail_a_policy(:trusted_session) }
    end

    context "with a configured security key" do
      before { Fabricate(:user_security_key, user:) }

      it { is_expected.to fail_a_policy(:trusted_session) }
    end

    context "with a password rejected by the user model" do
      let(:password) { "abc" }

      it "preserves the passwordless account, reminder, and login credentials" do
        token = UserAuthToken.generate!(user_id: user.id)
        email_token = Fabricate(:email_token, user:)

        expect { result }.not_to change {
          UserHistory.where(target_user: user, action: UserHistory.actions[:change_password]).count
        }
        expect(result).to fail_a_step(:save_password)
        expect(user.reload).not_to have_password
        expect(DiscourseAcademyRoles::PasswordSetup.pending?(user)).to eq(true)
        expect(UserAuthToken.exists?(token.id)).to eq(true)
        expect(email_token.reload).not_to be_expired
        expect(invite.reload.invalidated_at).to be_nil
      end
    end

    context "when the account and password are eligible" do
      it { is_expected.to run_successfully }

      it "saves a usable password and completes the reminder" do
        result

        expect(user.reload.confirm_password?(password)).to eq(true)
        expect(user.custom_fields).not_to have_key(
          DiscourseAcademyRoles::PasswordSetup::PENDING_FIELD,
        )
      end

      it "revokes previous login credentials and invitations" do
        token = UserAuthToken.generate!(user_id: user.id)
        email_token = Fabricate(:email_token, user:)

        result

        expect(UserAuthToken.exists?(token.id)).to eq(false)
        expect(email_token.reload).to be_expired
        expect(invite.reload.invalidated_at).to be_present
      end

      it "records the account's own password change" do
        expect { result }.to change {
          UserHistory.where(
            target_user: user,
            acting_user: user,
            action: UserHistory.actions[:change_password],
          ).count
        }.by(1)
      end
    end
  end
end
