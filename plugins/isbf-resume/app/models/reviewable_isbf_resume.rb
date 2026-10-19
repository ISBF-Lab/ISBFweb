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
    fields.add("payload.contributor_user_id", :text)
  end

  def update_fields(params, performed_by, version: nil)
    raise Discourse::InvalidAccess unless editable_resume?(performed_by.guardian)
    updates = params[:payload]
    raise Discourse::InvalidParameters.new(:payload) unless updates.respond_to?(:each_pair)
    edited_payload = payload.merge(editable_payload)
    edited_payload["submitted_details"] ||= shared_resume.editable_details.merge(
      "description" => shared_resume.submitted_description,
    )
    IsbfResume::SharedResume
      .normalize_details(updates)
      .each_pair do |field, value|
        edited_payload[field.to_s] = field == :contributor_user_id ? value.to_s : value
      end
    if updates.key?("download_url") || updates.key?(:download_url)
      IsbfResume::SharingLinks.validate!(edited_payload["download_url"])
    end
    IsbfResume::Contributors.validate!(
      edited_payload.symbolize_keys.slice(:student_number, :contributor_user_id),
    )
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
          details: edited_payload.slice(*IsbfResume::SharedResume::EDITABLE_FIELDS.map(&:to_s)),
        )
      end
    end
    result
  rescue IsbfResume::SharedResume::ReviewConflict
    raise Reviewable::UpdateConflict
  end

  def editable_payload
    return {} unless shared_resume
    fields = IsbfResume::SharedResume::EDITABLE_FIELDS.map(&:to_s)
    shared_resume
      .editable_details
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
    self.payload = payload.merge(shared_resume.editable_details)
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

# == Schema Information
#
# Table name: reviewables
#
#  id                      :bigint           not null, primary key
#  force_review            :boolean          default(FALSE), not null
#  latest_score            :datetime
#  payload                 :json
#  potential_spam          :boolean          default(FALSE), not null
#  potentially_illegal     :boolean          default(FALSE)
#  reject_reason           :text
#  reviewable_by_moderator :boolean          default(FALSE), not null
#  score                   :float            default(0.0), not null
#  status                  :integer          default("pending"), not null
#  target_type             :string
#  type                    :string           not null
#  type_source             :string           default("unknown"), not null
#  version                 :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  category_id             :integer
#  created_by_id           :integer          not null
#  target_created_by_id    :integer
#  target_id               :integer
#  topic_id                :integer
#
# Indexes
#
#  idx_reviewables_score_desc_created_at_desc                  (score,created_at)
#  index_reviewables_on_reviewable_by_group_id                 (reviewable_by_group_id)
#  index_reviewables_on_status_and_created_at                  (status,created_at)
#  index_reviewables_on_status_and_score                       (status,score)
#  index_reviewables_on_status_and_type                        (status,type)
#  index_reviewables_on_target_created_by_id                   (target_created_by_id)
#  index_reviewables_on_target_id_where_post_type_eq_post      (target_id) WHERE ((target_type)::text = 'Post'::text)
#  index_reviewables_on_topic_id_and_status_and_created_by_id  (topic_id,status,created_by_id)
#  index_reviewables_on_type_and_target_id                     (type,target_id) UNIQUE
#
