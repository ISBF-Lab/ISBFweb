# frozen_string_literal: true

module DiscourseAvatarFrames
  class CreateImport
    include Service::Base

    policy :can_manage

    params do
      attribute :frame_id, :integer
      attribute :file
      validates :frame_id, numericality: { only_integer: true, greater_than: 0 }
      validates :file, presence: true
    end

    model :frame
    policy :can_award
    model :import, :create_import
    step :enqueue_import
    step :log_import

    private

    def can_manage(guardian:)
      guardian.is_admin?
    end

    def fetch_frame(params:)
      Frame.find_by(id: params.frame_id)
    end

    def can_award(frame:)
      frame.grantable?
    end

    def create_import(frame:, guardian:, params:)
      Import.from_csv(frame:, actor: guardian.user, file: params.file)
    end

    def enqueue_import(import:)
      Jobs.enqueue(:avatar_frames_import, import_id: import.id)
    end

    def log_import(import:, guardian:)
      StaffActionLogger.new(guardian.user).log_custom(
        "avatar_frame_imported",
        frame_key: import.frame.key,
        import_id: import.id,
        matched_users: import.matched_count,
      )
    end
  end
end
