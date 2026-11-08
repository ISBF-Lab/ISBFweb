# frozen_string_literal: true

require "sanitize"

module ::IsbfGuides
  module DocumentMarkup
    CLASSES =
      %w[
        intro
        eyebrow
        lead
        info-grid
        info-item
        info-title
        info-desc
        section
        section-head
        section-title
        section-desc
        subhead
        step
        step-body
        step-meta
        badge
        step-title
        shot
        shot-trigger
        caption
        callout
        callout-label
        footer
      ].map { |name| "isbf-guide__#{name}" }.to_set.freeze
    MODIFIERS = %w[--wide --neutral --danger].to_set.freeze
    ELEMENTS = %w[
      a
      abbr
      article
      aside
      b
      blockquote
      br
      caption
      code
      col
      colgroup
      dd
      del
      details
      div
      dl
      dt
      em
      figcaption
      figure
      footer
      h1
      h2
      h3
      h4
      h5
      h6
      header
      hr
      i
      img
      li
      main
      mark
      ol
      p
      pre
      s
      section
      small
      span
      strong
      sub
      summary
      sup
      table
      tbody
      td
      th
      thead
      tr
      u
      ul
    ].freeze
    ATTRIBUTES = {
      :all => %w[id class title lang dir],
      "a" => %w[href],
      "img" => %w[src alt width height],
      "ol" => %w[start reversed],
      "li" => %w[value],
      "td" => %w[colspan rowspan headers],
      "th" => %w[colspan rowspan headers scope],
      "col" => %w[span],
      "colgroup" => %w[span],
    }.freeze

    def self.clean(html)
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css("script, style, link, meta, base, iframe, object, embed, form, template").remove
      fragment.css(
        ".isbf-guide__header, .isbf-guide__mobile-nav, .isbf-guide__rail, .isbf-guide__viewer, nav",
      ).remove
      sanitized =
        Sanitize.fragment(
          fragment.to_html,
          elements: ELEMENTS,
          attributes: ATTRIBUTES,
          protocols: {
            "a" => {
              "href" => ["http", "https", "mailto", :relative],
            },
            "img" => {
              "src" => ["data", :relative],
            },
          },
        )
      fragment = Nokogiri::HTML5.fragment(sanitized)
      fragment
        .css("[class]")
        .each do |node|
          classes =
            node["class"].split.select do |name|
              CLASSES.include?(name) || MODIFIERS.include?(name) ||
                (node.name.in?(%w[pre code]) && name.match?(/\Alanguage-[a-zA-Z0-9_-]+\z/))
            end
          classes.empty? ? node.remove_attribute("class") : node["class"] = classes.uniq.join(" ")
        end
      identifiers = Set.new
      fragment
        .css("[id]")
        .each do |node|
          identifier = node["id"]
          if identifier.empty? || identifier.length > 160 ||
               identifier.match?(/[[:space:]\x00-\x1f\x7f]/)
            node.remove_attribute("id")
            next
          end
          raise DocumentError.new(:duplicate_id, identifier:) unless identifiers.add?(identifier)
        end
      fragment
        .css("a[href]")
        .each { |link| link["rel"] = "noopener noreferrer" if link["href"].match?(/\Ahttps?:/i) }
      fragment
    end
  end
end
