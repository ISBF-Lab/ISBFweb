# frozen_string_literal: true

module ::IsbfJoin
  class ApplicationsController < PublicController
    prepend_before_action :validate_request
    before_action :rate_limit_submission

    rescue_from RateLimiter::LimitExceeded do |error|
      response.headers["Retry-After"] = error.available_in.to_s
      render_failure(:rate_limited, status: :too_many_requests)
    end

    def create
      permitted = params.permit(:name, :studentId, :phone, :submissionId)
      application_params = {
        name: permitted[:name],
        student_id: permitted[:studentId],
        phone: permitted[:phone],
        submission_id: permitted[:submissionId],
      }

      SubmitApplication.call(**service_params.deep_merge(params: application_params)) do
        on_success do |application:|
          render json: {
                   ok: true,
                   id: application.submission_id,
                 },
                 status: application.previously_new_record? ? :created : :ok
        end
        on_failed_contract { |contract| render_validation_failure(contract) }
        on_model_errors(:application) { |application:| render_validation_failure(application) }
        on_failed_policy(:submission_matches) { render_failure(:conflict, status: :conflict) }
        on_model_not_found(:application) do
          render_failure(:unavailable, status: :service_unavailable)
        end
      end
    end

    private

    def validate_request
      response.headers["Cache-Control"] = "no-store"
      origin = request.headers["Origin"]
      if (origin.present? && origin != request.base_url) ||
           request.headers["Sec-Fetch-Site"] == "cross-site"
        return render_failure(:cross_site, status: :forbidden)
      end
      if request.media_type != "application/json"
        return render_failure(:json_required, status: :unsupported_media_type)
      end
      body = request.body.read(MAX_BODY_BYTES + 1)
      request.body.rewind
      render_failure(:too_large, status: 413) if body.bytesize > MAX_BODY_BYTES
    end

    def rate_limit_submission
      RateLimiter.new(
        nil,
        "isbf-join-#{request.remote_ip}",
        RATE_LIMIT_COUNT,
        RATE_LIMIT_WINDOW,
      ).performed!
    end

    def render_validation_failure(record)
      field_errors = record.errors.to_hash.transform_keys { |key| key.to_s.camelize(:lower) }
      render json: {
               ok: false,
               errors: field_errors.transform_values(&:first),
               message: I18n.t("isbf_join.errors.invalid"),
             },
             status: :bad_request
    end

    def render_failure(key, status:)
      render json: { ok: false, message: I18n.t("isbf_join.errors.#{key}") }, status: status
    end
  end
end
