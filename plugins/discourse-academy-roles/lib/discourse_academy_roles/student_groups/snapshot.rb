# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroups::Snapshot
  include DiscourseAcademyRoles::StudentGroups

  def self.capture(user, group_ids)
    user.reload
    display_ids = user.attributes.values_at("primary_group_id", "flair_group_id").compact.uniq
    related_ids = (group_ids.map(&:to_i) + display_ids).uniq
    memberships =
      GroupUser
        .where(user_id: user.id, group_id: related_ids)
        .order(:group_id)
        .pluck(:group_id, :id, :owner)
    from_user(user, memberships, Group.where(id: display_ids).index_by(&:id))
  end

  def self.capture_many(users, group_ids)
    display_ids =
      users
        .flat_map { |user| user.attributes.values_at("primary_group_id", "flair_group_id") }
        .compact
        .uniq
    configurations = Group.where(id: display_ids).index_by(&:id)
    related_ids = (group_ids.map(&:to_i) + display_ids).uniq
    memberships =
      GroupUser
        .where(user_id: users.map(&:id), group_id: related_ids)
        .order(:group_id)
        .pluck(:user_id, :group_id, :id, :owner)
        .group_by(&:first)
    users.to_h do |user|
      ids =
        (
          group_ids.map(&:to_i) +
            user.attributes.values_at("primary_group_id", "flair_group_id").compact
        ).uniq
      rows = memberships.fetch(user.id, []).filter_map { |row| row.drop(1) if ids.include?(row[1]) }
      [user.id, from_user(user, rows, configurations)]
    end
  end

  def self.from_user(user, memberships, configurations)
    display_ids = user.attributes.values_at("primary_group_id", "flair_group_id").compact.uniq
    {
      "display" => user.attributes.slice(*DISPLAY_FIELDS),
      "display_groups" =>
        display_ids.to_h do |id|
          [id.to_s, configurations[id] && Groups.fingerprint(configurations[id])]
        end,
      "account" =>
        user.attributes.slice("active", "staged", "admin", "moderator", "suspended_till"),
      "memberships" =>
        memberships.to_h do |group_id, id, owner|
          [group_id.to_s, { "id" => id, "owner" => owner }]
        end,
    }.as_json
  end

  def self.matches?(user, snapshot, group_ids)
    capture(user, group_ids) == snapshot
  end

  def self.restorable_display?(source_item, after_steps: false)
    before = source_item.before_snapshot
    ids = before.fetch("display_groups", {}).keys.map(&:to_i)
    configurations = Group.where(id: ids).index_by { |group| group.id.to_s }
    memberships =
      GroupUser
        .where(user_id: source_item.user_id, group_id: ids)
        .pluck(:group_id, :id, :owner)
        .to_h { |group_id, id, owner| [group_id.to_s, { "id" => id, "owner" => owner }] }
    changed_ids = source_item.completed_steps.map { |step| step["group_id"] }
    before
      .fetch("display_groups", {})
      .all? do |id, configuration|
        expected = before.dig("memberships", id)
        valid_membership =
          (
            if changed_ids.include?(id.to_i)
              !after_steps || memberships[id].present?
            else
              memberships[id] == expected
            end
          )
        configuration && configurations[id] &&
          Groups.fingerprint(configurations[id]) == configuration && expected && valid_membership
      end
  end
end
