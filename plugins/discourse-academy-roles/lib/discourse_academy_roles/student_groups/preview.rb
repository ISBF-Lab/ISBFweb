# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroups::Preview
  include DiscourseAcademyRoles::StudentGroups

  def self.create(actor:, mode:, input_kind:, student_numbers: nil, prefix: nil, file: nil, add_group_ids: [], remove_group_ids: [])
    DiscourseAcademyRoles::StudentGroups.ensure_developer!(actor)
    input = Input.new(kind: input_kind, student_numbers:, prefix:, file:)
    plan = Groups.plan(mode:, add_group_ids:, remove_group_ids:)
    registrations = DiscourseAcademyRoles::StudentRegistration.where(student_number: input.numbers.select { |number| Input.valid_number?(number) }).includes(:user).index_by(&:student_number)
    snapshots = Snapshot.capture_many(registrations.values.filter_map(&:user), plan.fetch("groups").keys)
    DiscourseAcademyRoles::StudentGroupBatch.transaction do
      batch = DiscourseAcademyRoles::StudentGroupBatch.create!(
        actor:, mode:, input_kind:, plan:, expires_at: PREVIEW_LIFETIME.from_now,
        duplicate_count: input.duplicate_count,
      )
      rows = input.numbers.each_with_index.map do |number, position|
        registration = registrations[number]
        attributes = { batch_id: batch.id, position:, student_number: number.gsub(/[\p{Cc}\p{Cf}]/, "�").first(64), registration_id: registration&.id,
          user_id: nil, username: "", status: "ready", reason_code: "", selected: false, before_snapshot: {}, steps: [] }
        if !Input.valid_number?(number)
          attributes.merge!(status: "invalid", reason_code: "invalid_number")
        elsif !registration
          attributes.merge!(status: "unmatched", reason_code: "unmatched")
        elsif !registration.registered?
          attributes.merge!(status: "unregistered", reason_code: "unregistered")
        elsif !registration.user
          attributes.merge!(status: "missing_user", reason_code: "missing_user")
        else
          user = registration.user
          snapshot = snapshots.fetch(user.id)
          steps = plan.fetch("add_group_ids").filter_map do |id|
            { "operation" => "add", "group_id" => id, "state" => "pending" } unless snapshot["memberships"].key?(id.to_s)
          end
          steps += plan.fetch("remove_group_ids").filter_map do |id|
            { "operation" => "remove", "group_id" => id, "state" => "pending" } if snapshot["memberships"].key?(id.to_s)
          end
          conflict = plan.fetch("remove_group_ids").any? { |id| snapshot.dig("memberships", id.to_s, "owner") }
          conflict ||= user.id <= 0 || user.staged? || !user.active? || user.suspended?
          status = conflict ? "conflict" : (steps.empty? ? "no_change" : "ready")
          attributes.merge!(
            user_id: user.id, username: user.username, before_snapshot: snapshot, steps:, status:,
            selected: status == "ready", reason_code: conflict ? "account_or_owner" : "",
          )
        end
        attributes
      end
      DiscourseAcademyRoles::StudentGroupBatchItem.insert_all!(rows, record_timestamps: true)
      batch
    end
  end

  def self.undo(actor:, source:)
    DiscourseAcademyRoles::StudentGroups.ensure_developer!(actor)
    raise Error, :cannot_undo unless source.can_undo?
    DiscourseAcademyRoles::StudentGroupBatch.mutex(source.id) do
      raise Error, :cannot_undo unless source.reload.can_undo?
      DiscourseAcademyRoles::StudentGroupBatch.transaction do
        batch = DiscourseAcademyRoles::StudentGroupBatch.create!(
          actor:, mode: "undo", input_kind: "undo", plan: source.plan,
          source_batch: source, expires_at: PREVIEW_LIFETIME.from_now,
        )
        source.items.order(:position).each do |item|
          next if item.completed_steps.empty?
          steps = item.completed_steps.reverse.map do |step|
            { "operation" => step["operation"] == "add" ? "remove" : "add", "group_id" => step["group_id"], "state" => "pending" }
          end.sort_by { |step| step["operation"] == "add" ? 0 : 1 }
          valid = item.binding_matches? && Groups.valid_plan?(source.plan, mode: source.mode) &&
            Snapshot.matches?(item.user, item.expected_snapshot, source.group_ids) &&
            Snapshot.restorable_display?(item) &&
            item.steps.none? { |step| %w[started uncertain].include?(step["state"]) } &&
            steps.none? { |step| step["operation"] == "remove" && item.expected_snapshot.dig("memberships", step["group_id"].to_s, "owner") }
          DiscourseAcademyRoles::StudentGroupBatchItem.create!(
            batch:, source_item: item, registration_id: item.registration_id, user_id: item.user_id,
            username: item.username, student_number: item.student_number, position: item.position,
            steps:, before_snapshot: item.expected_snapshot, status: valid ? "ready" : "conflict",
            selected: valid, reason_code: valid ? "" : "changed_since_execution",
          )
        end
        batch
      end
    end
  end
end
