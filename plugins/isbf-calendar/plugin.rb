# frozen_string_literal: true

# name: isbf-calendar
# about: Private personal schedules and routes for the ISBF calendar UI
# version: 0.3.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Calendar
# required_version: 3.4.0

module ::IsbfCalendar
  PLUGIN_NAME = "isbf-calendar"
end

require_relative "lib/isbf_calendar/engine"
require "time"
require_relative "lib/isbf_calendar/official_items"
register_svg_icon "calendar-days"

after_initialize do
  require_relative "app/models/isbf_calendar/entry"
  require_relative "app/models/isbf_calendar/official_item"
  require_relative "app/services/isbf_calendar/publish_official_items"
  require_relative "app/services/isbf_calendar/add_official_entry"
  require_relative "app/services/isbf_calendar/respond_to_official_update"
  require_relative "app/serializers/isbf_calendar/official_item_serializer"
  require_relative "app/serializers/isbf_calendar/entry_serializer"
  require_relative "app/jobs/regular/isbf_calendar_notify_change"

  reloadable_patch do
    Topic.has_many :isbf_official_calendar_items,
                   -> { order(:position, :id) },
                   class_name: "IsbfCalendar::OfficialItem",
                   inverse_of: :topic,
                   autosave: true
  end
  register_topic_preloader_associations(:isbf_official_calendar_items)
  register_topic_preloader_associations(:first_post)
  TopicView.on_preload do |view|
    ActiveRecord::Associations::Preloader.new(
      records: [view.topic],
      associations: %i[isbf_official_calendar_items first_post]
    ).call
  end

  field = IsbfCalendar::OFFICIAL_ITEMS_FIELD.to_sym
  add_permitted_post_create_param(field, :string)
  NewPostManager.add_plugin_payload_attribute(field)
  add_permitted_post_update_param(field) do |post, value|
    if !value.nil? && !post.is_first_post?
      raise Discourse::InvalidParameters.new(IsbfCalendar::OFFICIAL_ITEMS_FIELD)
    end
  end
  PostRevisor.track_topic_field(field) do |changes, value|
    next if value.nil?
    result =
      IsbfCalendar.publish_official_items(changes.topic, changes.user, value)
    changes.record_change(field, result[:before_items], result[:after_items])
  end

  module ::IsbfCalendar::RevisorPayload
    def revise!(editor, fields, opts = {}, &block)
      clean_fields =
        fields.reject do |key, value|
          key.to_s == IsbfCalendar::OFFICIAL_ITEMS_FIELD && value.nil?
        end
      if clean_fields[IsbfCalendar::OFFICIAL_ITEMS_FIELD.to_sym].present? &&
           clean_fields[:raw].nil?
        clean_fields.delete(:raw)
      end
      super(editor, clean_fields, opts, &block)
    end
  end
  reloadable_patch { PostRevisor.prepend(IsbfCalendar::RevisorPayload) }

  on(:before_create_post) do |post, options|
    value = options[IsbfCalendar::OFFICIAL_ITEMS_FIELD.to_sym]
    next if value.nil?
    if options[:topic_id].present? ||
         options[:archetype] == Archetype.private_message ||
         !IsbfCalendar.official_category_id ||
         options[:category].to_i != IsbfCalendar.official_category_id ||
         !DiscourseAcademyRoles.official_member?(post.user)
      raise Discourse::InvalidParameters.new(IsbfCalendar::OFFICIAL_ITEMS_FIELD)
    end
    IsbfCalendar.parse_official_items(value)
  end

  on(:before_create_topic) do |topic, creator|
    value = creator.opts[IsbfCalendar::OFFICIAL_ITEMS_FIELD.to_sym]
    unless value.nil?
      IsbfCalendar.publish_official_items(topic, creator.user, value)
    end
  end

  on(:topic_destroyed) do |topic|
    IsbfCalendar::OfficialItem
      .where(topic_id: topic.id)
      .active
      .find_each do |item|
        item.update!(cancelled: true, registration_deadline: nil)
      end
  end

  %i[topic_view topic_list_item post].each do |serializer|
    add_to_serializer(
      serializer,
      field,
      include_condition: -> do
        topic = object.respond_to?(:topic) ? object.topic : object
        (!object.is_a?(Post) || object.is_first_post?) &&
          IsbfCalendar.official_topic?(topic) && !topic.deleted_at &&
          topic.first_post && !topic.first_post.hidden
      end
    ) do
      topic = object.respond_to?(:topic) ? object.topic : object
      items = topic.isbf_official_calendar_items.reject(&:cancelled?)
      entry_ids =
        if object.is_a?(Post) && scope.user
          IsbfCalendar::Entry
            .where(user_id: scope.user.id, source_item_id: items.map(&:id))
            .pluck(:source_item_id, :id)
            .to_h
        else
          {}
        end
      items.map do |item|
        IsbfCalendar::OfficialItemSerializer
          .new(item, scope:, root: false)
          .as_json
          .merge(personal_entry_id: entry_ids[item.id])
      end
    end
  end

  add_to_serializer(:site, :isbf_calendar) do
    {
      official_category_id: IsbfCalendar.official_category_id,
      timezone: IsbfCalendar::TIMEZONE,
      max_items: IsbfCalendar::MAX_OFFICIAL_ITEMS
    }
  end
end
