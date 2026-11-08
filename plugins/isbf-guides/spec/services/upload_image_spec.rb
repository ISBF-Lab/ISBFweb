# frozen_string_literal: true

RSpec.describe IsbfGuides::UploadImage do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:guide_id) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:guide, :isbf_guide)

    let(:params) { { guide_id: } }
    let(:dependencies) { { guardian: acting_user&.guardian || Guardian.new, options: { file: } } }
    let(:guide_id) { guide.id }
    let(:filename) { "step.png" }
    let(:bytes) { File.binread(File.expand_path("../fixtures/step.png", __dir__)) }
    let(:temporary) do
      file = Tempfile.new("guide-image")
      file.binmode
      file.write(bytes)
      file.rewind
      file
    end
    let(:file) do
      ActionDispatch::Http::UploadedFile.new(tempfile: temporary, filename:, type: "image/png")
    end

    before { SiteSetting.isbf_guides_enabled = true }
    after { temporary.close! }

    context "when the contract is invalid" do
      let(:guide_id) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "when the actor is a member" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when the guide is missing" do
      let(:guide_id) { -1 }

      it { is_expected.to fail_to_find_a_model(:guide) }
    end

    context "when the file type is unsupported" do
      let(:filename) { "script.svg" }

      it { is_expected.to fail_a_policy(:valid_upload) }
    end

    context "when the file exceeds the configured image limit" do
      let(:bytes) { "x" * 1025 }

      before { SiteSetting.max_image_size_kb = 1 }

      it { is_expected.to fail_a_policy(:valid_upload) }
    end

    context "when the extension disguises invalid image bytes" do
      let(:bytes) { "<script>alert('invalid image')</script>" }

      it "rejects the upload without retaining a row" do
        expect { result }.not_to change(IsbfGuides::Image, :count)
        expect(result).to fail_with_an_invalid_model(:image)
      end
    end

    context "when the image is valid" do
      it "stores the original bytes with a private guide URL" do
        expect { result }.to change(IsbfGuides::Image, :count).by(1)
        expect(result).to run_successfully
        image = guide.images.last
        expect(image).to have_attributes(
          data: bytes,
          content_type: "image/png",
          width: 1,
          height: 1,
          creator: acting_user,
          sha256: Digest::SHA256.hexdigest(bytes),
        )
        expect(image.url).to start_with("#{guide.url}/images/")
      end
    end
  end
end
