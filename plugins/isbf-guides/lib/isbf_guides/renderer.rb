# frozen_string_literal: true

module ::IsbfGuides
  class Renderer
    class InvalidImage < StandardError
    end

    def initialize(guide:, raw:, anchors: {})
      @guide = guide
      @raw = raw.to_s
      @anchors = anchors || {}
    end

    def render
      document = parse_document
      toc = build_toc(document)
      image_ids = prepare_images(document)
      { cooked: document.to_html, toc:, image_ids: }
    end

    private

    def parse_document
      Nokogiri::HTML5.fragment(PrettyText.cook(@raw))
    end

    def build_toc(document)
      used = Set.new
      document
        .css("h2, h3, h4")
        .each_with_index
        .filter_map do |heading, index|
          title = heading.text.strip
          preferred = @anchors[title].presence || heading["id"].presence || "section-#{index + 1}"
          identifier = preferred.match?(/\A[a-zA-Z0-9_-]+\z/) ? preferred : "section-#{index + 1}"
          identifier = "#{identifier}-#{index + 1}" if used.include?(identifier)
          used.add(identifier)
          heading["id"] = identifier
          next if heading.name == "h4"
          { id: identifier, title:, level: heading.name.delete_prefix("h").to_i }
        end
    end

    def prepare_images(document)
      images = @guide.images.pluck(:filename, :id, :width, :height).index_by(&:first)
      document
        .css("img")
        .map do |image|
          source = image["src"].to_s
          filename = source.delete_prefix("#{@guide.url}/images/")
          row = images[filename]
          raise InvalidImage unless row && source == "#{@guide.url}/images/#{filename}"

          image["width"] = row[2].to_s
          image["height"] = row[3].to_s
          image["loading"] = "lazy"
          image["decoding"] = "async"
          wrapper = image.ancestors("a").first
          if wrapper
            wrapper["href"] = source
            wrapper["class"] = "lightbox"
          else
            wrapper = Nokogiri::XML::Node.new("a", document)
            wrapper["href"] = source
            wrapper["class"] = "lightbox"
            image.replace(wrapper)
            wrapper.add_child(image)
          end
          wrapper["data-download-href"] = source
          row[1]
        end
        .uniq
    end
  end
end
