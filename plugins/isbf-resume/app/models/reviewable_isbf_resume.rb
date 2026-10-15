# frozen_string_literal: true

class ReviewableIsbfResume < Reviewable
  include ReviewableActionBuilder

  def serializer
    ReviewableIsbfResumeSerializer
  end

  def shared_resume
    @shared_resume ||= IsbfResume::SharedResume.find_by(id: payload["shared_resume_id"])
  end

  def build_combined_actions(actions, guardian, _args)
    return unless pending? && can_review_target?(guardian)
    build_action(
      actions,
      :approve_resume,
      icon: "check",
      button_class: "btn-primary",
      source: "isbf_resume",
    )
    build_action(actions, :reject_resume, icon: "xmark", source: "isbf_resume")
  end

  def build_editable_fields(fields, guardian, _args)
    fields.add("payload.description", :textarea) if pending? && can_review_target?(guardian)
  end

  def update_fields(params, performed_by, version: nil)
    description = params.dig(:payload, :description)
    if !description.is_a?(String) ||
         description.length > IsbfResume::SharedResume::FIELD_LIMITS[:description]
      raise Discourse::InvalidParameters.new(:description)
    end
    super
  end

  def perform_approve_resume(performed_by, args)
    review_resume(performed_by, "approve", args)
  end

  def perform_reject_resume(performed_by, args)
    review_resume(performed_by, "reject", args)
  end

  private

  def can_review_target?(guardian)
    guardian.can_review_isbf_resumes? && shared_resume.present? && super
  end

  def review_resume(performed_by, decision, args)
    shared_resume.review!(
      reviewer: performed_by,
      decision: decision,
      description: args.fetch(:description) { payload["description"] },
      expected_version: args.fetch(:expected_version) { shared_resume.lock_version },
    )
    self.payload = payload.merge("description" => shared_resume.description)
    create_result(:success, decision == "approve" ? :approved : :rejected)
  rescue Discourse::InvalidParameters
    create_result(:failure).tap do |result|
      result.errors = ActiveModel::Errors.new(self)
      result.errors.add(:base, I18n.t("isbf_resume.sharing.review_description_required"))
    end
  rescue IsbfResume::SharedResume::ReviewConflict
    raise Reviewable::UpdateConflict
  end
end
