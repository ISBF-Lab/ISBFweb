# frozen_string_literal: true

module ::IsbfGuides
  module Admin
    class GuidesController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME
      skip_before_action :check_xhr, only: %i[template source]
      before_action :private_response
      before_action :limit_uploads, only: :upload_image
      before_action :limit_imports, only: :import_document
      before_action :ensure_guide_manager

      def index
        page = [params[:page].to_i, 1].max
        guides =
          Guide
            .includes(:draft_revision, :published_revision)
            .order(updated_at: :desc, id: :desc)
            .offset((page - 1) * 30)
            .limit(31)
            .to_a
        render json: {
                 guides: serialize_data(guides.first(30), AdminGuideSerializer),
                 page:,
                 has_more: guides.length > 30,
               }
      end

      def show
        guide = Guide.includes(:draft_revision, :published_revision).find(params[:id])
        render json: {
                 guide: AdminGuideSerializer.new(guide, root: false, scope: guardian).as_json,
               }
      end

      def create
        save_draft(:created)
      end

      def update
        save_draft(:ok)
      end

      def import_document
        ImportDocument.call(
          service_params.deep_merge(
            params: {
              guide_id: params[:id],
            },
            options: {
              file: params[:file],
            },
          ),
        ) do
          on_success do |guide:|
            render json: {
                     guide: AdminGuideSerializer.new(guide, root: false, scope: guardian).as_json,
                   },
                   status: params[:id].present? ? :ok : :created
          end
          on_failed_contract do |contract|
            render json: { errors: contract.errors.full_messages }, status: :bad_request
          end
          on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
          on_failed_policy(:valid_upload) { render_invalid("document_invalid_file") }
          on_failed_policy(:current_version) { render_conflict }
          on_model_not_found(:guide) { raise Discourse::NotFound }
          on_exceptions(DocumentError) do |exception|
            render json: { errors: [exception.message] }, status: :unprocessable_entity
          end
          on_exceptions(ActiveRecord::RecordInvalid) do |exception|
            render json: {
                     errors: exception.record.errors.full_messages,
                   },
                   status: :unprocessable_entity
          end
          on_failure { render_invalid }
        end
      end

      def template
        send_data DocumentArchive.template,
                  type: "application/zip",
                  disposition: :attachment,
                  filename: "guide-template.zip"
      end

      def source
        guide = Guide.includes(:draft_revision).find(params[:id])
        raise Discourse::NotFound unless guide.draft_revision
        send_data DocumentArchive.new(revision: guide.draft_revision).data,
                  type: "application/zip",
                  disposition: :attachment,
                  filename: "#{guide.slug}-source.zip"
      end

      def publish
        Publish.call(service_params.deep_merge(params: { guide_id: params[:id] })) do
          on_success do |guide:|
            render json: {
                     guide: AdminGuideSerializer.new(guide, root: false, scope: guardian).as_json,
                   }
          end
          on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
          on_failed_policy(:current_version) { render_conflict }
          on_model_not_found(:guide) { raise Discourse::NotFound }
          on_failure { render_invalid }
        end
      end

      def unpublish
        Unpublish.call(service_params.deep_merge(params: { guide_id: params[:id] })) do
          on_success do |guide:|
            render json: {
                     guide: AdminGuideSerializer.new(guide, root: false, scope: guardian).as_json,
                   }
          end
          on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
          on_failed_policy(:current_version) { render_conflict }
          on_model_not_found(:guide) { raise Discourse::NotFound }
          on_failure { render_invalid }
        end
      end

      def upload_image
        UploadImage.call(
          service_params.deep_merge(
            params: {
              guide_id: params[:id],
            },
            options: {
              file: params[:file],
            },
          ),
        ) do
          on_success do |image:|
            render json: { image: { id: image.id, url: image.url } }, status: :created
          end
          on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
          on_model_not_found(:guide) { raise Discourse::NotFound }
          on_failure { render_invalid("invalid_image") }
        end
      end

      private

      def save_draft(status)
        SaveDraft.call(service_params.deep_merge(params: { guide_id: params[:id] })) do
          on_success do |guide:|
            render json: {
                     guide: AdminGuideSerializer.new(guide, root: false, scope: guardian).as_json,
                   },
                   status:
          end
          on_failed_contract do |contract|
            render json: { errors: contract.errors.full_messages }, status: :bad_request
          end
          on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
          on_failed_policy(:current_version) { render_conflict }
          on_model_not_found(:guide) { raise Discourse::NotFound }
          on_exceptions(ActiveRecord::RecordInvalid) do |exception|
            render json: {
                     errors: exception.record.errors.full_messages,
                   },
                   status: :unprocessable_entity
          end
          on_failure { render_invalid }
        end
      end

      def render_conflict
        render json: { errors: [I18n.t("isbf_guides.errors.conflict")] }, status: :conflict
      end

      def render_invalid(key = "invalid_content")
        render json: {
                 errors: [I18n.t("isbf_guides.errors.#{key}")],
               },
               status: :unprocessable_entity
      end

      def private_response
        response.headers["Cache-Control"] = "private, no-store"
      end

      def limit_uploads
        RateLimiter.new(current_user, "isbf-guides-images", 30, 1.minute).performed!
      end

      def limit_imports
        RateLimiter.new(current_user, "isbf-guides-imports", 10, 1.minute).performed!
      end

      def ensure_guide_manager
        raise Discourse::InvalidAccess unless guardian.can_manage_isbf_guides?
      end
    end
  end
end
