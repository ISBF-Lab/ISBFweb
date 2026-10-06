# frozen_string_literal: true

require "time"

module IsbfCalendar
  class EntriesController < BaseController
    before_action :ensure_logged_in

    def index
      from = parse_time(params.require(:from))
      to = parse_time(params.require(:to))
      raise Discourse::InvalidParameters if to <= from || to > from + 62.days

      entries = personal_entries.overlapping(from, to).order(:starts_at, :id)
      render json: { entries: entries.map { |entry| serialize(entry) } }
    end

    def show
      render json: { entry: serialize(owned_entry) }
    end

    def updates
      entries =
        personal_entries
          .pending_updates
          .order(:starts_at, :id)
          .filter_map do |entry|
            data = serialize(entry)
            data if data[:needs_update]
          end
      render json: { entries: }
    end

    def accept_update
      respond_to_update(accept: true)
    end

    def dismiss_update
      respond_to_update(accept: false)
    end

    def create
      entry =
        IsbfCalendar::Entry.new(entry_attributes.merge(user: current_user))
      entry.save!
      render json: { entry: serialize(entry) }, status: :created
    end

    def update
      entry = owned_entry
      if entry.source_item_id && (params.require(:entry).keys - ["note"]).any?
        raise Discourse::InvalidParameters.new(
                I18n.t("isbf_calendar.readonly_fields")
              )
      end
      entry.update!(entry_attributes)
      render json: { entry: serialize(entry) }
    end

    def destroy
      owned_entry.destroy!
      render json: success_json
    end

    private

    def owned_entry
      personal_entries.find(params[:id])
    end

    def personal_entries
      IsbfCalendar::Entry.where(user_id: current_user.id).includes(
        source_item: {
          topic: :first_post
        }
      )
    end

    def respond_to_update(accept:)
      RespondToOfficialUpdate.call(
        params: params.permit(:id, :revision).to_h.merge(accept:),
        guardian: current_user.guardian
      ) do
        on_success do |entry:|
          if accept
            render json: { entry: serialize(entry) }
          else
            head :no_content
          end
        end
        on_failed_contract { raise Discourse::InvalidParameters }
        on_model_not_found(:entry) { raise Discourse::NotFound }
        on_model_not_found(:item) { raise Discourse::NotFound }
        on_failed_policy(:can_respond) { raise Discourse::InvalidAccess }
        on_failed_policy(:current_revision) do
          render_json_error(
            I18n.t("isbf_calendar.version_conflict"),
            status: :conflict
          )
        end
      end
    end

    def entry_attributes
      data =
        params.require(:entry).permit(
          :title,
          :starts_at,
          :ends_at,
          :all_day,
          :note
        )
      attributes = {}
      attributes[:title] = data[:title]&.strip if data.key?(:title)
      attributes[:starts_at] = parse_time(data[:starts_at]) if data.key?(
        :starts_at
      )
      attributes[:ends_at] = parse_time(data[:ends_at]) if data.key?(:ends_at)
      attributes[:all_day] = ActiveModel::Type::Boolean.new.cast(
        data[:all_day]
      ) if data.key?(:all_day)
      attributes[:note] = data[:note]&.strip if data.key?(:note)
      attributes
    end

    def parse_time(value)
      Time.iso8601(value.to_s)
    rescue ArgumentError
      raise Discourse::InvalidParameters
    end

    def serialize(entry)
      EntrySerializer.new(
        entry,
        scope: current_user.guardian,
        root: false
      ).as_json
    end
  end
end
