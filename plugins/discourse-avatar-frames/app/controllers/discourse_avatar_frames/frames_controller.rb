# frozen_string_literal: true

module DiscourseAvatarFrames
  class FramesController < AdminController
    def index
      frames = Frame.includes(:image_upload, :static_upload).order(:position, :id).to_a
      render json: {
               frames:
                 ActiveModel::ArraySerializer.new(
                   frames,
                   each_serializer: FrameSerializer,
                   scope: guardian,
                   root: false,
                   counts: Grant.group(:frame_id).count,
                 ).as_json,
             }
    end

    def show
      frame = Frame.find_by(id: params[:id])
      raise Discourse::NotFound unless frame
      render_serialized(frame, FrameSerializer, root: :frame)
    end

    def create
      SaveFrame.call(service_params) do
        on_success { |frame:| render_serialized(frame, FrameSerializer, root: :frame, status: 201) }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages, status: 422)
        end
        on_model_errors(:frame) do |model|
          render_json_error(model.errors.full_messages, status: 422)
        end
        on_failure { render_json_error(I18n.t("avatar_frames.errors.unavailable"), status: 422) }
      end
    end

    def update
      SaveFrame.call(service_params.deep_merge(params: { frame_id: params[:id] })) do
        on_success { |frame:| render_serialized(frame, FrameSerializer, root: :frame) }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_model_not_found(:frame) { raise Discourse::NotFound }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages, status: 422)
        end
        on_model_errors(:frame) do |model|
          render_json_error(model.errors.full_messages, status: 422)
        end
        on_failure { render_json_error(I18n.t("avatar_frames.errors.unavailable"), status: 422) }
      end
    end
  end
end
