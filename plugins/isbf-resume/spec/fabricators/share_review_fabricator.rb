# frozen_string_literal: true

Fabricator(:isbf_resume_share_review, class_name: "IsbfResume::ShareReview") do
  shared_resume { Fabricate(:approved_shared_isbf_resume) }
  reviewer { Fabricate(:admin) }
  reviewer_name do |attributes|
    attributes[:reviewer].name.presence || attributes[:reviewer].username
  end
  reviewer_username { |attributes| attributes[:reviewer].username }
  decision "approve"
  original_description { |attributes| attributes[:shared_resume].submitted_description }
  previous_description ""
  description { |attributes| attributes[:shared_resume].description }
end
