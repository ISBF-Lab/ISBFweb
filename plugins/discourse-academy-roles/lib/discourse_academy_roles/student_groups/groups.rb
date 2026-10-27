# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroups::Groups
  include DiscourseAcademyRoles::StudentGroups

  CONFIG_FIELDS = %w[
    id name automatic automatic_membership_email_domains primary_group title grant_trust_level
    default_notification_level flair_icon flair_upload_id flair_bg_color flair_color
  ].freeze

  def self.allowed?(group)
    group && group.id.positive? && !group.automatic? &&
      !Group::AUTO_GROUPS.value?(group.id) && group.automatic_membership_email_domains.blank?
  end

  def self.available
    Group.where(automatic: false).order(:name).select { |group| allowed?(group) }
  end

  def self.alumni
    return unless defined?(IsbfAlumni) && IsbfAlumni.enabled?
    group = IsbfAlumni.group
    group if allowed?(group)
  end

  def self.fingerprint(group)
    group.attributes.slice(*CONFIG_FIELDS)
  end

  def self.plan(mode:, add_group_ids:, remove_group_ids:)
    add_ids = ids(add_group_ids)
    remove_ids = ids(remove_group_ids)
    if mode == "graduation"
      group = alumni
      raise Error, :alumni_unavailable unless group
      raise Error, :invalid_groups if add_ids.present? && add_ids != [group.id]
      add_ids = [group.id]
    elsif mode != "groups"
      raise Error, :invalid_input
    end
    raise Error, :invalid_groups if (add_ids + remove_ids).empty? || (add_ids & remove_ids).present?
    groups = Group.where(id: add_ids + remove_ids).index_by(&:id)
    unless groups.length == (add_ids + remove_ids).length && groups.values.all? { |group| allowed?(group) }
      raise Error, :invalid_groups
    end
    {
      "add_group_ids" => add_ids,
      "remove_group_ids" => remove_ids,
      "groups" => groups.transform_keys(&:to_s).transform_values { |group| fingerprint(group) },
    }
  end

  def self.valid_plan?(plan, mode:)
    groups = Group.where(id: plan.fetch("groups").keys).index_by { |group| group.id.to_s }
    valid = plan.fetch("groups").all? do |id, fingerprint|
      allowed?(groups[id]) && self.fingerprint(groups[id]) == fingerprint
    end
    valid && (mode != "graduation" || alumni&.id == plan.fetch("add_group_ids").first)
  end

  def self.ids(values, limit: 100)
    values = Array(values).reject(&:blank?)
    raise Error, :invalid_groups if values.length > limit || values.any? { |value| !value.to_s.match?(/\A[1-9]\d*\z/) }
    ids = values.map(&:to_i).uniq.sort
    raise Error, :invalid_groups if ids.any? { |id| id > 9_223_372_036_854_775_807 }
    ids
  end
end
