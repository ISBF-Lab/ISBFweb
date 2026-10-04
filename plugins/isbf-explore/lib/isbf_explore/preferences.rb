# frozen_string_literal: true

module IsbfExplore
  class Preferences
    STORE_NAME = "isbf-explore"
    MAX_IDS = 50
    ORDERS = %w[activity hot].freeze

    def initialize(user, guardian)
      @key = user.id.to_s
      @guardian = guardian
    end

    def read
      stored = PluginStore.get(STORE_NAME, @key)
      stored = stored.is_a?(Hash) ? stored.stringify_keys : {}
      payload(
        category_ids: stored_ids(stored["category_ids"]),
        tag_ids: stored_ids(stored["tag_ids"]),
        order: ORDERS.include?(stored["order"]) ? stored["order"] : "activity",
      )
    end

    def write(input)
      input = input.stringify_keys
      category_ids = validate_ids!(input["category_ids"], :category_ids)
      tag_ids = validate_ids!(input["tag_ids"], :tag_ids)
      raise Discourse::InvalidParameters.new(:order) if ORDERS.exclude?(input["order"])

      result = payload(category_ids: category_ids, tag_ids: tag_ids, order: input["order"])
      PluginStore.set(STORE_NAME, @key, result[:preferences])
      result
    end

    private

    def validate_ids!(ids, field)
      if !ids.is_a?(Array) || ids.length > MAX_IDS || !ids.all? { |id| valid_id?(id) }
        raise Discourse::InvalidParameters.new(field)
      end

      ids.uniq
    end

    def valid_id?(id)
      id.is_a?(Integer) && id.positive? && id <= 2_147_483_647
    end

    def stored_ids(ids)
      ids.is_a?(Array) ? ids.select { |id| valid_id?(id) }.uniq.first(MAX_IDS) : []
    end

    def payload(category_ids:, tag_ids:, order:)
      visible_category_ids = Category.secured(@guardian).where(id: category_ids).pluck(:id)
      visible_tags = Tag.where(id: tag_ids).select { |tag| @guardian.can_see_tag?(tag) }
      tags_by_id = visible_tags.index_by(&:id)
      selected_tag_ids = tag_ids.select { |id| tags_by_id.key?(id) }

      {
        preferences: {
          category_ids: category_ids.select { |id| visible_category_ids.include?(id) },
          tag_ids: selected_tag_ids,
          order: order,
        },
        tags:
          selected_tag_ids.map do |id|
            tag = tags_by_id.fetch(id)
            { id: tag.id, name: tag.name, slug: tag.slug.presence || tag.name }
          end,
      }
    end
  end
end
