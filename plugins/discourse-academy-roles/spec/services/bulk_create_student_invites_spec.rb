# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::BulkCreateStudentInvites do
  describe described_class::Contract, type: :model do
    subject(:contract) { described_class.new(file: upload) }

    let(:upload) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: file_from_contents("000123\n", "students.csv"),
        filename: "students.csv",
        type: "text/csv"
      )
    end

    it { is_expected.to validate_presence_of(:file) }

    it "accepts CSV uploads with case-insensitive extensions" do
      upload.original_filename = "STUDENTS.CSV"

      expect(contract).to be_valid
    end

    it "rejects a non-upload value or a different file extension" do
      ["students.csv", StringIO.new("000123\n")].each do |file|
        expect(described_class.new(file:)).not_to be_valid
      end
      upload.original_filename = "students.xlsx"
      expect(contract).not_to be_valid
    end

    it "accepts one megabyte and rejects larger uploads" do
      upload.tempfile = file_from_contents("0" * 1.megabyte, "limit.csv")
      expect(contract).to be_valid

      upload.tempfile =
        file_from_contents("0" * (1.megabyte + 1), "oversized.csv")
      expect(contract).not_to be_valid
    end

    it do
      is_expected.to allow_values(
        nil,
        1.day.from_now.iso8601,
        36_500.days.from_now.iso8601
      ).for(:expires_at)
    end

    it do
      is_expected.not_to allow_values(
        "invalid",
        1.day.ago.iso8601,
        36_501.days.from_now.iso8601
      ).for(:expires_at)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:official_group, :group)
    fab!(:official_category, :category)
    let(:params) { { file:, expires_at: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:file) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: file_from_contents(content, "students.csv"),
        filename: "students.csv",
        type: "text/csv"
      )
    end
    let(:content) { "学号\n 000123 \n000124\n" }
    let(:expires_at) { 3.days.from_now.iso8601 }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    context "with an invalid contract" do
      let(:file) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "when the actor is a moderator" do
      fab!(:acting_user, :moderator)

      it { is_expected.to fail_a_policy(:can_manage_student_invites) }
    end

    context "when the actor is a member" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage_student_invites) }
    end

    context "when academy membership is disabled" do
      before { SiteSetting.academy_roles_enabled = false }

      it { is_expected.to fail_a_policy(:can_manage_student_invites) }
    end

    context "with a malformed CSV" do
      let(:content) { "\"unterminated\n" }

      it "halts parsing before creating any invitation" do
        expect { result }.not_to change(Invite, :count)
        expect(result).to fail_to_find_a_model(:csv)
        expect(result["result.model.csv"].exception).to be_a(
          DiscourseAcademyRoles::StudentInviteCsv::InvalidFile
        )
      end
    end

    context "with more than 1500 data rows" do
      let(:content) { "student_number\n" + "000123\n" * 1501 }

      it "rejects the entire file before database writes" do
        registrations_before = DiscourseAcademyRoles::StudentRegistration.count

        expect { result }.not_to change(Invite, :count)
        expect(result).to fail_to_find_a_model(:csv)
        expect(result["result.model.csv"].exception).to be_a(
          DiscourseAcademyRoles::StudentInviteCsv::InvalidFile
        )
        expect(DiscourseAcademyRoles::StudentRegistration.count).to eq(
          registrations_before
        )
      end
    end

    context "with a valid upload" do
      it "creates single-use invitations with the requested expiry and no email" do
        email_jobs_before = Jobs::InviteEmail.jobs.size

        expect { result }.to change(
          DiscourseAcademyRoles::StudentRegistration,
          :count
        ).by(2).and change(Invite, :count).by(2)
        expect(result).to run_successfully
        expect(result.csv.results.map { |row| row[:student_number] }).to eq(
          %w[000123 000124]
        )
        expect(
          [
            result.csv.created_count,
            result.csv.skipped_count,
            result.csv.failed_count
          ]
        ).to eq([2, 0, 0])
        registrations =
          DiscourseAcademyRoles::StudentRegistration.where(
            student_number: %w[000123 000124]
          ).includes(:invite)
        registrations.each do |registration|
          expect(registration.issued_by).to eq(acting_user)
          expect(registration.invite).to be_redeemable
          expect(registration.invite.max_redemptions_allowed).to eq(1)
          expect(registration.invite.email).to be_nil
          expect(registration.invite.emailed_status).to eq(
            Invite.emailed_status_types[:not_required]
          )
          expect(registration.invite.expires_at).to eq_time(
            Time.iso8601(expires_at)
          )
        end
        expect(Jobs::InviteEmail.jobs.size).to eq(email_jobs_before)
      end
    end

    context "with exactly 1500 distinct data rows" do
      let(:content) do
        "student_number\n" +
          (1..1500).map { |number| format("%08d", number) }.join("\n")
      end

      it "issues the maximum batch without truncating or emailing records" do
        email_jobs_before = Jobs::InviteEmail.jobs.size

        expect { result }.to change(
          DiscourseAcademyRoles::StudentRegistration,
          :count
        ).by(1500).and change(Invite, :count).by(1500)
        expect(result).to run_successfully
        expect(
          [
            result.csv.created_count,
            result.csv.skipped_count,
            result.csv.failed_count
          ]
        ).to eq([1500, 0, 0])
        expect(result.csv.results.map { |row| row[:student_number] }).to eq(
          (1..1500).map { |number| format("%08d", number) }
        )
        expect(Jobs::InviteEmail.jobs.size).to eq(email_jobs_before)
      end
    end
  end
end
