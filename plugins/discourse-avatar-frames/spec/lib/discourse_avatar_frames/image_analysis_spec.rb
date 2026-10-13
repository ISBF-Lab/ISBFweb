# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::ImageAnalysis do
  describe ".call" do
    subject(:analysis) { described_class.call(png) }

    let(:filename) { "closed-ring.png" }
    let(:source) do
      Rails.root.join("plugins/discourse-avatar-frames/spec/fixtures/images", filename)
    end
    let(:png) { File.open(source, "rb") { |file| DiscourseAvatarFrames::Png.new(file) } }

    it "suggests calibration for a closed circle below the canvas center" do
      expect(analysis[:scale]).to be_within(1).of(120)
      expect(analysis[:offset_x]).to be_within(0.3).of(0)
      expect(analysis[:offset_y]).to be_within(0.5).of(-3.33)
    end

    context "with an opaque RGBA image" do
      let(:filename) { "opaque-rgba.png" }

      it "requires transparent pixels even when an alpha channel exists" do
        expect { analysis }.to raise_error(
          DiscourseAvatarFrames::Png::Invalid,
          I18n.t("avatar_frames.errors.transparency_required"),
        )
      end
    end

    context "with unused transparency in an opaque palette image" do
      let(:filename) { "opaque-palette.png" }

      it "requires transparency in the decoded pixels" do
        expect { analysis }.to raise_error(
          DiscourseAvatarFrames::Png::Invalid,
          I18n.t("avatar_frames.errors.transparency_required"),
        )
      end
    end

    context "with transparent palette pixels" do
      let(:filename) { "transparent-palette.png" }

      it "accepts the image and suggests circle calibration" do
        expect(analysis[:scale]).to be_within(1).of(120)
      end
    end

    context "with an open ring" do
      let(:filename) { "open-ring.png" }

      it { is_expected.to be_nil }
    end

    context "with an irregular ring" do
      let(:filename) { "irregular-ring.png" }

      it { is_expected.to be_nil }
    end

    context "with a transparent blank canvas" do
      let(:filename) { "transparent-blank.png" }

      it { is_expected.to be_nil }
    end
  end
end
