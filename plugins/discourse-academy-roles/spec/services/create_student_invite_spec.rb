# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::CreateStudentInvite do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:student_number) }
    it { is_expected.to validate_length_of(:student_number).is_at_most(64) }

    it do
      is_expected.to allow_values("000123", " A2026001 ").for(:student_number)
    end

    it { is_expected.not_to allow_values("", "  ").for(:student_number) }

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

    it "trims the student number while preserving leading zeroes" do
      contract = described_class.new(student_number: " 000123 ")

      expect(contract).to be_valid
      expect(contract.student_number).to eq("000123")
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:official_group, :group)
    fab!(:official_category, :category)
    let(:params) { { student_number:, expires_at: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:student_number) { " 000123 " }
    let(:expires_at) { 2.days.from_now.iso8601 }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    context "with an invalid contract" do
      let(:student_number) { " " }

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

    context "when the student number is already reserved" do
      fab!(:existing_registration) do
        Fabricate(:academy_student_registration, student_number: "000123")
      end

      it "rejects the duplicate and rolls back the newly generated invite" do
        expect { result }.not_to change(Invite, :count)
        expect(result).to fail_with_an_invalid_model(:student_registration)
        expect(existing_registration.reload.student_number).to eq("000123")
      end
    end

    context "with a valid request" do
      it { is_expected.to run_successfully }

      it "reserves the student number with an unbound single-use invite" do
        expect { result }.to change(
          DiscourseAcademyRoles::StudentRegistration,
          :count
        ).by(1).and change(Invite, :count).by(1)

        registration = result.student_registration
        expect(registration.student_number).to eq("000123")
        expect(registration.issued_by).to eq(acting_user)
        expect(registration.user).to be_nil
        expect(registration.invite.max_redemptions_allowed).to eq(1)
        expect(registration.invite.email).to be_nil
        expect(registration.invite.domain).to be_nil
        expect(registration.invite.expires_at).to eq_time(
          Time.iso8601(expires_at)
        )
        expect(registration.invite).to be_redeemable
      end
    end
  end
end
