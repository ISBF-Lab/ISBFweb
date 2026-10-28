# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroupBatch < ActiveRecord::Base
  self.table_name = "academy_student_group_batches"

  belongs_to :actor, class_name: "::User", optional: true
  belongs_to :source_batch, class_name: "DiscourseAcademyRoles::StudentGroupBatch", optional: true
  has_many :items,
           class_name: "DiscourseAcademyRoles::StudentGroupBatchItem",
           foreign_key: :batch_id

  validates :mode, inclusion: { in: %w[graduation groups undo] }
  validates :state, inclusion: { in: %w[preview queued running completed partial blocked] }

  scope :unfinished, -> { where(state: %w[queued running]) }

  def group_ids
    plan.fetch("groups").keys.map(&:to_i)
  end

  def counts
    items.group(:status).count
  end

  def channel
    "/academy-roles/student-group-batches/#{id}"
  end

  def publish_progress!
    increment!(:version)
    MessageBus.publish(
      channel,
      { id:, state:, counts:, version: },
      user_ids: User.where(admin: true).where("id > 0").pluck(:id),
    )
  end

  def undo?
    mode == "undo"
  end

  def terminal?
    %w[completed partial blocked].include?(state)
  end

  def can_retry?
    if state == "blocked" && items.where(selected: true, status: %w[queued running]).exists?
      return true
    end
    terminal? &&
      items
        .where(status: %w[failed partial])
        .where(
          "steps @> ?::jsonb OR (? AND NOT display_restored)",
          [{ state: "pending" }].to_json,
          undo?,
        )
        .exists?
  end

  def can_undo?
    !undo? && terminal? && items.where("steps @> ?::jsonb", [{ state: "done" }].to_json).exists?
  end

  def self.mutex(batch_id, &block)
    DistributedMutex.synchronize("academy-group-batch-#{batch_id}", validity: 600, &block)
  end
end
