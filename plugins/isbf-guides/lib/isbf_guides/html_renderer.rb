# frozen_string_literal: true

module ::IsbfGuides
  class HtmlRenderer < Renderer
    private

    def parse_document
      DocumentMarkup.clean(@raw)
    end

    def build_toc(document)
      identifiers = document.css("[id]").map { |node| node["id"] }.to_set
      targets = Set.new
      entries = []
      document
        .css(".isbf-guide__intro, h2, h3")
        .each_with_index do |heading, index|
          next if heading.ancestors(".isbf-guide__step").any?
          intro = heading["class"].to_s.split.include?("isbf-guide__intro")
          next if intro && heading.at_css("h2, h3")
          title = intro ? I18n.t("isbf_guides.document.intro") : heading.text.strip
          next if title.blank?
          target = heading
          section = heading.ancestors("section[id]").first
          target = section if heading["id"].blank? && heading.name == "h2" && section &&
            !targets.include?(section["id"])
          identifier = target["id"].presence
          unless identifier
            identifier = "section-#{index + 1}"
            identifier = "#{identifier}-next" while identifiers.include?(identifier)
            target["id"] = identifier
            identifiers.add(identifier)
          end
          next unless targets.add?(identifier)
          entries << { id: identifier, title:, level: heading.name == "h3" ? 3 : 2 }
        end
      entries
    end

    def prepare_images(document)
      identifiers = super
      document
        .css(".isbf-guide__shot a.lightbox")
        .each { |link| link["class"] = "lightbox isbf-guide__shot-trigger" }
      identifiers
    end
  end
end
