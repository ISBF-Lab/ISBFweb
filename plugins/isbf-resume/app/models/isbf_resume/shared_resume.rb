# frozen_string_literal: true

module IsbfResume
  class SharedResume < ActiveRecord::Base
    self.table_name = "isbf_resume_shared_resumes"

    class ReviewConflict < StandardError
    end

    FIELD_LIMITS = {
      title: 200,
      industry: 120,
      position: 120,
      salary: 120,
      experience: 80,
      description: 2000,
    }.freeze
    STATUSES = %w[pending approved rejected].freeze

    belongs_to :user, optional: true
    has_many :reviews, class_name: "IsbfResume::ShareReview", foreign_key: :shared_resume_id

    validates :user_id, :storage_key, :file_sha256, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :pages,
              numericality: {
                only_integer: true,
                greater_than: 0,
                less_than_or_equal_to: SharedPdf::MAX_PAGES,
              }
    validates :description, presence: true, if: :approved?
    FIELD_LIMITS.each { |field, limit| validates field, length: { maximum: limit } }
    validates :submitted_description, length: { maximum: FIELD_LIMITS[:description] }

    scope :published, -> { where(status: "approved") }

    after_create :queue_review

    def reviewable
      ReviewableIsbfResume.find_by("payload ->> 'shared_resume_id' = ?", id.to_s)
    end

    def self.submit(file:, user:, details:)
      pdf = SharedPdf.store(file)
      shared_resume =
        create(
          details.except(:description).merge(
            user: user,
            title:
              details[:title].presence || pdf.filename_title.presence ||
                I18n.t("isbf_resume.sharing.untitled"),
            submitted_description: details[:description],
            uploader_name: user.name.presence || user.username,
            uploader_username: user.username,
            storage_key: pdf.key,
            file_sha256: pdf.sha256,
            file_bytes: pdf.bytes,
            pages: pdf.pages,
            status: "pending",
          ),
        )
      shared_resume
    ensure
      pdf&.discard! unless shared_resume&.persisted?
    end

    def approved?
      status == "approved"
    end

    def pending?
      status == "pending"
    end

    def pdf
      SharedPdf.new(key: storage_key, pages: pages)
    end

    def review!(reviewer:, decision:, description:, expected_version:, metadata: {})
      with_lock do
        raise Discourse::InvalidAccess unless reviewer.guardian.can_review_isbf_resumes?
        raise ReviewConflict unless pending? && lock_version == expected_version
        final_description = description.to_s.strip
        if %w[approve reject].exclude?(decision) ||
             final_description.length > FIELD_LIMITS[:description] ||
             (decision == "approve" && final_description.blank?)
          raise Discourse::InvalidParameters.new(:description)
        end
        final_metadata = metadata.symbolize_keys
        final_metadata.each do |field, value|
          limit = FIELD_LIMITS.except(:description)[field]
          unless limit && value.is_a?(String) && value.length <= limit
            raise Discourse::InvalidParameters.new(field)
          end
        end
        final_metadata.transform_values!(&:strip)
        final_metadata[:title] = title if final_metadata.key?(:title) &&
          final_metadata[:title].blank?
        timestamp = Time.now.utc
        reviews.create!(
          reviewer: reviewer,
          reviewer_name: reviewer.name.presence || reviewer.username,
          reviewer_username: reviewer.username,
          decision: decision,
          original_description: submitted_description,
          previous_description: self.description,
          description: final_description,
          created_at: timestamp,
          updated_at: timestamp,
        )
        update!(
          final_metadata.merge(
            status: decision == "approve" ? "approved" : "rejected",
            description: final_description,
            reviewed_at: timestamp,
          ),
        )
      end
    end

    def revise!(reviewer:, details:)
      with_lock do
        raise Discourse::InvalidAccess unless reviewer.guardian.can_review_isbf_resumes?
        raise ReviewConflict unless approved?
        updates = details.symbolize_keys
        updates.each do |field, value|
          limit = FIELD_LIMITS[field]
          unless limit && value.is_a?(String) && value.length <= limit
            raise Discourse::InvalidParameters.new(field)
          end
        end
        updates.transform_values!(&:strip)
        updates[:title] = title if updates.key?(:title) && updates[:title].blank?
        final_description = updates.fetch(:description, description)
        raise Discourse::InvalidParameters.new(:description) if final_description.blank?
        reviews.create!(
          reviewer: reviewer,
          reviewer_name: reviewer.name.presence || reviewer.username,
          reviewer_username: reviewer.username,
          decision: "edit",
          original_description: submitted_description,
          previous_description: description,
          description: final_description,
        )
        update!(updates)
      end
    end

    private

    def queue_review
      ReviewableIsbfResume.create!(
        created_by: user,
        target_created_by: user,
        reviewable_by_moderator: true,
        force_review: true,
        status: status,
        payload:
          attributes.slice(*FIELD_LIMITS.keys.map(&:to_s)).merge(
            "shared_resume_id" => id,
            "description" => submitted_description,
          ),
      )
    end
  end
end

# == Schema Information
#
# Table name: isbf_resume_shared_resumes
#
#  id                    :bigint           not null, primary key
#  description           :text             default(""), not null
#  experience            :text             default(""), not null
#  file_bytes            :bigint           not null
#  file_sha256           :string(64)       not null
#  industry              :text             default(""), not null
#  lock_version          :integer          default(0), not null
#  pages                 :integer          not null
#  position              :text             default(""), not null
#  reviewed_at           :datetime
#  salary                :text             default(""), not null
#  status                :string           default("pending"), not null
#  storage_key           :string           not null
#  submitted_description :text             default(""), not null
#  title                 :text             default(""), not null
#  uploader_name         :text             default(""), not null
#  uploader_username     :text             default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :integer          not null
#
# Indexes
#
#  index_isbf_resume_shared_resumes_on_storage_key  (storage_key) UNIQUE
#  isbf_resume_shares_owner                         (user_id,created_at,id)
#  isbf_resume_shares_published                     (status,reviewed_at,id)
#  isbf_resume_shares_queue                         (status,created_at,id)
#
