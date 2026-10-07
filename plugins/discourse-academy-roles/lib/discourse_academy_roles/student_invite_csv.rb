# frozen_string_literal: true

require "csv"

class DiscourseAcademyRoles::StudentInviteCsv
  MAX_ROWS = 1500
  MAX_BYTES = 1.megabyte
  STUDENT_NUMBER_HEADERS = %w[student_number 学号].freeze
  EXPORT_COLUMNS = %w[
    student_number
    invite_key
    link
    expires_at
    result
    reason
  ].freeze

  class InvalidFile < StandardError
  end

  attr_reader :rows, :results

  def initialize(file)
    file.rewind
    content = file.read(MAX_BYTES + 1).to_s.dup.force_encoding(Encoding::UTF_8)
    if content.bytesize > MAX_BYTES
      raise InvalidFile, I18n.t("academy_roles.student_invites.bulk.too_large")
    end
    unless content.valid_encoding?
      raise InvalidFile,
            I18n.t("academy_roles.student_invites.bulk.invalid_encoding")
    end

    parsed_rows = CSV.parse(content.delete_prefix(Encodings::BOM))
    if STUDENT_NUMBER_HEADERS.include?(
         parsed_rows.first&.first.to_s.strip.downcase
       )
      parsed_rows.shift
    end

    if parsed_rows.empty?
      raise InvalidFile, I18n.t("academy_roles.student_invites.bulk.empty_file")
    end
    if parsed_rows.length > MAX_ROWS
      raise InvalidFile,
            I18n.t(
              "academy_roles.student_invites.bulk.too_many_rows",
              count: MAX_ROWS
            )
    end

    @rows =
      parsed_rows.map do |row|
        { student_number: row.first.to_s.strip, column_count: row.length }
      end
    @results = []
  rescue CSV::MalformedCSVError
    raise InvalidFile,
          I18n.t("academy_roles.student_invites.bulk.malformed_csv")
  end

  def row_error(row)
    if row[:student_number].blank?
      I18n.t("academy_roles.student_invites.bulk.missing_student_number")
    elsif row[:column_count] != 1
      I18n.t("academy_roles.student_invites.bulk.single_column_required")
    elsif row[:student_number].length >
          DiscourseAcademyRoles::StudentRegistration::MAX_STUDENT_NUMBER_LENGTH
      I18n.t("academy_roles.student_invites.bulk.student_number_too_long")
    end
  end

  def record(row, status:, registration: nil, reason: nil)
    results << {
      student_number: row[:student_number],
      invite_key: registration&.invite&.invite_key,
      link: registration&.invite&.link,
      expires_at: registration&.invite&.expires_at&.iso8601,
      result: status,
      reason:
    }
  end

  def created_count
    results.count { |result| result[:result] == :created }
  end

  def skipped_count
    results.count { |result| result[:result] == :skipped }
  end

  def failed_count
    results.count { |result| result[:result] == :failed }
  end

  def to_csv
    Encodings::BOM +
      CSV.generate(row_sep: "\r\n", force_quotes: true) do |csv|
        csv << EXPORT_COLUMNS.map do |column|
          I18n.t("academy_roles.student_invites.bulk.columns.#{column}")
        end
        results.each do |result|
          csv << EXPORT_COLUMNS.map do |column|
            value = result[column.to_sym]
            value =
              I18n.t(
                "academy_roles.student_invites.bulk.results.#{value}"
              ) if column == "result"
            escape_cell(value)
          end
        end
      end
  end

  private

  def escape_cell(value)
    text = value.to_s
    text.match?(/\A[=+\-@\t\r\n]/) ? "'#{text}" : text
  end
end
