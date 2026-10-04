# frozen_string_literal: true

class DiscourseAcademyRoles::StudentRegistration < ActiveRecord::Base
  self.table_name = "academy_student_registrations"

  MAX_STUDENT_NUMBER_LENGTH = 64

  belongs_to :invite, -> { with_deleted }, class_name: "::Invite"
  belongs_to :issued_by, class_name: "::User"
  belongs_to :user, class_name: "::User", optional: true

  before_validation { self.student_number = student_number&.strip }

  validates :student_number,
            presence: true,
            length: {
              maximum: MAX_STUDENT_NUMBER_LENGTH
            },
            uniqueness: true
  validates :invite_id, uniqueness: true
  validates :user_id, uniqueness: true, allow_nil: true
  validate :preserve_identity

  def registered?
    registered_at.present? || user_id.present?
  end

  def status
    return "registered" if registered?
    return "revoked" if invite.nil? || invite.deleted_at? || !invite.link_valid?
    return "expired" if invite.expired?

    "pending"
  end

  private

  def preserve_identity
    return if new_record?

    if will_save_change_to_student_number? || registered_identity_changed?
      errors.add(
        :base,
        I18n.t("academy_roles.student_invites.immutable_identity")
      )
    end
  end

  def registered_identity_changed?
    (registered_at_in_database.present? || user_id_in_database.present?) &&
      %w[user_id registered_at invite_id].any? do |attribute|
        will_save_change_to_attribute?(attribute)
      end
  end
end

# == Schema Information
#
# Table name: academy_student_registrations
#
#  id             :bigint           not null, primary key
#  registered_at  :datetime
#  student_number :string(64)       not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  invite_id      :bigint           not null
#  issued_by_id   :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_academy_student_registrations_on_invite_id       (invite_id) UNIQUE
#  index_academy_student_registrations_on_student_number  (student_number) UNIQUE
#  index_academy_student_registrations_on_user_id         (user_id) UNIQUE WHERE (user_id IS NOT NULL)
#
