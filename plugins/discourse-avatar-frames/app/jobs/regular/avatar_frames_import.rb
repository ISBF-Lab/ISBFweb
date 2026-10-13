# frozen_string_literal: true

module Jobs
  class AvatarFramesImport < ::Jobs::Base
    def execute(args)
      import = DiscourseAvatarFrames::Import.find_by(id: args[:import_id])
      return if import.blank? || import.finished?

      until import.reload.finished?
        actor = User.find_by(id: import.created_by_id)
        if actor.blank? || !actor.admin?
          import.update!(
            status: "failed",
            failed_count: import.failed_count + import.matched_count - import.processed_count,
            failures: [{ message: I18n.t("avatar_frames.errors.admin_required") }],
          )
          break
        end

        result =
          DiscourseAvatarFrames::ProcessImport.call(
            params: {
              import_id: import.id,
            },
            guardian: actor.guardian,
          )
        unless result.success?
          import.update!(
            status: "failed",
            failures: [{ message: I18n.t("avatar_frames.errors.import_failed") }],
          )
          break
        end
      end
    end
  end
end
