# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroups::Runner
  include DiscourseAcademyRoles::StudentGroups

  def self.call(batch_id:)
    batch = DiscourseAcademyRoles::StudentGroupBatch.find_by(id: batch_id)
    return unless batch
    DiscourseAcademyRoles::StudentGroupBatch.mutex(batch.id) do
      return unless batch.reload.state.in?(%w[queued running])
      unless SiteSetting.academy_roles_enabled? && batch.actor&.admin?
        batch.update!(state: "blocked", finished_at: Time.current)
        batch.publish_progress!
        return
      end
      batch.update!(state: "running")
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      batch.items.where(selected: true, status: %w[queued running]).order(:position).limit(CHUNK_SIZE).each do |item|
        break if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at >= CHUNK_BUDGET
        break if batch.reload.state == "blocked"
        unless batch.actor&.reload&.admin? && SiteSetting.academy_roles_enabled?
          batch.update!(state: "blocked", finished_at: Time.current)
          break
        end
        DistributedMutex.synchronize("academy-group-user-#{item.user_id}", validity: 600) do
          new(batch, item).run
        end
      end
      unless batch.state == "blocked"
        remaining = batch.items.where(selected: true, status: %w[queued running]).exists?
        if remaining
          batch.update!(state: "queued")
        else
          unsuccessful = batch.items.where(selected: true).where.not(status: "success").exists?
          batch.update!(state: unsuccessful ? "partial" : "completed", finished_at: Time.current)
        end
      end
      batch.publish_progress!
    end
    Jobs.enqueue(:academy_student_group_batch, batch_id: batch.id) if batch.reload.state == "queued"
  end

  def initialize(batch, item)
    @batch = batch
    @item = item
  end

  def run
    @item.reload
    if @item.steps.any? { |step| %w[started uncertain].include?(step["state"]) }
      conflict!(:uncertain_result)
      return
    end
    unless valid_context?
      conflict!(:changed_since_preview)
      return
    end
    @item.update!(status: "running", reason_code: "")
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @item.steps.each_with_index do |step, index|
      next if step["state"] == "done"
      if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at >= USER_SLICE_BUDGET
        @item.update!(status: "queued")
        return
      end
      return unless apply_step(step, index)
    end
    return if @batch.undo? && !@item.display_restored && !restore_display
    @item.update!(status: "success", reason_code: "", after_snapshot: current_snapshot)
    Discourse.request_refresh!(user_ids: [@item.user_id])
  rescue StandardError => error
    return if @item.reload.status == "success"
    # A native callback can fail after its membership transaction committed.
    # An unrecorded outcome must never be replayed as a fresh operation.
    if @item.reload.steps.any? { |step| step["state"] == "started" }
      conflict!(:uncertain_result)
    else
      @item.update!(status: @item.completed_steps.empty? ? "failed" : "partial", reason_code: "execution_failed")
    end
    Rails.logger.warn("[academy student group batch #{@batch.id}] #{error.class.name}")
  end

  private

  def valid_context?
    @batch.actor&.reload&.admin? && SiteSetting.academy_roles_enabled? &&
      (!@batch.undo? || (@batch.source_batch.reload.terminal? && Snapshot.restorable_display?(@item.source_item))) &&
      @item.binding_matches? &&
      Groups.valid_plan?(@batch.plan, mode: @batch.undo? ? @batch.source_batch.mode : @batch.mode) &&
      Snapshot.matches?(@item.user, @item.expected_snapshot, @batch.group_ids)
  end

  def current_snapshot
    Snapshot.capture(@item.user, @batch.group_ids)
  end

  def apply_step(step, index)
    unless valid_context?
      conflict!(:changed_since_preview)
      return false
    end
    step["state"] = "started"
    @item.update!(steps: @item.steps)
    attempted = false
    applied = false
    Group.transaction do
      group = Group.lock.find_by(id: step.fetch("group_id"))
      @item.user.lock!
      GroupUser.where(user_id: @item.user_id, group_id: @batch.group_ids).lock.load
      unless group && valid_context?
        raise Error, :changed_since_preview
      end
      if step["operation"] == "remove" && GroupUser.exists?(group_id: group.id, user_id: @item.user_id, owner: true)
        raise Error, :account_or_owner
      end
      before = current_snapshot
      step["before"] = before
      attempted = true
      changed_ids = step["operation"] == "add" ? group.bulk_add([@item.user_id]) : group.bulk_remove([@item.user_id])
      after = current_snapshot
      member = after.dig("memberships", group.id.to_s)
      applied = step["operation"] == "add" ? member.present? && !member["owner"] : member.nil?
      raise Error, :uncertain_result unless changed_ids.include?(@item.user_id) && applied
      logger = GroupActionLogger.new(@batch.actor, group)
      subject = "academy-group-batch:#{@batch.id}:#{@item.id}:#{index}"
      if step["operation"] == "add"
        logger.log_add_user_to_group(@item.user, subject)
      else
        logger.log_remove_user_from_group(@item.user, subject)
      end
      step["state"] = "done"
      step["after"] = after
      @item.update!(steps: @item.steps, after_snapshot: after)
    end
    applied
  rescue StandardError => error
    @item.reload
    steps = @item.steps
    steps[index]["state"] = attempted ? "uncertain" : "pending"
    @item.update!(steps:)
    if attempted
      conflict!(:uncertain_result)
    elsif error.is_a?(Error)
      conflict!(error.code)
    else
      @item.update!(status: @item.completed_steps.empty? ? "failed" : "partial", reason_code: "execution_failed")
    end
    false
  end

  def restore_display
    source = @item.source_item
    unless source && @item.binding_matches? && Groups.valid_plan?(@batch.plan, mode: @batch.source_batch.mode)
      conflict!(:changed_since_execution)
      return false
    end
    restored = false
    @item.user.with_lock do
      if Snapshot.matches?(@item.user, @item.expected_snapshot, @batch.group_ids) && Snapshot.restorable_display?(source, after_steps: true)
        target = source.before_snapshot.fetch("display")
        @item.user.update!(target)
        @item.update!(after_snapshot: current_snapshot, display_restored: true)
        restored = true
      end
    end
    conflict!(:changed_since_execution) unless restored
    Discourse.request_refresh!(user_ids: [@item.user_id]) if restored
    restored
  end

  def conflict!(reason)
    @item.update!(status: "conflict", reason_code: reason.to_s)
  end
end
