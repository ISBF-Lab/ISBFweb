# frozen_string_literal: true

module DiscourseAvatarFrames
  class SaveFrame
    include Service::Base

    policy :can_manage

    model :frame_defaults, :fetch_frame_defaults, optional: true

    params default_values_from: :frame_defaults do
      attribute :frame_id, :integer
      attribute :name, :string
      attribute :description, :string, default: ""
      attribute :access_mode, :string, default: "granted"
      attribute :enabled, :boolean, default: true
      attribute :position, :integer, default: 0
      attribute :image_upload_id, :integer
      attribute :static_upload_id, :integer
      attribute :scale, :float, default: 120
      attribute :offset_x, :float, default: 0
      attribute :offset_y, :float, default: 0
      attribute :confirm_calibration, :boolean, default: false

      validates :name, presence: true, length: { maximum: 100 }
      validates :description, length: { maximum: 500 }
      validates :access_mode, inclusion: { in: %w[public granted] }
      validates :scale, numericality: { greater_than_or_equal_to: 50, less_than_or_equal_to: 300 }
      validates :offset_x,
                :offset_y,
                numericality: {
                  greater_than_or_equal_to: -100,
                  less_than_or_equal_to: 100,
                }
      validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      before_validation { self.name = name&.strip }
    end

    model :frame, :build_frame

    transaction do
      step :save_frame
      step :log_change
    end

    private

    def can_manage(guardian:)
      guardian.is_admin?
    end

    def fetch_frame_defaults(params:)
      frame_id = params.to_h.with_indifferent_access[:frame_id]
      frame_id.present? ? Frame.find_by(id: frame_id)&.attributes || {} : {}
    end

    def build_frame(params:)
      frame = params.frame_id ? Frame.find_by(id: params.frame_id) : Frame.new
      frame&.assign_attributes(
        params.slice(
          :name,
          :description,
          :access_mode,
          :enabled,
          :position,
          :image_upload_id,
          :static_upload_id,
          :scale,
          :offset_x,
          :offset_y,
          :confirm_calibration,
        ),
      )
      frame
    end

    def save_frame(frame:)
      frame.save!
    end

    def log_change(frame:, guardian:)
      StaffActionLogger.new(guardian.user).log_custom(
        "avatar_frame_saved",
        frame_key: frame.key,
        frame_name: frame.name,
        enabled: frame.enabled?,
      )
    end
  end
end
