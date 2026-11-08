# frozen_string_literal: true

RSpec.describe IsbfGuides::Image do
  describe "#save" do
    it "rejects active content disguised with an image extension" do
      image = Fabricate.build(:isbf_guide_image, data: "<svg onload='alert(1)'></svg>")

      expect(image.save).to eq(false)
      expect(image.errors[:base]).to be_present
    end

    it "rejects image paths containing traversal segments" do
      image = Fabricate.build(:isbf_guide_image, filename: "../step.png")

      expect(image.save).to eq(false)
      expect(image.errors[:filename]).to be_present
    end

    it "retains private image bytes independently of temporary upload files" do
      image = Fabricate(:isbf_guide_image)
      expected = File.binread(File.expand_path("../fixtures/step.png", __dir__))

      expect(image.reload.data).to eq(expected)
      expect(image.content_type).to eq("image/png")
    end
  end
end
