# frozen_string_literal: true

module IsbfResume
  module GuardianExtension
    def can_generate_isbf_resume?
      SiteSetting.isbf_resume_enabled && authenticated? && !user.suspended?
    end

    def can_download_isbf_resume?(export)
      can_generate_isbf_resume? && export && export.owner_id == user.id && export.available?
    end

    def can_submit_isbf_resume?
      can_generate_isbf_resume? && !user.silenced?
    end

    def can_review_isbf_resumes?
      return false unless can_submit_isbf_resume?
      return true if user[:admin]
      user[:moderator] && respond_to?(:academy_can?) && academy_can?(:review_resumes)
    end

    def can_view_shared_isbf_resume?(shared_resume)
      can_generate_isbf_resume? && shared_resume &&
        (shared_resume.approved? || shared_resume.user_id == user.id || can_review_isbf_resumes?)
    end
  end
end
