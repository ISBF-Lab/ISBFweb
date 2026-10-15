# frozen_string_literal: true

module IsbfResume
  class ExportsController < BaseController
    requires_login
    skip_before_action :check_xhr, only: %i[download preview]
    before_action :limit_generation, only: :create

    def create
      if request.raw_post.bytesize > MAX_REQUEST_BYTES
        raise Discourse::InvalidParameters.new(:resume)
      end
      Export::Generate.call(service_params) do
        on_success do |export:|
          render json: ExportSerializer.new(export, root: false).as_json,
                 status: :created
        end
        on_failed_contract do
          render json: {
                   errors: [I18n.t("isbf_resume.invalid_request")]
                 },
                 status: :bad_request
        end
        on_failed_policy(:can_generate) { raise Discourse::InvalidAccess }
        on_exceptions(Generator::InvalidResume) do |exception|
          render json: {
                   errors: [I18n.t("isbf_resume.invalid_fields")],
                   field_errors: exception.field_errors
                 },
                 status: :unprocessable_entity
        end
        on_failure do
          render json: {
                   errors: [I18n.t("isbf_resume.generation_failed")]
                 },
                 status: :unprocessable_entity
        end
      end
    end

    def download
      export = Export.find(params[:export_id])
      unless guardian.can_download_isbf_resume?(export)
        raise Discourse::NotFound
      end
      file_type = params[:file_type]
      path = export.file_path(file_type)
      raise Discourse::NotFound unless path
      response.headers["Cache-Control"] = "private, no-store"
      response.headers["X-Content-Type-Options"] = "nosniff"
      send_file(
        path,
        filename: "resume-#{export.template}.#{file_type}",
        type:
          (
            if file_type == "pdf"
              "application/pdf"
            else
              "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            end
          ),
        disposition:
          file_type == "pdf" && params[:inline] == "1" ? "inline" : "attachment"
      )
    end

    def preview
      export = Export.find(params[:export_id])
      unless guardian.can_download_isbf_resume?(export)
        raise Discourse::NotFound
      end
      path = export.preview_path(params[:page])
      raise Discourse::NotFound unless path
      response.headers["Cache-Control"] = "private, no-store"
      response.headers["X-Content-Type-Options"] = "nosniff"
      send_file(
        path,
        filename: File.basename(path),
        type: "image/png",
        disposition: "inline"
      )
    end

    private

    def limit_generation
      RateLimiter.new(
        current_user,
        "isbf-resume-generate",
        5,
        1.minute
      ).performed!
    end
  end
end
