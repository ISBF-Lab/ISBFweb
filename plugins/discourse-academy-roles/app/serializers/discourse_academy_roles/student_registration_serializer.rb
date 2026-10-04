# frozen_string_literal: true

class DiscourseAcademyRoles::StudentRegistrationSerializer < ApplicationSerializer
  attributes :id,
             :student_number,
             :status,
             :registered_at,
             :created_at,
             :expires_at,
             :invite_key,
             :link

  has_one :user, serializer: BasicUserSerializer, embed: :objects

  def include_student_number?
    scope&.is_admin?
  end

  def expires_at
    object.invite&.expires_at
  end

  def invite_key
    object.invite.invite_key
  end

  def link
    object.invite.link
  end

  def include_invite_key?
    object.status == "pending"
  end

  alias_method :include_link?, :include_invite_key?
end
