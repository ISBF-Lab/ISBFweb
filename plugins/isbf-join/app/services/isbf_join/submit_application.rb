# frozen_string_literal: true

module ::IsbfJoin
  class SubmitApplication
    include Service::Base

    params do
      attribute :name
      attribute :student_id
      attribute :phone
      attribute :submission_id

      include ApplicationFields
    end

    model :application, :register_application
    policy :submission_matches

    private

    def register_application(params:)
      Application.create_or_find_by(submission_id: params.submission_id) do |application|
        application.assign_attributes(params.application_attributes)
      end
    end

    def submission_matches(application:, params:)
      application.application_attributes == params.application_attributes
    end
  end
end
