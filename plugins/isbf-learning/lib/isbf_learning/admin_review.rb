# frozen_string_literal: true

module IsbfLearning
  module AdminReviewScope
    def viewable_by(user, **options)
      scope = super
      IsbfLearning.resource_libraries.each do |library|
        next if user && library.can_review?(user.guardian)
        scope =
          scope.where(
            "NOT (reviewables.type = :type AND (COALESCE(reviewables.category_id, 0) = :category_id OR COALESCE(reviewables.payload ->> :group_field, '') <> ''))",
            type: "ReviewableQueuedPost",
            category_id: library.category_id || -1,
            group_field: library::GROUP_FIELD,
          )
      end
      scope
    end
  end

  module AdminReviewPermission
    private

    def can_review_target?(guardian)
      if library = IsbfLearning.reviewable_resource_library(self)
        unless library.can_review?(guardian) && category && guardian.can_see_category?(category)
          return false
        end
        return false if guardian.user.silenced? || guardian.user.suspended?
      end
      super
    end
  end

  module ContributorReviewSerializer
    def cooked
      body = super
      return body unless IsbfLearning.learning_reviewable?(object)
      library = IsbfLearning.reviewable_resource_library(object)
      name =
        object.payload[library::CONTRIBUTOR_FIELD].presence ||
          IsbfLearning.contributor_name(object.target_created_by)
      "#{body}<p>#{CGI.escapeHTML(I18n.t("isbf_learning.contributor_label"))}: #{CGI.escapeHTML(name)}</p>"
    end
  end
end

Reviewable.singleton_class.prepend(IsbfLearning::AdminReviewScope)
Reviewable.prepend(IsbfLearning::AdminReviewPermission)
ReviewableQueuedPost.before_validation do
  self.reviewable_by_moderator = false if IsbfLearning.learning_reviewable?(self)
end
IsbfLearning.resource_libraries.each do |library|
  ReviewableQueuedPostSerializer.payload_attributes(library::CONTRIBUTOR_FIELD.to_sym)
end
ReviewableQueuedPostSerializer.prepend(IsbfLearning::ContributorReviewSerializer)
