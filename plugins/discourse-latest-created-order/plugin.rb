# frozen_string_literal: true

# name: discourse-latest-created-order
# about: Orders default Latest lists by topic creation date while preserving pinned topics
# version: 0.1.0
# authors: ISBF Lab
# required_version: 2026.8.0

enabled_site_setting :latest_topics_order_by_created

after_initialize do
  register_modifier(:topic_query_create_list_topics) do |topics, options, topic_query|
    next topics unless options[:filter] == :latest

    order = topic_query.options[:order]
    next topics if order.present? && order != "default"

    topics.reorder(created_at: :desc, id: :desc)
  end

  add_to_serializer(
    :topic_list_item,
    :latest_created_order_pinned_at,
    include_condition: -> { object.topic_list&.filter == :latest },
  ) do
    category = object.topic_list.category
    prioritized = category ? object.category_id == category.id : object.pinned_globally
    cleared_at = object.user_data&.cleared_pinned_at

    if prioritized && object.pinned_at && (cleared_at.nil? || object.pinned_at > cleared_at)
      object.pinned_at
    end
  end
end
