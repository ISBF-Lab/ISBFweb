# frozen_string_literal: true

module DiscourseAcademyRoles::ModeratorPostDestroyer
  private

  def can_moderate_this_topic?
    super ||
      (
        guardian.academy_restricted_moderator? &&
          DiscourseAcademyRoles::ModeratorPermissions.resource?(@topic) &&
          guardian.academy_can?(:manage_resources) && guardian.can_recover_post?(@post)
      )
  end
end
