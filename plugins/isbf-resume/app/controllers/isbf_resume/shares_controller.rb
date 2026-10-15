# frozen_string_literal: true

module IsbfResume
  class SharesController < BaseController
    PAGE_SIZE = 20
    MAX_PAGE = 1000

    requires_login
    skip_before_action :check_xhr, only: %i[download preview]
    before_action :limit_submissions, only: :create

    def index
      page = params.fetch(:page, "1").to_s
      unless /\A[1-9]\d{0,3}\z/.match?(page) && page.to_i <= MAX_PAGE
        raise Discourse::InvalidParameters.new(:page)
      end
      list = params.fetch(:list, "published")
      records =
        case list
        when "published"
          SharedResume.published.order(reviewed_at: :desc, id: :desc)
        when "mine"
          SharedResume.where(user_id: current_user.id).order(created_at: :desc, id: :desc)
        when "review"
          raise Discourse::InvalidAccess unless guardian.can_review_isbf_resumes?
          status = params.fetch(:status, "pending")
          raise Discourse::InvalidParameters.new(:status) if SharedResume::STATUSES.exclude?(status)
          SharedResume.where(status: status).order(created_at: :desc, id: :desc)
        else
          raise Discourse::InvalidParameters.new(:list)
        end
      records = records.includes(:reviews) if guardian.can_review_isbf_resumes? &&
        list != "published"
      results = records.offset((page.to_i - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1).to_a
      serializer = list == "published" ? SharedResumeSerializer : PrivateSharedResumeSerializer
      response.headers["Cache-Control"] = "private, no-store"
      render json: {
               shares:
                 results
                   .first(PAGE_SIZE)
                   .map { |record| serializer.new(record, scope: guardian, root: false).as_json },
               can_load_more: results.length > PAGE_SIZE,
               page: page.to_i,
               can_submit: guardian.can_submit_isbf_resume?,
               can_review: guardian.can_review_isbf_resumes?,
             }
    end

    def show
      shared_resume = SharedResume.find_by(id: params[:id])
      raise Discourse::NotFound unless guardian.can_view_shared_isbf_resume?(shared_resume)
      response.headers["Cache-Control"] = "private, no-store"
      serializer =
        if shared_resume.user_id == current_user.id || guardian.can_review_isbf_resumes?
          PrivateSharedResumeSerializer
        else
          SharedResumeSerializer
        end
      render json: serializer.new(shared_resume, scope: guardian, root: false).as_json
    end

    def create
      details =
        params
          .require(:shared_resume)
          .permit(:title, :industry, :position, :salary, :experience, :description, :consent, :file)
          .to_h
      SharedResume::Submit.call(service_params.deep_merge(params: details)) do
        on_success do |shared_resume:|
          render json:
                   PrivateSharedResumeSerializer.new(
                     shared_resume,
                     scope: guardian,
                     root: false,
                   ).as_json,
                 status: :created
        end
        on_failed_contract do
          render_json_error(I18n.t("isbf_resume.sharing.invalid_submission"), status: :bad_request)
        end
        on_failed_policy(:can_submit) { raise Discourse::InvalidAccess }
        on_model_not_found(:shared_resume) do |model_result|
          error_key =
            if model_result.exception.is_a?(SharedPdf::InvalidPdf)
              "isbf_resume.sharing.#{model_result.exception.reason}"
            else
              "isbf_resume.sharing.submit_failed"
            end
          render_json_error(I18n.t(error_key), status: :unprocessable_entity)
        end
        on_failure do
          render_json_error(
            I18n.t("isbf_resume.sharing.submit_failed"),
            status: :unprocessable_entity,
          )
        end
      end
    end

    def review
      details =
        params
          .require(:share_review)
          .permit(:decision, :description, :expected_version)
          .to_h
          .merge(shared_resume_id: params[:id])
      SharedResume::Review.call(service_params.deep_merge(params: details)) do
        on_success do |shared_resume:|
          render json:
                   PrivateSharedResumeSerializer.new(
                     shared_resume,
                     scope: guardian,
                     root: false,
                   ).as_json
        end
        on_failed_policy(:can_review) { raise Discourse::InvalidAccess }
        on_failed_contract do
          render_json_error(
            I18n.t("isbf_resume.sharing.review_description_required"),
            status: :bad_request,
          )
        end
        on_model_not_found(:shared_resume) { raise Discourse::NotFound }
        on_exceptions(SharedResume::ReviewConflict) do
          render_json_error(I18n.t("isbf_resume.sharing.review_conflict"), status: :conflict)
        end
        on_exceptions(Discourse::InvalidAccess) { raise Discourse::InvalidAccess }
        on_failure do
          render_json_error(
            I18n.t("isbf_resume.sharing.review_failed"),
            status: :unprocessable_entity,
          )
        end
      end
    end

    def download
      shared_resume = SharedResume.find_by(id: params[:id])
      raise Discourse::NotFound unless guardian.can_view_shared_isbf_resume?(shared_resume)
      path = shared_resume.pdf.available_path
      raise Discourse::NotFound unless path
      response.headers["Cache-Control"] = "private, no-store"
      response.headers["X-Content-Type-Options"] = "nosniff"
      send_file(
        path,
        filename: "resume-#{shared_resume.id}.pdf",
        type: "application/pdf",
        disposition: "attachment",
      )
    end

    def preview
      shared_resume = SharedResume.find_by(id: params[:id])
      raise Discourse::NotFound unless guardian.can_view_shared_isbf_resume?(shared_resume)
      response.headers["Cache-Control"] = "private, no-store"
      response.headers["X-Content-Type-Options"] = "nosniff"
      path = shared_resume.pdf.render_preview!(params[:page])
      raise Discourse::NotFound unless path
      send_file(path, filename: File.basename(path), type: "image/png", disposition: "inline")
    rescue SharedPdf::PreviewUnavailable
      response.headers["Retry-After"] = "5"
      head :service_unavailable
    end

    private

    def limit_submissions
      RateLimiter.new(current_user, "isbf-resume-share", 3, 1.minute).performed!
    end
  end
end
