# frozen_string_literal: true

module IsbfCalendar
  class OfficialItem < ActiveRecord::Base
    self.table_name = "isbf_calendar_official_items"

    SNAPSHOT_FIELDS = %w[title schedule_kind starts_at ends_at all_day].freeze
    PUBLICATION_FIELDS =
      (SNAPSHOT_FIELDS + %w[location organizer registration_deadline_id]).freeze
    REVISION_FIELDS = (SNAPSHOT_FIELDS + %w[cancelled]).freeze

    belongs_to :topic, -> { with_deleted }
    belongs_to :registration_deadline,
               class_name: "IsbfCalendar::OfficialItem",
               optional: true,
               autosave: true
    has_many :entries,
             foreign_key: :source_item_id,
             class_name: "IsbfCalendar::Entry"

    validates :title, presence: true, length: { maximum: 120 }
    validates :location, length: { maximum: 255 }
    validates :organizer, length: { maximum: 120 }
    validates :schedule_kind, inclusion: { in: %w[event deadline] }
    validates :all_day, inclusion: { in: [true, false] }
    validates :starts_at, :ends_at, presence: true
    validate :valid_time_range
    validate :valid_registration_deadline

    before_update :advance_revision
    after_update_commit :notify_subscribers

    scope :active, -> { where(cancelled: false) }

    def self.attributes_from_payload(item)
      attributes =
        item
          .with_indifferent_access
          .slice(*SNAPSHOT_FIELDS, :location, :organizer)
          .to_h
      attributes["title"] = attributes["title"].to_s.strip
      %w[location organizer].each do |field|
        next unless attributes.key?(field)
        value = attributes[field]
        raise ArgumentError unless value.nil? || value.is_a?(String)
        attributes[field] = value.to_s.strip
      end
      %w[starts_at ends_at].each do |field|
        value = attributes[field].to_s
        raise ArgumentError unless value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
        Date.iso8601(value)
        attributes[field] = Time.iso8601(value)
      end
      attributes["all_day"] = ActiveModel::Type::Boolean.new.cast(
        attributes["all_day"]
      )
      attributes
    end

    def snapshot
      attributes.slice(*SNAPSHOT_FIELDS)
    end

    def publication_snapshot
      attributes.slice(*PUBLICATION_FIELDS)
    end

    def visible_to?(guardian)
      topic && !topic.deleted_at && IsbfCalendar.official_topic?(topic) &&
        guardian.can_see?(topic) && topic.first_post &&
        !topic.first_post.hidden && guardian.can_see?(topic.first_post)
    end

    private

    def valid_registration_deadline
      return if registration_deadline_id.nil? && registration_deadline.nil?

      deadline = registration_deadline
      if schedule_kind != "event" || !deadline || deadline.cancelled? ||
           deadline.schedule_kind != "deadline" || deadline.topic != topic
        errors.add(:registration_deadline, :invalid)
      end
    end

    def valid_time_range
      return if starts_at.blank? || ends_at.blank?
      valid = ends_at >= starts_at
      valid &&= ends_at == starts_at if schedule_kind == "deadline" && !all_day
      if all_day
        start = starts_at.in_time_zone(TIMEZONE)
        finish = ends_at.in_time_zone(TIMEZONE)
        valid &&=
          start == start.beginning_of_day &&
            finish == finish.beginning_of_day && ends_at > starts_at
        valid &&= ends_at == starts_at + 1.day if schedule_kind == "deadline"
      end
      errors.add(:ends_at, I18n.t("isbf_calendar.invalid_time")) unless valid
    end

    def advance_revision
      self.revision += 1 if REVISION_FIELDS.any? { |field|
        will_save_change_to_attribute?(field)
      }
    end

    def notify_subscribers
      return unless saved_change_to_revision?
      Jobs.enqueue(:isbf_calendar_notify_change, item_id: id, revision:)
    end
  end
end

# == Schema Information
#
# Table name: isbf_calendar_official_items
#
#  id                       :bigint           not null, primary key
#  all_day                  :boolean          default(FALSE), not null
#  cancelled                :boolean          default(FALSE), not null
#  ends_at                  :datetime         not null
#  location                 :string(255)      default(""), not null
#  organizer                :string(120)      default(""), not null
#  position                 :integer          default(0), not null
#  revision                 :integer          default(1), not null
#  schedule_kind            :string           default("event"), not null
#  starts_at                :datetime         not null
#  title                    :string(120)      not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  registration_deadline_id :bigint
#  topic_id                 :bigint           not null
#
# Indexes
#
#  idx_isbf_calendar_items_topic                                   (topic_id,position)
#  index_isbf_calendar_official_items_on_registration_deadline_id  (registration_deadline_id)
#
