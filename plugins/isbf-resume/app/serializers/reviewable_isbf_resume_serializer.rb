# frozen_string_literal: true

class ReviewableIsbfResumeSerializer < ReviewableSerializer
  attributes :shared_resume, :can_edit_resume

  def attributes
    super.tap { |data| data[:payload] = object.editable_payload }
  end

  def can_edit
    false
  end

  def can_edit_resume
    editable_fields.present?
  end

  def shared_resume
    IsbfResume::PrivateSharedResumeSerializer.new(
      object.shared_resume,
      scope: scope,
      root: false,
    ).as_json
  end
end
