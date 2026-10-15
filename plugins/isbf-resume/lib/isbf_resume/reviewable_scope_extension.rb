# frozen_string_literal: true

module IsbfResume
  module ReviewableScopeExtension
    def viewable_by(user, **options)
      scope = super
      return scope if user&.guardian&.can_review_isbf_resumes?
      scope.where.not(type: "ReviewableIsbfResume")
    end
  end
end
