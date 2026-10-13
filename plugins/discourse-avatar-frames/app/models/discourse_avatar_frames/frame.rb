# frozen_string_literal: true

module DiscourseAvatarFrames
  class Frame < ActiveRecord::Base
    self.table_name = "discourse_avatar_frames_frames"

    belongs_to :image_upload, class_name: "::Upload", optional: true
    belongs_to :static_upload, class_name: "::Upload", optional: true
    has_many :grants, class_name: "DiscourseAvatarFrames::Grant", dependent: :destroy
    has_many :imports, class_name: "DiscourseAvatarFrames::Import", dependent: :destroy
    has_many :upload_references, as: :target, dependent: :destroy

    attr_accessor :confirm_calibration

    validates :key, presence: true, uniqueness: true, length: { maximum: 64 }
    validates :name, presence: true, length: { maximum: 100 }
    validates :description, length: { maximum: 500 }
    validates :access_mode, inclusion: { in: %w[public granted] }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validate :validate_images
    validates :scale, numericality: { greater_than_or_equal_to: 50, less_than_or_equal_to: 300 }
    validates :offset_x,
              :offset_y,
              numericality: {
                greater_than_or_equal_to: -100,
                less_than_or_equal_to: 100,
              }
    validate :validate_calibration

    scope :active, -> { where(enabled: true) }

    before_validation { self.key ||= SecureRandom.uuid }
    before_validation :update_calibration_confirmation
    after_save :update_upload_references
    after_save { self.confirm_calibration = false }
    after_commit :invalidate_catalog

    def self.available_for(user)
      return none unless user && !DiscourseAvatarFrames.anonymous?(user)

      active.where(access_mode: "public").or(
        active.where(id: Grant.where(user_id: user.id).select(:frame_id)),
      )
    end

    def grantable?
      enabled? && access_mode == "granted"
    end

    def name_key
      if builtin.present? && name == DiscourseAvatarFrames::BUILTINS[builtin]
        "avatar_frames.frames.#{builtin}"
      end
    end

    def image_url
      if builtin.present? && image_upload_id.blank?
        "/plugins/discourse-avatar-frames/images/#{builtin}.png"
      else
        image_upload&.url
      end
    end

    def static_url
      if builtin.present? && static_upload_id.blank?
        "/plugins/discourse-avatar-frames/images/#{builtin}-static.png"
      else
        static_upload&.url
      end
    end

    private

    def update_calibration_confirmation
      if builtin.present? && image_upload_id.blank? && static_upload_id.blank?
        self.calibration_confirmed = true
        return
      end

      if %w[image_upload_id static_upload_id scale offset_x offset_y].any? { |attribute|
           will_save_change_to_attribute?(attribute)
         }
        self.calibration_confirmed = false
      end
      self.calibration_confirmed = true if confirm_calibration == true
    end

    def validate_calibration
      if enabled? && !calibration_confirmed?
        errors.add(:base, I18n.t("avatar_frames.errors.calibration_required"))
      end
    end

    def validate_images
      return if builtin.present? && image_upload_id.blank? && static_upload_id.blank?

      [image_upload, static_upload].each do |upload|
        unless upload && upload.extension == "png" && !upload.secure? &&
                 upload.width.to_i.positive? && upload.width == upload.height
          errors.add(:base, I18n.t("avatar_frames.errors.invalid_image"))
          break
        end
      end
      errors.add(:base, I18n.t("avatar_frames.errors.invalid_static")) if static_upload&.animated?
    end

    def update_upload_references
      UploadReference.ensure_exist!(upload_ids: [image_upload_id, static_upload_id], target: self)
    end

    def invalidate_catalog
      DiscourseAvatarFrames::Cache.reset
      Site.clear_anon_cache!
    end
  end
end
