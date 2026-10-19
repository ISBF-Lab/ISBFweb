# frozen_string_literal: true

module IsbfResume
  module Contributors
    def self.users(student_number)
      validate_number!(student_number)
      if student_number.blank? || !defined?(DiscourseAcademyRoles::StudentRegistration)
        return User.none
      end
      registrations =
        DiscourseAcademyRoles::StudentRegistration
          .where(student_number: student_number)
          .where.not(user_id: nil)
          .select(:user_id)
      User.real.where(id: registrations, staged: false)
    end

    def self.validate_number!(number)
      unless number.is_a?(String) && number.length <= 64 && !number.match?(/[\s\p{Cc}]/)
        raise Discourse::InvalidParameters.new(:student_number)
      end
    end

    def self.validate!(details)
      number = details.fetch(:student_number, "")
      validate_number!(number)
      user_id = details[:contributor_user_id]
      return if user_id.blank?
      unless user_id.to_s.match?(/\A[1-9]\d{0,18}\z/) && users(number).exists?(id: user_id)
        raise Discourse::InvalidParameters.new(:contributor_user_id)
      end
    end
  end
end
