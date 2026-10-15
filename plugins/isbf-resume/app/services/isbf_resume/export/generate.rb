# frozen_string_literal: true

module IsbfResume
  class Export::Generate
    include Service::Base

    params do
      attribute :resume
      validates :resume, presence: true
      validate :validate_resume_object
      validate :validate_request_size

      def validate_resume_object
        errors.add(:resume, :invalid) unless resume.is_a?(Hash)
      end

      def validate_request_size
        if resume.is_a?(Hash) &&
             JSON.generate(resume).bytesize > MAX_REQUEST_BYTES
          errors.add(:resume, :too_long, count: MAX_REQUEST_BYTES)
        end
      end
    end

    policy :can_generate
    model :export, :create_export
    try Generator::InvalidResume, Generator::GenerationError do
      step :generate_documents
    end

    private

    def can_generate(guardian:)
      guardian.can_generate_isbf_resume?
    end

    def create_export(params:, guardian:)
      Export.create(owner_id: guardian.user.id, resume: params.resume)
    end

    def generate_documents(export:)
      Generator.call(export)
    end
  end
end
