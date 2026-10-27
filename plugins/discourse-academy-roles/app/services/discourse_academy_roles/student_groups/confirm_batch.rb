# frozen_string_literal: true

class DiscourseAcademyRoles::StudentGroups::ConfirmBatch
  include Service::Base

  params do
    attribute :batch_id, :integer
    attribute :selected_item_ids, :array, default: []
    validates :batch_id, presence: true
  end

  policy :developer
  model :batch
  policy :initiator
  step :queue_confirmed_accounts

  private

  def developer(guardian:)
    SiteSetting.academy_roles_enabled? && guardian.user&.admin?
  end

  def fetch_batch(params:)
    DiscourseAcademyRoles::StudentGroupBatch.find_by(id: params.batch_id)
  end

  def initiator(batch:, guardian:)
    batch.actor_id == guardian.user.id
  end

  def queue_confirmed_accounts(batch:, params:, guardian:)
    DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
      actor: guardian.user,
      batch:,
      selected_item_ids: params.selected_item_ids,
    )
  end
end
