# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ReissueStudentInvite do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:student_registration_id) }

    it do
      is_expected.not_to allow_values(
        "invalid",
        1.day.ago.iso8601,
        36_501.days.from_now.iso8601
      ).for(:expires_at)
    end

    it do
      is_expected.to allow_values(
        nil,
        1.day.from_now.iso8601,
        36_500.days.from_now.iso8601
      ).for(:expires_at)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:official_group, :group)
    fab!(:official_category, :category)
    fab!(:student_registration, :academy_student_registration)
    let(:params) { { student_registration_id:, expires_at: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:student_registration_id) { student_registration.id }
    let(:expires_at) { 3.days.from_now.iso8601 }

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

      it "keeps the registered account and invitation intact" do
        expect { result }.not_to change(Invite, :count)
        expect(result).to fail_a_policy(:unredeemed)
        expect(student_registration.reload.invite.invalidated_at).to be_nil
      end
    end

    context "when the student has a pending invitation" do
      it { is_expected.to run_successfully }

      it "replaces the invitation and invalidates the old code" do
        previous_invite = student_registration.invite

        expect { result }.to change(Invite, :count).by(1)

        student_registration.reload
        expect(student_registration.invite).not_to eq(previous_invite)
        expect(student_registration.issued_by).to eq(acting_user)
        expect(student_registration.student_number).to eq(
          result.student_registration.student_number
        )
        expect(student_registration.invite.expires_at).to eq_time(
          Time.iso8601(expires_at)
        )
        expect(student_registration.invite).to be_redeemable
        expect(previous_invite.reload).not_to be_redeemable
      end
    end
  end
end
