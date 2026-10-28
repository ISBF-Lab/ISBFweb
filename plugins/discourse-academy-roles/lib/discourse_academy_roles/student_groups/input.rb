# frozen_string_literal: true

require "csv"

class DiscourseAcademyRoles::StudentGroups::Input
  include DiscourseAcademyRoles::StudentGroups

  attr_reader :numbers, :duplicate_count

  def initialize(kind:, student_numbers: nil, file: nil, prefix: nil)
    values =
      case kind
      when "list"
        text = student_numbers.to_s
        raise Error, :too_large if text.bytesize > MAX_BYTES
        text.split(/[\r\n,;，；\s]+/).reject(&:blank?)
      when "csv"
        read_csv(file)
      when "prefix"
        read_prefix(prefix)
      else
        raise Error, :invalid_input
      end
    raise Error, :empty_input if values.empty?
    raise Error, :too_many if values.length > MAX_ROWS
    @numbers = values.map(&:strip).uniq
    @duplicate_count = values.length - @numbers.length
  end

  def self.valid_number?(number)
    number.present? &&
      number.length <= DiscourseAcademyRoles::StudentRegistration::MAX_STUDENT_NUMBER_LENGTH &&
      !number.match?(/[\p{Cc}\p{Cf}]/)
  end

  private

  def read_csv(file)
    unless file.respond_to?(:tempfile) && file.original_filename.to_s.match?(/\.csv\z/i)
      raise Error, :csv_required
    end
    raise Error, :too_large if file.size > MAX_BYTES
    file.tempfile.rewind
    text = file.tempfile.read(MAX_BYTES + 1).force_encoding(Encoding::UTF_8)
    raise Error, :too_large if text.bytesize > MAX_BYTES
    raise Error, :invalid_utf8 unless text.valid_encoding?
    text = text.delete_prefix("\uFEFF")
    values = []
    CSV
      .parse(text)
      .each_with_index do |row, index|
        next if row.empty? || row.all?(&:blank?)
        raise Error, :single_column unless row.length == 1
        value = row.first.to_s.strip
        next if index.zero? && %w[student_number 学号].include?(value)
        values << value
        raise Error, :too_many if values.length > MAX_ROWS
      end
    values
  rescue CSV::MalformedCSVError
    raise Error, :invalid_csv
  ensure
    file.tempfile.rewind if file.respond_to?(:tempfile)
  end

  def read_prefix(prefix)
    value = prefix.to_s.strip
    raise Error, :invalid_prefix unless self.class.valid_number?(value)
    numbers =
      DiscourseAcademyRoles::StudentRegistration
        .where("student_number LIKE ?", "#{ActiveRecord::Base.sanitize_sql_like(value)}%")
        .order(:student_number)
        .limit(MAX_ROWS + 1)
        .pluck(:student_number)
    raise Error, :too_many if numbers.length > MAX_ROWS
    numbers
  end
end
