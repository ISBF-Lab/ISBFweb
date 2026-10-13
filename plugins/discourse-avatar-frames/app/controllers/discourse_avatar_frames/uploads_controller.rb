# frozen_string_literal: true

module DiscourseAvatarFrames
  class UploadsController < AdminController
    def create
      RateLimiter.new(
        current_user,
        "avatar-frame-uploads",
        SiteSetting.max_uploads_per_minute,
        1.minute,
      ).performed!
      UploadFrame.call(service_params) do
        on_success do |images:|
          render_serialized(images, UploadPairSerializer, root: false, status: 201)
        end
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_model_not_found(:images) do |failure|
          if failure.exception.is_a?(Png::Invalid)
            render_json_error(failure.exception.message, status: 422)
          else
            raise failure.exception || Discourse::NotFound
          end
        end
        on_failure { render_json_error(I18n.t("avatar_frames.errors.invalid_image"), status: 422) }
      end
    end
  end
end
