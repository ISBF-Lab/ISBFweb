# frozen_string_literal: true

module ::IsbfGuides
  class Revision < ActiveRecord::Base
    self.table_name = "isbf_guides_revisions"

    CONTENT_ATTRIBUTES = %w[
      title
      summary
      raw
      cooked
      toc
      image_ids
      anchors
      content_digest
      content_format
    ].freeze

    belongs_to :guide, class_name: "IsbfGuides::Guide"
    belongs_to :editor, class_name: "User"

    validates :title, presence: true, length: { maximum: 200 }
    validates :summary, length: { maximum: 1000 }
    validates :raw, presence: true, length: { maximum: 200_000 }
    validates :content_format, inclusion: { in: %w[markdown html] }
    validate :preserve_published_content, on: :update

    before_validation :render_content, if: :content_changed?

    def content_attributes
      attributes.slice(*CONTENT_ATTRIBUTES)
    end

    def source_at_url(previous_url:, url:)
      return raw unless content_format == "html" && previous_url != url
      fragment = Nokogiri::HTML5.fragment(raw)
      fragment
        .css("img[src], a[href]")
        .each do |node|
          attribute = node.name == "img" ? "src" : "href"
          source = node[attribute]
          if source.start_with?("#{previous_url}/images/")
            node[attribute] = "#{url}/images/#{source.delete_prefix("#{previous_url}/images/")}"
          end
        end
      fragment.to_html
    end

    private

    def content_changed?
      new_record? || title_changed? || summary_changed? || raw_changed? || anchors_changed? ||
        content_format_changed?
    end

    def preserve_published_content
      if published_at_was.present? && changed?
        errors.add(:base, I18n.t("isbf_guides.errors.immutable_revision"))
      end
    end

    def render_content
      renderer = content_format == "html" ? HtmlRenderer : Renderer
      rendered = renderer.new(guide:, raw:, anchors:).render
      self.cooked = rendered.fetch(:cooked)
      self.toc = rendered.fetch(:toc)
      self.image_ids = rendered.fetch(:image_ids)
      digest_input = [title, summary, raw, anchors.sort.to_h]
      digest_input << content_format if content_format != "markdown"
      self.content_digest = Digest::SHA256.hexdigest(digest_input.to_json)
    rescue Renderer::InvalidImage
      errors.add(:raw, I18n.t("isbf_guides.errors.invalid_image_reference"))
    rescue DocumentError => error
      errors.add(:raw, error.message)
    end
  end
end

# == Schema Information
#
# Table name: isbf_guides_revisions
#
#  id             :bigint           not null, primary key
#  anchors        :jsonb            not null
#  content_digest :string           not null
#  content_format :string           default("markdown"), not null
#  cooked         :text             not null
#  image_ids      :jsonb            not null
#  published_at   :datetime
#  raw            :text             not null
#  summary        :string           default(""), not null
#  title          :string           not null
#  toc            :jsonb            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  editor_id      :bigint           not null
#  guide_id       :bigint           not null
#
# Indexes
#
#  index_isbf_guides_revisions_on_guide_id  (guide_id)
#
