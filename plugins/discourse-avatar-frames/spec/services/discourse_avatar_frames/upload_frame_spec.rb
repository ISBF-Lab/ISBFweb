# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::UploadFrame do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:file) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    let(:params) { { file: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:source) { Rails.root.join("plugins/discourse-avatar-frames/public/images/chromawave.png") }
    let(:file) { Rack::Test::UploadedFile.new(source, "image/png") }

    context "when the actor is a regular user" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "without a file" do
      let(:file) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "with an animated PNG" do
      it "preserves the animated original and stores a static PNG" do
        expect(result).to run_successfully
        image = result.images.image_upload
        still = result.images.static_upload

        expect(image).to be_animated
        expect(still).not_to be_animated
        expect(image.secure?).to eq(false)
        expect(File.binread(Discourse.store.path_for(image))).to eq(File.binread(source))
        expect(File.binread(Discourse.store.path_for(still))).to eq(
          File.binread(source.sub_ext("-static.png")),
        )
        expect(FastImage.size(Discourse.store.path_for(still))).to eq([288, 288])
      end
    end

    context "with a static PNG" do
      let(:source) do
        Rails.root.join("plugins/discourse-avatar-frames/public/images/bubble-static.png")
      end

      it "reuses the original image for the static preview" do
        expect(result).to run_successfully
        expect(result.images.static_upload).to eq(result.images.image_upload)
        expect(result.images.image_upload).not_to be_animated
      end
    end
  end
end
