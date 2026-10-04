# frozen_string_literal: true

require "time"

module IsbfCalendar
  class EntriesController < BaseController
    before_action :ensure_logged_in

    def index
      from = parse_time(params.require(:from))
      to = parse_time(params.require(:to))
      raise Discourse::InvalidParameters if to <= from || to > from + 62.days

      entries =
        personal_entries.where("starts_at < ? AND ends_at > ?", to, from).order(:starts_at, :id)
      render json: { entries: entries.map { |entry| serialize(entry) } }
    end

    def create
      entry = IsbfCalendar::Entry.new(entry_attributes.merge(user: current_user))
      entry.save!
      render json: { entry: serialize(entry) }, status: :created
    end

    def update
      entry = owned_entry
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
      IsbfCalendar::Entry.where(user_id: current_user.id)
    end

    def entry_attributes
      data = params.require(:entry).permit(:title, :starts_at, :ends_at, :all_day, :note)
      attributes = {}
      attributes[:title] = data[:title]&.strip if data.key?(:title)
      attributes[:starts_at] = parse_time(data[:starts_at]) if data.key?(:starts_at)
      attributes[:ends_at] = parse_time(data[:ends_at]) if data.key?(:ends_at)
      attributes[:all_day] = ActiveModel::Type::Boolean.new.cast(data[:all_day]) if data.key?(
        :all_day,
      )
      attributes[:note] = data[:note]&.strip if data.key?(:note)
      attributes
    end

    def parse_time(value)
      Time.iso8601(value.to_s)
    rescue ArgumentError
      raise Discourse::InvalidParameters
    end

    def serialize(entry)
      {
        id: entry.id,
        title: entry.title,
        starts_at: entry.starts_at.iso8601,
        ends_at: entry.ends_at.iso8601,
        all_day: entry.all_day,
        note: entry.note,
      }
    end
  end
end
