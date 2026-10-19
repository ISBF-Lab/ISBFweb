# frozen_string_literal: true

require_relative "../../../support/isbf_resume_sharing_helpers"

RSpec.describe IsbfResume::SharedResume::Submit do
  include_context "with private shared resume storage"
  include_context "with resume review permissions"

  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:download_url) }
    it { is_expected.to allow_value(true).for(:consent) }
    it { is_expected.not_to allow_values(false, nil).for(:consent) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_length_of(:industry).is_at_most(120) }
    it { is_expected.to validate_length_of(:position).is_at_most(120) }
    it { is_expected.to validate_length_of(:salary).is_at_most(120) }
    it { is_expected.to validate_length_of(:experience).is_at_most(80) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }
    it { is_expected.to validate_length_of(:download_url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:contributor).is_at_most(80) }
    it { is_expected.to validate_length_of(:student_number).is_at_most(64) }
    it { is_expected.to allow_values("", nil).for(:description) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)

    let(:params) do
      { file: upload, consent: true, download_url: "https://www.kdocs.cn/l/shared-resume" }.merge(
        metadata,
      )
    end
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
        Fabricate(:admin, suspended_at: 1.hour.ago, suspended_till: 1.day.from_now)
      end

      it { is_expected.to fail_a_policy(:can_submit) }
    end

    context "when the actor is silenced" do
      fab!(:acting_user) { Fabricate(:admin, silenced_till: 1.day.from_now) }

      it { is_expected.to fail_a_policy(:can_submit) }
    end

    context "when the actor is an ordinary member" do
      fab!(:acting_user, :user)

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
      it "stores private pending previews owned by the actor without inferring a contributor" do
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
          download_url: params[:download_url],
          contributor: "",
          contributor_user_id: nil,
          student_number: "",
        )
        expect(shared_resume.reviews).to be_empty
        expect(IsbfResume::SharedResume.published).to be_empty
        expect(shared_resume.pdf.available_path).to eq(nil)
        expect(File.binread(shared_resume.pdf.preview_path(1), 8)).to eq(
          IsbfResume::SharedPdf::PNG_SIGNATURE,
        )
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
          contributor: " Graduate contributor ",
          student_number: " 20261019 ",
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
          contributor: "Graduate contributor",
          student_number: "20261019",
          contributor_user_id: nil,
        )
      end
    end

    context "when an administrator provides images with review permission disabled" do
      fab!(:acting_user, :moderator)

      let(:params) { super().except(:file).merge(preview_images: [sharing_image_upload]) }

      it "creates a pending resume while keeping review access independent" do
        expect(result).to run_successfully
        expect(result.shared_resume.reload).to have_attributes(
          user_id: acting_user.id,
          status: "pending",
          pages: 1,
        )
        expect(result.shared_resume.pdf.available_path).to eq(nil)
        expect(acting_user.guardian.can_review_isbf_resumes?).to eq(false)
      end
    end
  end
end
