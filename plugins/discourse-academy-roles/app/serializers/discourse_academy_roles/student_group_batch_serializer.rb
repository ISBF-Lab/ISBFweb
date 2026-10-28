# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroupBatchSerializer < ApplicationSerializer
  attributes :id,
             :mode,
             :state,
             :created_at,
             :expires_at,
             :confirmed_at,
             :finished_at,
             :source_batch_id,
             :duplicate_count,
             :counts,
             :version,
             :message_bus_channel,
             :add_groups,
             :remove_groups,
             :selectable_item_ids,
             :selected_item_ids,
             :can_retry,
             :can_undo

  %i[counts selectable_item_ids selected_item_ids can_retry can_undo].each do |attribute|
    define_method("include_#{attribute}?") { !@options[:compact] }
  end

  def message_bus_channel
    object.channel
  end

  def add_groups
    object
      .plan
      .fetch(object.undo? ? "remove_group_ids" : "add_group_ids")
      .map { |id| { id:, name: object.plan.dig("groups", id.to_s, "name") } }
  end

  def remove_groups
    object
      .plan
      .fetch(object.undo? ? "add_group_ids" : "remove_group_ids")
      .map { |id| { id:, name: object.plan.dig("groups", id.to_s, "name") } }
  end

  def selectable_item_ids
    object.items.where(status: "ready").order(:id).pluck(:id)
  end

  def selected_item_ids
    object.items.where(selected: true).order(:id).pluck(:id)
  end

  def can_retry
    object.actor_id == scope.user.id && object.can_retry?
  end

  def can_undo
    object.can_undo?
  end
end
