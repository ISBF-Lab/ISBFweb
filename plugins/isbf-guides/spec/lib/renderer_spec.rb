# frozen_string_literal: true

RSpec.describe IsbfGuides::Renderer do
  describe "#render" do
    fab!(:guide, :isbf_guide)

    it "retains accepted legacy anchors and gives duplicate headings distinct targets" do
      result =
        described_class.new(
          guide:,
          raw: "## Preparation\n\nRead first.\n\n## Preparation\n\nRead again.",
          anchors: {
            "Preparation" => "prep",
          },
        ).render

      expect(result[:toc].map { |entry| entry[:id] }).to eq(%w[prep prep-2])
      document = Nokogiri::HTML5.fragment(result[:cooked])
      expect(document.css("h2").map { |heading| heading["id"] }).to eq(%w[prep prep-2])
    end

    it "adds the native image viewer link and captures only referenced private images" do
      image = Fabricate(:isbf_guide_image, guide:)
      Fabricate(:isbf_guide_image, guide:)

      result = described_class.new(guide:, raw: "![Notification settings](#{image.url})").render
      document = Nokogiri::HTML5.fragment(result[:cooked])

      expect(result[:image_ids]).to eq([image.id])
      expect(document.at_css("a.lightbox")["href"]).to eq(image.url)
      expect(document.at_css("img").attributes.transform_values(&:value)).to include(
        "src" => image.url,
        "width" => "1",
        "height" => "1",
        "loading" => "lazy",
      )
    end

    it "rejects images belonging to another guide" do
      image = Fabricate(:isbf_guide_image)

      expect do
        described_class.new(guide:, raw: "![Other guide](#{image.url})").render
      end.to raise_error(described_class::InvalidImage)
    end

    it "sanitizes scripts and executable links" do
      result =
        described_class.new(
          guide:,
          raw:
            "## Safe heading\n\n<script>alert(1)</script>\n\n<a href='javascript:alert(1)'>Unsafe link</a>",
        ).render
      document = Nokogiri::HTML5.fragment(result[:cooked])

      expect(document.css("script")).to be_empty
      expect(document.css("a").map { |anchor| anchor["href"] }.compact).not_to include(
        "javascript:alert(1)",
      )
    end
  end
end
