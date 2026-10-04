# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::RevokeStudentInvite do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:student_registration_id) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:official_group, :group)
    fab!(:official_category, :category)
    fab!(:student_registration, :academy_student_registration)
    let(:params) { { student_registration_id: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:student_registration_id) { student_registration.id }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    context "with an invalid contract" do
      let(:student_registration_id) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "when the actor is a moderator" do
      fab!(:acting_user, :moderator)

      it { is_expected.to fail_a_policy(:can_manage_student_invites) }
    end

    context "when academy membership is disabled" do
      before { SiteSetting.academy_roles_enabled = false }

      it { is_expected.to fail_a_policy(:can_manage_student_invites) }
    end

    context "when the registration cannot be found" do
      let(:student_registration_id) { 0 }

      it { is_expected.to fail_to_find_a_model(:student_registration) }
    end

    context "when the student is already registered" do
      fab!(:student_registration, :registered_academy_student)

      it "rejects revocation of the registered identity" do
        expect(result).to fail_a_policy(:unredeemed)
        expect(student_registration.reload.invite.invalidated_at).to be_nil
      end
    end

    context "when the student has a pending invitation" do
      it { is_expected.to run_successfully }

      it "invalidates the code while retaining the reserved student number" do
        expect { result }.not_to change(
          DiscourseAcademyRoles::StudentRegistration,
          :count
        )
        expect(student_registration.reload.status).to eq("revoked")
        expect(student_registration.invite).not_to be_redeemable
      end
    end
  end
end
