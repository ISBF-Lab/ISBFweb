# frozen_string_literal: true

module ::IsbfJoin
  module ApplicationFields
    extend ActiveSupport::Concern

    TEXT_LIMITS = { name: 60, student_id: 40 }.freeze
    FIELD_NAMES = %i[name student_id phone].freeze
    SUBMISSION_ID_PATTERN =
      /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    included do
      before_validation :normalize_application_fields
      validate :validate_application_fields
      validates :submission_id, format: { with: SUBMISSION_ID_PATTERN }
    end

    def application_attributes
      FIELD_NAMES.index_with { |field| public_send(field) }
    end

    private

    def normalize_application_fields
      FIELD_NAMES.each do |field|
        value = public_send(field)
        if value.is_a?(String)
          public_send("#{field}=", value.gsub(/\A[[:space:]\uFEFF]+|[[:space:]\uFEFF]+\z/u, ""))
        end
      end
      self.submission_id = submission_id.downcase if submission_id.is_a?(String)
    end

    def validate_application_fields
      TEXT_LIMITS.each do |field, maximum|
        value = public_send(field)
        if !value.is_a?(String) || value.empty? ||
             value.encode(Encoding::UTF_16LE).bytesize > maximum * 2 ||
             value.match?(/[\u0000-\u001f\u007f]/)
          errors.add(field, I18n.t("isbf_join.errors.#{field}"))
        end
      end

      if !phone.is_a?(String) || phone.length > 30 || !phone.match?(/\A\+?[0-9 ()-]+\z/) ||
           !phone.count("0-9").between?(7, 15)
        errors.add(:phone, I18n.t("isbf_join.errors.phone"))
      end
    end
  end
end
