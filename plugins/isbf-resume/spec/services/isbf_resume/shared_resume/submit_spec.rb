# frozen_string_literal: true

require_relative "../../../support/isbf_resume_sharing_helpers"

RSpec.describe IsbfResume::SharedResume::Submit do
  include_context "with private shared resume storage"
  include_context "with resume review permissions"

  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to allow_value(true).for(:consent) }
    it { is_expected.not_to allow_values(false, nil).for(:consent) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_length_of(:industry).is_at_most(120) }
    it { is_expected.to validate_length_of(:position).is_at_most(120) }
    it { is_expected.to validate_length_of(:salary).is_at_most(120) }
    it { is_expected.to validate_length_of(:experience).is_at_most(80) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }
    it { is_expected.to allow_values("", nil).for(:description) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :user)

    let(:params) { { file: upload, consent: true }.merge(metadata) }
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new } }
    let(:upload) { sharing_pdf_upload }
    let(:metadata) do
      { title: "", industry: "", position: "", salary: "", experience: "", description: "" }
    end

    context "when the sharing consent contract is invalid" do
      let(:params) { super().merge(consent: false) }

      it "halts without a record or stored PDF" do
        expect { expect(result).to fail_a_contract }.not_to change(IsbfResume::SharedResume, :count)
        expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
      end
    end

    context "when the actor is a visitor" do
      fab!(:acting_user) { nil }

      it "halts at the submission policy" do
        expect(result).to fail_a_policy(:can_submit)
        expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
      end
    end

    context "when the actor is suspended" do
      fab!(:acting_user) do
        Fabricate(:user, suspended_at: 1.hour.ago, suspended_till: 1.day.from_now)
      end

      it { is_expected.to fail_a_policy(:can_submit) }
    end

    context "when the actor is silenced" do
      fab!(:acting_user) { Fabricate(:user, silenced_till: 1.day.from_now) }

      it { is_expected.to fail_a_policy(:can_submit) }
    end

    context "when resume sharing is disabled" do
      before { SiteSetting.isbf_resume_enabled = false }

      it { is_expected.to fail_a_policy(:can_submit) }
    end

    context "when the PDF cannot be parsed" do
      let(:upload) { sharing_raw_upload(content: "%PDF-1.7\nnot a document") }

      it "returns a typed failure and removes the rejected private file" do
        expect { expect(result).to fail_to_find_a_model(:shared_resume) }.not_to change(
          IsbfResume::SharedResume,
          :count,
        )
        expect(result["result.model.shared_resume"].exception).to be_a(
          IsbfResume::SharedPdf::InvalidPdf,
        )
        expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
      end
    end

    context "when all optional details are blank" do
      it "stores a private pending PDF owned by the actor with a filename title" do
        expect { expect(result).to run_successfully }.to change(
          IsbfResume::SharedResume,
          :count,
        ).by(1)
        shared_resume = result.shared_resume.reload
        expect(shared_resume).to have_attributes(
          user_id: acting_user.id,
          status: "pending",
          title: "shared-resume",
          industry: "",
          position: "",
          salary: "",
          experience: "",
          description: "",
          submitted_description: "",
          uploader_name: acting_user.name.presence || acting_user.username,
          uploader_username: acting_user.username,
        )
        expect(shared_resume.reviews).to be_empty
        expect(IsbfResume::SharedResume.published).to be_empty
        expect(File.binread(shared_resume.pdf.available_path, 5)).to eq("%PDF-")
        expect(shared_resume.pdf.preview_path(1)).to eq(nil)
      end
    end

    context "when the uploader provides personal details" do
      let(:metadata) do
        {
          title: "  Finance analyst  ",
          industry: " Banking ",
          position: " Analyst ",
          salary: " 15,000 monthly ",
          experience: " 3 years ",
          description: " My original summary ",
        }
      end

      it "preserves trimmed optional details separately from the reviewed description" do
        expect(result).to run_successfully
        expect(result.shared_resume.reload).to have_attributes(
          title: "Finance analyst",
          industry: "Banking",
          position: "Analyst",
          salary: "15,000 monthly",
          experience: "3 years",
          submitted_description: "My original summary",
          description: "",
          status: "pending",
        )
      end
    end
  end
end
