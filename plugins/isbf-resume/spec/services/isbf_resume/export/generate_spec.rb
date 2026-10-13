# frozen_string_literal: true

require_relative "../../../support/isbf_resume_helpers"

RSpec.describe IsbfResume::Export::Generate do
  include_context "with private resume storage"

  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:resume) }

    it do
      is_expected.to allow_value({ "basic" => { "name" => "示例" } }).for(:resume)
    end

    it { is_expected.not_to allow_values(nil, [], "{}", true).for(:resume) }

    it "limits encoded bytes rather than character count" do
      stub_const(IsbfResume, :MAX_REQUEST_BYTES, 128) do
        is_expected.to allow_value({ "text" => "字" * 30 }).for(:resume)
        is_expected.not_to allow_value({ "text" => "字" * 43 }).for(:resume)
      end
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :user)
    let(:params) { { resume: } }
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new } }

    before { SiteSetting.isbf_resume_enabled = true }

    context "when the request contract is invalid" do
      let(:params) { { resume: [] } }

      it "halts before creating private files" do
        expect(result).to fail_a_contract
        expect(Dir.children(IsbfResume::Export.storage_path)).to be_empty
      end
    end

    context "when the actor is a visitor" do
      fab!(:acting_user) { nil }

      it "halts at the generation policy" do
        expect(result).to fail_a_policy(:can_generate)
        expect(Dir.children(IsbfResume::Export.storage_path)).to be_empty
      end
    end

    context "when the actor is suspended" do
      fab!(:acting_user) do
        Fabricate(
          :user,
          suspended_at: 1.hour.ago,
          suspended_till: 1.day.from_now
        )
      end

      it { is_expected.to fail_a_policy(:can_generate) }
    end

    context "when generation is disabled" do
      before { SiteSetting.isbf_resume_enabled = false }

      it { is_expected.to fail_a_policy(:can_generate) }
    end

    context "when resume content is invalid" do
      let(:params) do
        { resume: resume.deep_merge("basic" => { "email" => "invalid" }) }
      end

      it "returns a typed validation failure and removes the input" do
        expect(result).to fail_with_exception(
          IsbfResume::Generator::InvalidResume
        )
        export = result.export
        expect(File.exist?(export.input_path)).to eq(false)
        expect(IsbfResume::Export.find(export.id)).to eq(nil)
      end
    end

    context "when the generator executable is unavailable" do
      around do |example|
        with_resume_environment(
          "ISBF_RESUME_PYTHON" =>
            File.join(IsbfResume::Export.storage_path, "missing-python")
        ) { example.run }
      end

      it "returns a typed generation failure" do
        expect(result).to fail_with_exception(
          IsbfResume::Generator::GenerationError
        )
        expect(File.exist?(result.export.input_path)).to eq(false)
        expect(IsbfResume::Export.find(result.export.id)).to eq(nil)
      end
    end

    context "when the resume is valid" do
      it "creates an owner-bound export with both real documents" do
        expect(result).to run_successfully
        export = IsbfResume::Export.find(result.export.id)
        expect(export.owner_id).to eq(acting_user.id)
        expect(export.pages).to be >= 1
        expect(export).to be_available
        expect(File.binread(export.file_path("docx"), 4)).to eq("PK\x03\x04")
        expect(File.binread(export.file_path("pdf"), 5)).to eq("%PDF-")
        expect(File.exist?(export.input_path)).to eq(false)
      end
    end
  end
end
