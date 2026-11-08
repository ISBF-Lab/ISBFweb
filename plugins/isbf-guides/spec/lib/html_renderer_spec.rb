# frozen_string_literal: true

RSpec.describe IsbfGuides::HtmlRenderer do
  describe "#render" do
    fab!(:guide, :isbf_guide)

    it "preserves section and step IDs while omitting step headings from the directory" do
      raw = <<~HTML
        <section class="isbf-guide__intro" id="prep"><p>Read first.</p></section>
        <section id="sec-1"><h2>Allow notifications</h2>
          <article class="isbf-guide__step" id="step-01"><h3>Open settings</h3><p>Enable messages.</p></article>
          <h3 id="faq">Troubleshooting</h3><p>Check permissions.</p>
        </section>
      HTML

      result = described_class.new(guide:, raw:).render
      document = Nokogiri::HTML5.fragment(result[:cooked])

      expect(result[:toc]).to eq(
        [
          { id: "prep", title: I18n.t("isbf_guides.document.intro"), level: 2 },
          { id: "sec-1", title: "Allow notifications", level: 2 },
          { id: "faq", title: "Troubleshooting", level: 3 },
        ],
      )
      expect(document.at_css("section#sec-1 h2").text).to eq("Allow notifications")
      expect(document.at_css("article#step-01 h3").text).to eq("Open settings")
    end

    it "keeps figures, captions and approved callout structure" do
      image = Fabricate(:isbf_guide_image, guide:)
      raw = <<~HTML
        <section id="setup"><h2>Setup</h2>
        <figure class="isbf-guide__shot"><img src="#{image.url}" alt="Phone settings"><figcaption class="isbf-guide__caption">Figure one</figcaption></figure>
        <div class="isbf-guide__callout --danger"><strong>Important</strong><p>Keep forum messages enabled.</p></div>
        </section>
      HTML

      result = described_class.new(guide:, raw:).render
      document = Nokogiri::HTML5.fragment(result[:cooked])

      expect(document.at_css("figure.isbf-guide__shot figcaption").text).to eq("Figure one")
      expect(document.at_css(".isbf-guide__callout p").text).to eq("Keep forum messages enabled.")
      expect(document.at_css("a.lightbox")["href"]).to eq(image.url)
      expect(result[:image_ids]).to eq([image.id])
    end

    it "renders HTML text directly without interpreting Markdown punctuation" do
      raw =
        "<section id='literal'><h2>Literal text</h2><p>Keep **these asterisks** and `backticks`.</p></section>"

      result = described_class.new(guide:, raw:).render
      document = Nokogiri::HTML5.fragment(result[:cooked])

      expect(document.at_css("p").text).to eq("Keep **these asterisks** and `backticks`.")
      expect(document.css("strong, code")).to be_empty
    end

    it "removes executable elements, inline events, styles and unsafe link protocols" do
      raw = <<~HTML
        <style>body { display: none; }</style><script>alert(1)</script>
        <section id="safe" onclick="alert(1)" style="position:fixed"><h2>Safe heading</h2>
          <a href="javascript:alert(1)">Unsafe link</a><iframe src="https://example.com"></iframe>
          <form><input name="password"></form><object data="payload"></object>
        </section>
      HTML

      result = described_class.new(guide:, raw:).render
      document = Nokogiri::HTML5.fragment(result[:cooked])

      expect(
        document.css("script, style, iframe, form, input, object, [onclick], [style]"),
      ).to be_empty
      expect(document.at_css("a")["href"]).to be_nil
      expect(document.at_css("section#safe h2").text).to eq("Safe heading")
    end

    it "rejects ambiguous duplicate document IDs" do
      raw = "<section id='setup'><h2>One</h2></section><section id='setup'><h2>Two</h2></section>"

      expect { described_class.new(guide:, raw:).render }.to raise_error(IsbfGuides::DocumentError)
    end

    it "rejects images outside the current guide" do
      image = Fabricate(:isbf_guide_image)

      expect do
        described_class.new(guide:, raw: "<figure><img src='#{image.url}'></figure>").render
      end.to raise_error(IsbfGuides::Renderer::InvalidImage)
    end
  end
end
