# frozen_string_literal: true

class ReviewableIsbfResumeSerializer < ReviewableSerializer
  payload_attributes :description
  attributes :shared_resume

  def shared_resume
    IsbfResume::PrivateSharedResumeSerializer.new(
      object.shared_resume,
      scope: scope,
      root: false,
    ).as_json
  end
end
