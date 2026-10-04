# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentRegistration do
  fab!(:student_registration, :academy_student_registration)

  describe "#save" do
    it "trims surrounding whitespace without changing leading zeroes" do
      invite = Fabricate(:invite, email: nil)
      registration =
        Fabricate.build(
          :academy_student_registration,
          student_number: " 000987 ",
          invite:,
          issued_by: invite.invited_by
        )

      expect(registration.save).to eq(true)
      expect(registration.reload.student_number).to eq("000987")
    end

    it "preserves the student number after issuance" do
      original_student_number = student_registration.student_number
      student_registration.student_number = "replacement"

      expect(student_registration.save).to eq(false)
      expect(student_registration.reload.student_number).to eq(
        original_student_number
      )
    end

    it "preserves all identity fields after redemption" do
      registration = Fabricate(:registered_academy_student)
      original_identity =
        registration.attributes.slice(
          "student_number",
          "user_id",
          "invite_id",
          "registered_at"
        )
      registration.assign_attributes(
        user: Fabricate(:user),
        invite: Fabricate(:invite, email: nil),
        registered_at: nil
      )

      expect(registration.save).to eq(false)
      expect(
        registration.reload.attributes.slice(*original_identity.keys)
      ).to eq(original_identity)
    end

    it "protects the account binding when the registration timestamp is missing" do
      user = Fabricate(:user)
      registration = Fabricate(:academy_student_registration, user:)
      registration.user = Fabricate(:user)

      expect(registration.save).to eq(false)
      expect(registration.reload.user).to eq(user)
      expect(registration.registered_at).to be_nil
    end

    it "keeps student numbers unique including leading zeroes" do
      duplicate =
        Fabricate.build(
          :academy_student_registration,
          student_number: student_registration.student_number
        )

      expect(duplicate.save).to eq(false)
      expect(duplicate.errors[:student_number]).to be_present
    end

    it "reserves at most one student number per account" do
      registered = Fabricate(:registered_academy_student)
      duplicate =
        Fabricate.build(:registered_academy_student, user: registered.user)

      expect(duplicate.save).to eq(false)
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe "#status" do
    it "reports a pending invitation" do
      expect(student_registration.status).to eq("pending")
    end

    it "reports an expired invitation" do
      student_registration.invite.update!(expires_at: 1.day.ago)

      expect(student_registration.reload.status).to eq("expired")
    end

    it "reports a revoked or soft-deleted invitation" do
      student_registration.invite.update!(invalidated_at: Time.current)
      expect(student_registration.reload.status).to eq("revoked")

      student_registration.invite.trash!
      expect(student_registration.reload.invite).to be_present
      expect(student_registration.status).to eq("revoked")
    end

    it "retains the registered status after deleting the account and invitation" do
      registration = Fabricate(:registered_academy_student)
      student_number = registration.student_number
      registration.user.destroy!
      registration.invite.destroy!

      expect(registration.reload.status).to eq("registered")
      expect(registration.student_number).to eq(student_number)
      expect(registration).to be_registered
    end
  end
end
