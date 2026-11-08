# frozen_string_literal: true

require "base64"
require "stringio"
require "tempfile"
require "zip"

module IsbfGuidesDocumentHelpers
  def guide_image_bytes
    File.binread(File.expand_path("../fixtures/step.png", __dir__))
  end

  def inline_guide_image
    "data:image/png;base64,#{Base64.strict_encode64(guide_image_bytes)}"
  end

  def guide_document_html(image_source: nil, body: "Configure the forum messages category.")
    figure =
      if image_source
        <<~HTML
          <figure><img src="#{image_source}" alt="Notification settings"><figcaption>Notification settings screenshot</figcaption></figure>
        HTML
      else
        ""
      end
    <<~HTML
      <!doctype html><html><head><meta charset="utf-8"><title>Notification guide</title></head><body>
      <header><nav>Global site navigation</nav></header>
      <main>
        <section class="isbf-guide__intro" id="prep"><h1>Notification guide</h1><p>Read this introduction first.</p></section>
        <section id="sec-1"><h2>Allow notifications</h2>
          <article class="isbf-guide__step" id="step-01"><h3>Open settings</h3><p>#{body}</p>#{figure}</article>
          <div class="isbf-guide__callout"><strong>Important</strong><p>Keep forum messages enabled.</p></div>
        </section>
      </main>
      <footer>Global site footer</footer>
      </body></html>
    HTML
  end

  def guide_zip_bytes(entries)
    Zip::OutputStream
      .write_buffer do |archive|
        entries.each do |path, contents|
          archive.put_next_entry(path)
          archive.write(contents)
        end
      end
      .string
  end

  def guide_zip_contents(data)
    contents = {}
    Zip::File.open_buffer(StringIO.new(data)) do |archive|
      archive
        .entries
        .reject(&:directory?)
        .each { |entry| contents[entry.name] = archive.read(entry) }
    end
    contents
  end

  def guide_document_upload(data, filename: "guide.html", type: "text/html")
    temporary = Tempfile.new(["isbf-guide-document", File.extname(filename)])
    temporary.binmode
    temporary.write(data)
    temporary.rewind
    ActionDispatch::Http::UploadedFile.new(tempfile: temporary, filename:, type:)
  end

  def rack_guide_document(data, filename: "guide.html", type: "text/html")
    Rack::Test::UploadedFile.new(StringIO.new(data), type, original_filename: filename)
  end
end

RSpec.configure { |config| config.include IsbfGuidesDocumentHelpers }
