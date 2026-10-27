# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroupBatchItemSerializer < ApplicationSerializer
  attributes :id, :position, :student_number, :username, :user_id, :status, :reason,
             :reason_code, :selected, :selectable, :current_groups, :add_groups,
             :remove_groups, :completed_add_groups, :completed_remove_groups, :steps

  def reason
    I18n.t("academy_roles.student_groups.errors.#{object.reason_code}") if object.reason_code.present?
  end

  def selectable
    object.selectable?
  end

  def current_groups
    object.before_snapshot.fetch("memberships", {}).keys.filter_map do |id|
      @options[:batch].plan.dig("groups", id, "name")
    end
  end

  def add_groups
    object.steps.filter_map do |step|
      @options[:batch].plan.dig("groups", step["group_id"].to_s, "name") if step["operation"] == "add"
    end
  end

  def remove_groups
    object.steps.filter_map do |step|
      @options[:batch].plan.dig("groups", step["group_id"].to_s, "name") if step["operation"] == "remove"
    end
  end

  def completed_add_groups
    object.completed_steps.filter_map do |step|
      @options[:batch].plan.dig("groups", step["group_id"].to_s, "name") if step["operation"] == "add"
    end
  end

  def completed_remove_groups
    object.completed_steps.filter_map do |step|
      @options[:batch].plan.dig("groups", step["group_id"].to_s, "name") if step["operation"] == "remove"
    end
  end

  def steps
    object.steps.map { |step| step.slice("operation", "group_id", "state") }
  end
end
