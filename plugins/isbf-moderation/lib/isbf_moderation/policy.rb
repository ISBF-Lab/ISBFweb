# frozen_string_literal: true

module IsbfModeration
  module Policy
    def self.normal_user?(user)
      user.present? && user.id.positive? && user.active? && !user.staged? && !user.anonymous? &&
        !user.suspended? && !user.silenced?
    end

    def self.forum_post?(post)
      post.present? && !post.trashed? && post.user_id.to_i.positive? &&
        post.post_type == Post.types[:regular] && post.topic.present? &&
        post.topic.archetype == Archetype.default && !post.topic.trashed?
    end

    def self.can_report?(user, post, guardian: nil)
      return false unless SiteSetting.isbf_severe_reports_enabled && normal_user?(user)
      return false unless forum_post?(post) && !post.hidden? && post.topic.visible?

      (guardian || Guardian.new(user)).can_see_post?(post)
    end

    def self.staff_reviewer?(user, post)
      user.present? && user.id.positive? && user.staff? && Guardian.new(user).can_review_post?(post)
    end
  end
end
