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
    return unless editable_resume?(guardian)
    IsbfResume::SharedResume::FIELD_LIMITS.each_key do |field|
      fields.add("payload.#{field}", field == :description ? :textarea : :text)
    end
  end

  def update_fields(params, performed_by, version: nil)
    raise Discourse::InvalidAccess unless editable_resume?(performed_by.guardian)
    updates = params[:payload]
    raise Discourse::InvalidParameters.new(:payload) unless updates.respond_to?(:each_pair)
    edited_payload = payload.merge(editable_payload)
    edited_payload["submitted_details"] ||= shared_resume
      .attributes
      .slice(*IsbfResume::SharedResume::FIELD_LIMITS.keys.map(&:to_s))
      .merge("description" => shared_resume.submitted_description)
    updates.each_pair do |field, value|
      limit = IsbfResume::SharedResume::FIELD_LIMITS[field.to_sym]
      unless limit && value.is_a?(String) && value.length <= limit
        raise Discourse::InvalidParameters.new(field)
      end
      edited_payload[field.to_s] = approved? ? value.strip : value
    end
    if approved?
      edited_payload["title"] = shared_resume.title if edited_payload["title"].blank?
      raise Discourse::InvalidParameters.new(:description) if edited_payload["description"].blank?
    end
    result = false
    Reviewable.transaction do
      result = super({ payload: edited_payload }, performed_by, version: version)
      raise ActiveRecord::Rollback unless result
      if approved?
        shared_resume.revise!(
          reviewer: performed_by,
          details: edited_payload.slice(*IsbfResume::SharedResume::FIELD_LIMITS.keys.map(&:to_s)),
        )
      end
    end
    result
  rescue IsbfResume::SharedResume::ReviewConflict
    raise Reviewable::UpdateConflict
  end

  def editable_payload
    return {} unless shared_resume
    fields = IsbfResume::SharedResume::FIELD_LIMITS.keys.map(&:to_s)
    shared_resume
      .attributes
      .slice(*fields)
      .merge(
        "description" =>
          shared_resume.approved? ? shared_resume.description : shared_resume.submitted_description,
      )
      .merge(payload.slice(*fields))
  end

  def perform_approve_resume(performed_by, args)
    review_resume(performed_by, "approve", args)
  end

  def perform_reject_resume(performed_by, args)
    review_resume(performed_by, "reject", args)
  end

  private

  def editable_resume?(guardian)
    (pending? || approved?) && can_review_target?(guardian) && shared_resume.status == status
  end

  def can_review_target?(guardian)
    guardian.can_review_isbf_resumes? && shared_resume.present? && super
  end

  def review_resume(performed_by, decision, args)
    shared_resume.review!(
      reviewer: performed_by,
      decision: decision,
      description: args.fetch(:description) { editable_payload["description"] },
      metadata: editable_payload.except("description"),
      expected_version: args.fetch(:expected_version) { shared_resume.lock_version },
    )
    self.payload =
      payload.merge(
        shared_resume.attributes.slice(*IsbfResume::SharedResume::FIELD_LIMITS.keys.map(&:to_s)),
      )
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
