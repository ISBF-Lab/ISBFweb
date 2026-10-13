# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorTopics
  def private_messages_for_user(user)
    return super unless DiscourseAcademyRoles::ModeratorPermissions.restricted?(user)
    groups = DiscourseAcademyRoles::ModeratorPermissions.group_ids(user, internal: true)
    private_messages.where(id: TopicAllowedUser.where(user_id: user.id).select(:topic_id)).or(
      private_messages.where(id: TopicAllowedGroup.where(group_id: groups).select(:topic_id)),
    )
  end
end
