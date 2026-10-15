# frozen_string_literal: true

module IsbfResume
  module GuardianExtension
    def can_generate_isbf_resume?
      SiteSetting.isbf_resume_enabled && authenticated? && !user.suspended?
    end

    def can_download_isbf_resume?(export)
      can_generate_isbf_resume? && export && export.owner_id == user.id &&
        export.available?
    end
  end
end
