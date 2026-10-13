# frozen_string_literal: true

DiscourseAvatarFrames::BUILTINS.each_with_index do |(key, name), position|
  next if DiscourseAvatarFrames::Frame.exists?(key:)

  title =
    SiteSetting
      .avatar_frames_config
      .to_s
      .split("|")
      .filter_map do |entry|
        frame_key, frame_name = entry.split(":", 3)
        frame_name if frame_key == key
      end
      .first
  DiscourseAvatarFrames::Frame.create!(
    key:,
    builtin: key,
    name: title.presence || name,
    access_mode: "public",
    position:,
  )
end
