# frozen_string_literal: true

module IsbfResume
  class SharedResume::Submit
    include Service::Base

    params do
      attribute :file
      attribute :consent, :boolean
      SharedResume::FIELD_LIMITS.each do |field, limit|
        attribute field, :string, default: ""
        validates field, length: { maximum: limit }
      end
      validates :file, presence: true
      validates :consent, inclusion: { in: [true] }

      def details
        SharedResume::FIELD_LIMITS.keys.to_h { |field| [field, public_send(field).to_s.strip] }
      end
    end

    policy :can_submit
    model :shared_resume, :create_shared_resume

    private

    def can_submit(guardian:)
      guardian.can_submit_isbf_resume?
    end

    def create_shared_resume(params:, guardian:)
      SharedResume.submit(file: params.file, user: guardian.user, details: params.details)
    end
  end
end
