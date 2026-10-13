# frozen_string_literal: true

module IsbfCalendar
  class Entry < ActiveRecord::Base
    self.table_name = "isbf_calendar_entries"

    belongs_to :user
    belongs_to :source_item,
               class_name: "IsbfCalendar::OfficialItem",
               optional: true

    validates :title, presence: true, length: { maximum: 120 }
    validates :note, length: { maximum: 2000 }
    validates :starts_at, :ends_at, presence: true
    validates :schedule_kind, inclusion: { in: %w[event deadline] }
    validate :ends_after_start

    scope :overlapping,
          ->(from, to) do
            where(
              "starts_at < :to AND (ends_at > :from OR (starts_at = ends_at AND starts_at >= :from))",
              from:,
              to:
            )
          end
    scope :pending_updates,
          -> do
            joins(:source_item).where(
              "isbf_calendar_official_items.revision > GREATEST(isbf_calendar_entries.accepted_revision, isbf_calendar_entries.dismissed_revision)"
            )
          end

    def needs_update?
      source_item &&
        source_item.revision > [accepted_revision, dismissed_revision].max
    end

    private

    def ends_after_start
      return if starts_at.blank? || ends_at.blank? || ends_at > starts_at
      return if source_item_id.present? && !all_day && ends_at == starts_at

      errors.add(:ends_at, "must be after the start")
    end
  end
end

# == Schema Information
#
# Table name: isbf_calendar_entries
#
#  id                 :bigint           not null, primary key
#  accepted_revision  :integer          default(0), not null
#  all_day            :boolean          default(FALSE), not null
#  dismissed_revision :integer          default(0), not null
#  ends_at            :datetime         not null
#  note               :text
#  notified_revision  :integer          default(0), not null
#  schedule_kind      :string           default("event"), not null
#  starts_at          :datetime         not null
#  title              :string(120)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  source_item_id     :bigint
#  user_id            :bigint           not null
#
# Indexes
#
#  idx_isbf_calendar_entries_source_user          (user_id,source_item_id) UNIQUE WHERE (source_item_id IS NOT NULL)
#  idx_isbf_calendar_user_start                   (user_id,starts_at)
#  index_isbf_calendar_entries_on_source_item_id  (source_item_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
