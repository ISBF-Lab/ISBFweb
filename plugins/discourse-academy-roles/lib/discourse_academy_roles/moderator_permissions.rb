# frozen_string_literal: true

module DiscourseAcademyRoles
  module ModeratorPermissions
    SETTINGS = {
      internal_boards: :academy_moderators_access_internal_boards,
      user_admin: :academy_moderators_access_user_admin,
      hidden_content: :academy_moderators_view_hidden_content,
      review: :academy_moderators_review_content,
      edit_others: :academy_moderators_edit_others_content,
      delete_others: :academy_moderators_delete_others_content,
      manage_topics: :academy_moderators_manage_topics,
      edit_users: :academy_moderators_edit_users,
      suspend_users: :academy_moderators_suspend_users,
      silence_users: :academy_moderators_silence_users,
      delete_users: :academy_moderators_delete_users,
      anonymize_users: :academy_moderators_anonymize_users,
      manage_categories: :moderators_manage_categories,
      manage_groups: :moderators_manage_groups,
      publish_activities: :academy_moderators_publish_activities,
      publish_official: :academy_moderators_publish_official,
      review_resources: :academy_moderators_review_resources,
      review_resumes: :academy_moderators_review_resumes,
      manage_resources: :academy_moderators_manage_resources,
      view_emails: :moderators_view_emails,
      trace_anonymous: :academy_moderators_trace_anonymous,
    }.freeze
    ROLE_GROUP_IDS = [
      Group::AUTO_GROUPS[:admins],
      Group::AUTO_GROUPS[:moderators],
      Group::AUTO_GROUPS[:staff],
    ].freeze

    def self.restricted?(user)
      SiteSetting.academy_roles_enabled? && user.present? && user[:moderator] && !user[:admin]
    end

    def self.allowed?(user, permission)
      return false if user.blank?
      return true if user[:admin]
      restricted?(user) && !user.suspended? && !user.silenced? &&
        SiteSetting.public_send(SETTINGS.fetch(permission))
    end

    def self.for(user)
      SETTINGS.keys.to_h { |permission| [permission, allowed?(user, permission)] }
    end

    def self.ordinary_account?(user)
      user.present? && user.id.positive? && !user[:admin] && !user[:moderator]
    end

    def self.group_ids(user, internal: false)
      ids =
        (
          if user.respond_to?(:academy_role_group_ids)
            user.academy_role_group_ids
          else
            user.belonging_to_group_ids
          end
        )
      return ids unless restricted?(user)
      if internal && allowed?(user, :internal_boards)
        ids - [Group::AUTO_GROUPS[:admins]]
      else
        ids - ROLE_GROUP_IDS
      end
    end

    def self.learning_category_id
      if SiteSetting.respond_to?(:isbf_learning_category_id)
        SiteSetting.isbf_learning_category_id.to_i
      else
        0
      end
    end

    def self.resource?(object)
      category_id = object.is_a?(Category) ? object.id : object&.category_id
      category_id.to_i.positive? && category_id.to_i == learning_category_id
    end

    def self.review_permission(reviewable)
      return :review_resumes if reviewable.type == "ReviewableIsbfResume"
      if resource?(reviewable) || reviewable.type == "ReviewableIsbfLearningCourse"
        :review_resources
      else
        :review
      end
    end

    def self.review_edit_permission(reviewable)
      return :review_resumes if reviewable.type == "ReviewableIsbfResume"
      resource?(reviewable) ? :manage_resources : :edit_others
    end

    def self.review_action_allowed?(user, reviewable, action)
      return true unless restricted?(user)
      return false unless allowed?(user, review_permission(reviewable))

      name = action.to_s
      target =
        reviewable.target_created_by || (reviewable.target if reviewable.target_type == "User")
      return false if reviewable.target_type == "User" && !ordinary_account?(reviewable.target)
      requirements = []
      requirements << :suspend_users if name.include?("suspend")
      requirements << :silence_users if name.include?("silence")
      requirements << :delete_users if name.include?("delete_user") || name.include?("block_user")
      restoring_content =
        name.include?("restore") && reviewable.target_type == "Post" &&
          (reviewable.send(:target_post)&.trashed? || reviewable.send(:target_post)&.user_deleted?)
      if (name.include?("delete") && !name.include?("user")) || restoring_content
        requirements << (resource?(reviewable) ? :manage_resources : :delete_others)
      end
      if name.include?("edit") || name.include?("revise") || name.include?("remove_avatar") ||
           name == "scrub"
        requirements << if reviewable.target_type == "User"
          :edit_users
        elsif resource?(reviewable)
          :manage_resources
        else
          :edit_others
        end
      end
      requirements.all? { |permission| allowed?(user, permission) } &&
        (
          if requirements.intersect?(%i[suspend_users silence_users delete_users edit_users])
            ordinary_account?(target)
          else
            true
          end
        )
    end
  end
end
