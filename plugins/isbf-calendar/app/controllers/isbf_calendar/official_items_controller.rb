# frozen_string_literal: true

module IsbfCalendar
  class OfficialItemsController < BaseController
    before_action :ensure_logged_in

    def add
      AddOfficialEntry.call(
        params: params.permit(:id, :revision),
        guardian: current_user.guardian
      ) do
        on_success do |entry:, created:|
          render json: {
                   entry:
                     EntrySerializer.new(
                       entry,
                       scope: current_user.guardian,
                       root: false
                     ).as_json
                 },
                 status: created ? :created : :ok
        end
        on_failed_contract { raise Discourse::InvalidParameters }
        on_model_not_found(:item) { raise Discourse::NotFound }
        on_failed_policy(:can_add) { raise Discourse::InvalidAccess }
        on_failed_policy(:current_revision) do
          render_json_error(
            I18n.t("isbf_calendar.version_conflict"),
            status: :conflict
          )
        end
      end
    end
  end
end
