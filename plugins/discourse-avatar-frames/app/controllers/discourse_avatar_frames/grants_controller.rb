# frozen_string_literal: true

module DiscourseAvatarFrames
  class GrantsController < AdminController
    PAGE_SIZE = 50

    def index
      frame = Frame.find_by(id: params[:frame_id])
      raise Discourse::NotFound unless frame
      grants =
        frame
          .grants
          .includes(:granted_by, user: %i[primary_group flair_group])
          .order(granted_at: :desc)
      if params[:username].present?
        grants =
          grants.joins(:user).where(
            "users.username_lower LIKE ?",
            "%#{User.sanitize_sql_like(params[:username].downcase)}%",
          )
      end
      offset = [fetch_int_from_params(:offset, default: 0), 0].max
      render json: {
               grants:
                 ActiveModel::ArraySerializer.new(
                   grants.limit(PAGE_SIZE).offset(offset),
                   each_serializer: GrantSerializer,
                   scope: guardian,
                   root: false,
                 ).as_json,
               total: grants.count,
             }
    end

    def create
      user_id = params[:user_id]
      if user_id.blank? && params[:username].present?
        user_id = User.find_by(username_lower: params[:username].downcase)&.id
      end
      GrantFrame.call(service_params.deep_merge(params: { user_id: })) do
        on_success do |grant:|
          render json: {
                   grant: GrantSerializer.new(grant, scope: guardian, root: false).as_json,
                   newly_granted: grant.previously_new_record?,
                 },
                 status: grant.previously_new_record? ? 201 : 200
        end
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_model_not_found(:frame) { raise Discourse::NotFound }
        on_model_not_found(:user) { raise Discourse::NotFound }
        on_failure { render_json_error(I18n.t("avatar_frames.errors.unavailable"), status: 422) }
      end
    end

    def destroy
      RevokeFrame.call(service_params) do
        on_success { head :no_content }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_model_not_found(:grant) { raise Discourse::NotFound }
        on_failure { render_json_error(I18n.t("avatar_frames.errors.unavailable"), status: 422) }
      end
    end
  end
end
