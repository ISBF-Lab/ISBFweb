# frozen_string_literal: true

require "csv"

module DiscourseAvatarFrames
  class CsvRecipients
    class Invalid < StandardError
    end

    MAX_ENTRIES = 50_000
    HEADERS = %w[username email].freeze

    attr_reader :user_ids, :unmatched_entries, :duplicate_count

    def initialize(file)
      entries = []
      CSV.foreach(file.tempfile.path, encoding: "bom|utf-8") do |row|
        entry = row.first&.strip&.downcase
        next if entry.blank?
        next if entries.empty? && HEADERS.include?(entry)
        entries << entry
        if entries.length > MAX_ENTRIES
          raise Invalid, I18n.t("avatar_frames.errors.too_many_csv_entries", count: MAX_ENTRIES)
        end
      end
      raise Invalid, I18n.t("avatar_frames.errors.empty_csv") if entries.empty?

      emails, usernames = entries.uniq.partition { |entry| entry.include?("@") }
      username_ids =
        User.where(username_lower: usernames).where("users.id > 0").pluck(:username_lower, :id).to_h
      email_ids =
        User
          .with_email(emails)
          .where("users.id > 0")
          .pluck("LOWER(user_emails.email)", "users.id")
          .to_h
      matched = entries.filter_map { |entry| username_ids[entry] || email_ids[entry] }
      anonymous_ids = DiscourseAvatarFrames.anonymous_ids(matched.uniq)
      @user_ids = matched.uniq - anonymous_ids
      @unmatched_entries =
        entries.uniq.select do |entry|
          user_id = username_ids[entry] || email_ids[entry]
          user_id.blank? || anonymous_ids.include?(user_id)
        end
      @duplicate_count = matched.length - matched.uniq.length
    rescue CSV::MalformedCSVError, ArgumentError, Encoding::InvalidByteSequenceError
      raise Invalid, I18n.t("avatar_frames.errors.invalid_csv")
    end
  end
end
