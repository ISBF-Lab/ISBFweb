# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroups::Confirmation
  include DiscourseAcademyRoles::StudentGroups

  def self.execute(actor:, batch:, selected_item_ids:)
    DiscourseAcademyRoles::StudentGroups.ensure_developer!(actor)
    raise Discourse::InvalidAccess unless batch.actor_id == actor.id
    selected = Groups.ids(selected_item_ids, limit: MAX_ROWS)
    raise Error, :empty_selection if selected.empty?
    enqueue = false
    DiscourseAcademyRoles::StudentGroupBatch.mutex(batch.id) do
      batch.with_lock do
        if batch.state != "preview"
          unless batch.items.where(selected: true).order(:id).pluck(:id) == selected
            raise Error, :already_confirmed
          end
        else
          raise Error, :preview_expired if batch.expires_at <= Time.current
          unless Groups.valid_plan?(
                   batch.plan,
                   mode: batch.undo? ? batch.source_batch.mode : batch.mode,
                 )
            raise Error, :groups_changed
          end
          allowed = batch.items.where(status: "ready").pluck(:id)
          raise Error, :invalid_selection unless (selected - allowed).empty?
          batch
            .items
            .where(status: "ready")
            .where.not(id: selected)
            .update_all(selected: false, status: "excluded", updated_at: Time.current)
          batch
            .items
            .where(id: selected)
            .update_all(selected: true, status: "queued", updated_at: Time.current)
          batch.update!(state: "queued", confirmed_at: Time.current)
          enqueue = true
        end
      end
    end
    Jobs.enqueue(:academy_student_group_batch, batch_id: batch.id) if enqueue
    batch
  end

  def self.retry(actor:, batch:)
    DiscourseAcademyRoles::StudentGroups.ensure_developer!(actor)
    raise Discourse::InvalidAccess unless batch.actor_id == actor.id
    enqueue = false
    DiscourseAcademyRoles::StudentGroupBatch.mutex(batch.id) do
      batch.with_lock do
        raise Error, :cannot_retry unless batch.terminal?
        enqueue =
          batch.state == "blocked" &&
            batch.items.where(selected: true, status: %w[queued running]).exists?
        batch
          .items
          .where(selected: true, status: %w[failed partial])
          .each do |item|
            next unless item.retryable?
            item.update!(status: "queued", reason_code: "")
            enqueue = true
          end
        raise Error, :cannot_retry unless enqueue
        batch.update!(state: "queued", finished_at: nil)
      end
    end
    Jobs.enqueue(:academy_student_group_batch, batch_id: batch.id)
    batch
  end
end
