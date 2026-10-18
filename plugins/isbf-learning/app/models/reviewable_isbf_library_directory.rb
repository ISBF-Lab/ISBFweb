# frozen_string_literal: true

class ReviewableIsbfLibraryDirectory < Reviewable
  include ReviewableActionBuilder

  def serializer
    ReviewableIsbfLibraryDirectorySerializer
  end

  def build_combined_actions(actions, guardian, _args)
    return unless pending? && can_review_target?(guardian)
    build_action(
      actions,
      :approve_directory,
      icon: "check",
      button_class: "btn-primary",
      source: "isbf_library",
    )
    build_action(actions, :reject_directory, icon: "xmark", source: "isbf_library")
  end

  def perform(performed_by, action_id, args = nil)
    IsbfLibrary::Catalog.synchronize { super }
  end

  def perform_approve_directory(performed_by, _args)
    entry =
      IsbfLibrary::Catalog.approve_locked(
        performed_by,
        kind: payload.fetch("kind"),
        name: payload.fetch("name"),
        category_id: payload["category_id"],
      )
    self.payload = payload.merge("directory_id" => entry.fetch("id"))
    create_result(:success, :approved)
  rescue IsbfLearning::StorageError
    create_result(:failure).tap do |result|
      result.errors = [I18n.t("isbf_library.directory_storage_error")]
    end
  end

  def perform_reject_directory(_performed_by, _args)
    create_result(:success, :rejected)
  end

  private

  def can_review_target?(guardian)
    guardian.is_staff? && IsbfLibrary.enabled? && category_id == IsbfLibrary.category_id &&
      category && guardian.can_see_category?(category) && !guardian.user.silenced? &&
      !guardian.user.suspended? && super
  end
end
