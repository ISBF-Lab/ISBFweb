# frozen_string_literal: true

require "erb"
require "zip"

module ::IsbfGuides
  class DocumentArchive
    TEMPLATE_DIRECTORY = Pathname.new(__dir__).join("templates").freeze

    def self.template
      build_zip(
        "index.html" => TEMPLATE_DIRECTORY.join("guide.html").read,
        "images/example.png" => TEMPLATE_DIRECTORY.join("example.png").binread,
      )
    end

    def self.build_zip(files)
      Zip::OutputStream
        .write_buffer do |archive|
          files.each do |path, data|
            archive.put_next_entry(path)
            archive.write(data)
          end
        end
        .string
    end

    def initialize(revision:)
      @revision = revision
    end

    def data
      source = @revision.content_format == "html" ? @revision.raw : @revision.cooked
      fragment = DocumentMarkup.clean(source)
      images = @revision.guide.images.where(id: @revision.image_ids).index_by(&:filename)
      files = {}
      fragment
        .css("img")
        .each do |image|
          original_url = image["src"]
          filename = original_url.delete_prefix("#{@revision.guide.url}/images/")
          stored = images[filename]
          raise DocumentError.new(:missing_image, path: filename.truncate(160)) unless stored
          path = "images/#{filename}"
          files[path] = stored.data
          image["src"] = path
          link = image.ancestors("a").first
          link["href"] = path if link
        end
      title = ERB::Util.html_escape(@revision.title)
      files["index.html"] = <<~HTML
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>#{title}</title></head>
        <body><main data-guide-content><h1>#{title}</h1>#{fragment.to_html}</main></body>
        </html>
      HTML
      self.class.build_zip(files)
    end
  end
end
