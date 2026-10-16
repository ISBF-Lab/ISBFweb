# frozen_string_literal: true

module IsbfResume
  class ShareReview < ActiveRecord::Base
    self.table_name = "isbf_resume_share_reviews"

    belongs_to :shared_resume, class_name: "IsbfResume::SharedResume"
    belongs_to :reviewer, class_name: "User", optional: true

    validates :reviewer_id, :reviewer_name, :reviewer_username, presence: true
    validates :decision, inclusion: { in: %w[approve reject edit] }
  end
end

# == Schema Information
#
# Table name: isbf_resume_share_reviews
#
#  id                   :bigint           not null, primary key
#  decision             :string           not null
#  description          :text             default(""), not null
#  original_description :text             default(""), not null
#  previous_description :text             default(""), not null
#  reviewer_name        :text             not null
#  reviewer_username    :text             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  reviewer_id          :integer          not null
#  shared_resume_id     :bigint           not null
#
# Indexes
#
#  isbf_resume_review_history  (shared_resume_id,id)
#
