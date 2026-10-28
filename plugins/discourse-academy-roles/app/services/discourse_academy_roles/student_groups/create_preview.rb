# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroups::CreatePreview
  include Service::Base

  params do
    attribute :mode, :string, default: "graduation"
    attribute :input_kind, :string, default: "list"
    attribute :student_numbers, :string
    attribute :prefix, :string
    attribute :file
    attribute :add_group_ids, :array, default: []
    attribute :remove_group_ids, :array, default: []

    validates :mode, inclusion: { in: %w[graduation groups] }
    validates :input_kind, inclusion: { in: %w[list csv prefix] }
  end

  policy :developer
  model :batch, :create_preview

  private

  def developer(guardian:)
    SiteSetting.academy_roles_enabled? && guardian.user&.admin?
  end

  def create_preview(params:, guardian:)
    DiscourseAcademyRoles::StudentGroups::Preview.create(
      actor: guardian.user,
      **params.attributes.symbolize_keys,
    )
  end
end
