# frozen_string_literal: true

module DiscourseAvatarFrames
  class FrameSerializer < ::ApplicationSerializer
    attributes :id,
               :key,
               :name,
               :name_key,
               :description,
               :access_mode,
               :enabled,
               :position,
               :image_url,
               :static_url,
               :image_upload_id,
               :static_upload_id,
               :scale,
               :offset_x,
               :offset_y,
               :calibration_confirmed,
               :grants_count,
               :minimum_activity_level_id,
               :minimum_activity_level

    def minimum_activity_level
      if object.minimum_activity_level_id.present? &&
           defined?(DiscourseAcademyRoles::ActivityLevels::Cosmetics)
        DiscourseAcademyRoles::ActivityLevels::Cosmetics.level_info(
          object.minimum_activity_level_id,
        )
      end
    end

    def image_url
      GlobalPath.upload_cdn_path(object.image_url)
    end

    def static_url
      GlobalPath.upload_cdn_path(object.static_url)
    end

    def grants_count
      @options[:counts].fetch(object.id, 0)
    end

    def include_grants_count?
      @options.key?(:counts)
    end
  end
end
