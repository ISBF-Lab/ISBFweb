# frozen_string_literal: true

require_relative "../../lib/isbf_guides/legacy_import"

RSpec.describe IsbfGuides::LegacyImport do
  describe ".call" do
    subject(:result) { described_class.call(directory:, actor: acting_user) }

    fab!(:acting_user, :admin)

    let(:directory) { Dir.mktmpdir("isbf-guides-import") }
    let(:image_bytes) { File.binread(File.expand_path("../fixtures/step.png", __dir__)) }
    let(:source_html) do
      next_image = 0
      sections =
        [4, 4, 4, 4, 4, 4, 5].each_with_index
          .map do |count, section_index|
            number = section_index + 1
            steps =
              count
                .times
                .map do
                  next_image += 1
                  filename = format("step-%02d.jpg", next_image)
                  <<~HTML
                <article>
                  <h3 id="step-#{next_image}" class="isbf-guide__step-title">Step #{next_image}</h3>
                  <p>Configure setting #{next_image}.</p>
                  <img src="/guides/android/images/#{filename}" alt="Step #{next_image}">
                </article>
              HTML
                end
                .join
            faq =
              if number == 7
                '<h3 id="sec-7-1">FAQ one</h3><p>First answer.</p><h3 id="sec-7-2">FAQ two</h3><p>Second answer.</p>'
              else
                ""
              end
            "<section id='sec-#{number}'><h2>Section #{number}</h2>#{steps}#{faq}</section>"
          end
          .join
      <<~HTML
        <!doctype html><html><body><main>
        <section id="prep"><h1>Android notification setup</h1><p>Read the <strong>important instructions</strong> first.</p></section>
        #{sections}
        </main></body></html>
      HTML
    end

    before do
      SiteSetting.isbf_guides_enabled = true
      FileUtils.mkdir_p(File.join(directory, "images"))
      File.write(File.join(directory, "index.html"), source_html)
      (1..29).each do |number|
        File.binwrite(File.join(directory, "images", format("step-%02d.jpg", number)), image_bytes)
      end
    end

    after { FileUtils.remove_entry(directory) }

    context "when the source is complete" do
      it "publishes all original screenshot paths and preserves chapter and step anchors" do
        guide = result

        expect(guide).to be_published
        expect(guide.published_revision.title).to eq("Android notification setup")
        expect(guide.images.count).to eq(29)
        expect(guide.images.first.data).to eq(image_bytes)
        expect(guide.published_revision.image_ids.length).to eq(29)
        expect(guide.published_revision.toc.map { |entry| entry["id"] }).to eq(
          %w[prep sec-1 sec-2 sec-3 sec-4 sec-5 sec-6 sec-7 sec-7-1 sec-7-2],
        )
        document = Nokogiri::HTML5.fragment(guide.published_revision.cooked)
        expect(document.at_css("h4#step-1").text).to eq("Step 1")
        expect(document.css("img").map { |image| image["src"] }).to eq(
          (1..29).map { |number| "/guides/android/images/#{format("step-%02d.jpg", number)}" },
        )
      end

      it "preserves subsequent administrator edits when imported again" do
        guide = result
        guide.draft_revision.update!(
          title: "Maintained by the administrator",
          raw: "## Updated\n\nNew instructions.",
        )
        edited = guide.draft_revision.attributes
        published = guide.published_revision.attributes

        expect do described_class.call(directory:, actor: acting_user) end.not_to change(
          IsbfGuides::Revision,
          :count,
        )
        expect(guide.reload.draft_revision.attributes).to eq(edited)
        expect(guide.published_revision.attributes).to eq(published)
      end
    end

    context "when a screenshot file is missing" do
      before { File.unlink(File.join(directory, "images", "step-29.jpg")) }

      it "rolls back all partially imported data" do
        expect { result }.to raise_error(Errno::ENOENT)
        expect(IsbfGuides::Guide.count).to eq(0)
        expect(IsbfGuides::Image.count).to eq(0)
        expect(IsbfGuides::Revision.count).to eq(0)
      end
    end

    context "when the source layout is incomplete" do
      before { File.write(File.join(directory, "index.html"), "<main></main>") }

      it "rejects the source before creating a guide" do
        expect { result }.to raise_error(RuntimeError, "Invalid Android tutorial source")
        expect(IsbfGuides::Guide.count).to eq(0)
      end
    end

    context "when the actor is a member" do
      fab!(:acting_user, :user)

      it "requires an administrator even for a direct importer call" do
        expect { result }.to raise_error(Discourse::InvalidAccess)
        expect(IsbfGuides::Guide.count).to eq(0)
      end
    end
  end
end
