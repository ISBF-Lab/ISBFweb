# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::CreateImport do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.not_to allow_values(nil, 0, -1).for(:frame_id) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:recipient, :user)
    fab!(:frame, :avatar_frame)
    let(:params) { { frame_id: frame.id, file: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:contents) do
      "\uFEFFusername\n#{recipient.username}\n#{recipient.email}\nunknown_person\n\n"
    end
    let(:csv_file) { Tempfile.new(%w[avatar-frame .csv]) }
    let(:file) { Rack::Test::UploadedFile.new(csv_file.path, "text/csv") }

    before do
      csv_file.write(contents)
      csv_file.flush
    end

    after { csv_file.close! }

    context "when the actor is a regular user" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "without a file" do
      let(:file) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "when the frame is missing" do
      let(:params) { { frame_id: frame.id + 100_000, file: } }

      it { is_expected.to fail_to_find_a_model(:frame) }
    end

    context "when the frame is public" do
      fab!(:frame) { Fabricate(:avatar_frame, access_mode: "public") }

      it { is_expected.to fail_a_policy(:can_award) }
    end

    context "with a valid CSV" do
      it "deduplicates matched users and enqueues a single import" do
        expect { result }.to change { Jobs::AvatarFramesImport.jobs.length }.by(1)
        expect(result).to run_successfully
        expect(result.import).to have_attributes(
          user_ids: [recipient.id],
          matched_count: 1,
          duplicate_count: 1,
          unmatched_count: 1,
          unmatched_entries: ["unknown_person"],
          status: "queued",
        )
      end
    end

    context "with a malformed CSV" do
      let(:contents) { "username\n\"unterminated\n" }

      it "rejects the file before creating an import or enqueuing work" do
        expect(result).to fail_to_find_a_model(:import)
        expect(DiscourseAvatarFrames::Import.count).to eq(0)
        expect(Jobs::AvatarFramesImport.jobs).to be_empty
      end
    end
  end
end
