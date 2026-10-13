# frozen_string_literal: true

module DiscourseAvatarFrames
  class ProcessImport
    include Service::Base

    BATCH_SIZE = 200

    policy :can_manage

    params do
      attribute :import_id, :integer
      validates :import_id, numericality: { only_integer: true, greater_than: 0 }
    end

    model :import
    only_if :pending? do
      step :process_batch
    end

    private

    def can_manage(guardian:)
      guardian.is_admin?
    end

    def fetch_import(params:)
      Import.includes(:frame).find_by(id: params.import_id)
    end

    def pending?(import:)
      !import.finished?
    end

    def process_batch(import:, guardian:)
      import.frame.with_lock do
        import.with_lock do
          import.status = "processing"
          batch = import.user_ids.slice(import.processed_count, BATCH_SIZE) || []
          batch.each do |user_id|
            result = GrantFrame.call(params: { frame_id: import.frame_id, user_id: }, guardian:)
            if result.success?
              field =
                (
                  if result.grant.previously_new_record?
                    :granted_count
                  else
                    :skipped_count
                  end
                )
              import.public_send("#{field}=", import.public_send(field) + 1)
            else
              import.failed_count += 1
              if import.failures.length < 100
                import.failures += [
                  { user_id:, message: I18n.t("avatar_frames.errors.unavailable") },
                ]
              end
            end
          end
          import.processed_count += batch.length
          import.status = "completed" if import.processed_count >= import.matched_count
          import.save!
        end
      end
    end
  end
end
