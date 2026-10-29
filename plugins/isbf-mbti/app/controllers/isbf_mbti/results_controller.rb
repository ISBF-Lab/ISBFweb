# frozen_string_literal: true

module IsbfMbti
  class ResultsController < BaseController
    requires_login
    before_action :limit_writes, only: %i[create destroy]
    before_action :prevent_private_caching

    rescue_from Questionnaire::InvalidAnswers do
      render json: { errors: [I18n.t("isbf_mbti.invalid_answers")] }, status: :unprocessable_entity
    end

    rescue_from Questionnaire::StaleVersion do
      render json: { errors: [I18n.t("isbf_mbti.stale_version")] }, status: :conflict
    end

    rescue_from Result::SubmissionConflict do
      render json: { errors: [I18n.t("isbf_mbti.submission_conflict")] }, status: :conflict
    end

    rescue_from Result::AccountChanged do
      render json: { errors: [I18n.t("isbf_mbti.account_changed")] }, status: :conflict
    end

    def index
      page = params.fetch(:page, "0").to_s
      raise Discourse::InvalidParameters.new(:page) unless page.match?(/\A\d{1,5}\z/)
      records =
        own_results
          .order(created_at: :desc, id: :desc)
          .offset(page.to_i * PAGE_SIZE)
          .limit(PAGE_SIZE + 1)
          .to_a
      render json: {
               results: serialize_data(records.first(PAGE_SIZE), ResultSerializer),
               has_more: records.size > PAGE_SIZE,
               page: page.to_i,
             }
    end

    def show
      render json: { result: serialize_data(own_results.find(params[:id]), ResultSerializer) }
    end

    def create
      raise Questionnaire::InvalidAnswers if request.content_length.to_i > 32.kilobytes
      result =
        Result.record!(
          user: current_user,
          variant: params[:variant],
          version: params[:version],
          attempt_id: params[:attempt_id],
          answers: params[:answers],
        )
      render json: { result: serialize_data(result, ResultSerializer) }, status: :created
    end

    def destroy
      own_results.find(params[:id]).destroy!
      head :no_content
    end

    private

    def limit_writes
      RateLimiter.new(current_user, "isbf-mbti-write", 30, 1.minute).performed!
    end

    def own_results
      Result.where(user_id: current_user.id)
    end

    def prevent_private_caching
      response.headers["Cache-Control"] = "no-store, private"
    end
  end
end
