# frozen_string_literal: true

module DiscourseAvatarFrames
  class ImportsController < AdminController
    def index
      imports = Import.where(frame_id: params[:frame_id]).order(id: :desc).limit(20)
      render_serialized(imports, ImportSerializer, root: :imports)
    end

    def show
      import = Import.find_by(id: params[:id])
      raise Discourse::NotFound unless import
      render_serialized(import, ImportSerializer, root: :import)
    end

    def create
      CreateImport.call(service_params) do
        on_success do |import:|
          render_serialized(import, ImportSerializer, root: :import, status: 201)
        end
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_model_not_found(:frame) { raise Discourse::NotFound }
        on_model_not_found(:import) do |failure|
          if failure.exception.is_a?(CsvRecipients::Invalid)
            render_json_error(failure.exception.message, status: 422)
          else
            raise failure.exception || Discourse::NotFound
          end
        end
        on_failure { render_json_error(I18n.t("avatar_frames.errors.unavailable"), status: 422) }
      end
    end
  end
end
