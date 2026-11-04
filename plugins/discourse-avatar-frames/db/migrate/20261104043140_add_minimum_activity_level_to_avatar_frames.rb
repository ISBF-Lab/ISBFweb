# frozen_string_literal: true

class AddMinimumActivityLevelToAvatarFrames < ActiveRecord::Migration[8.0]
  def change
    add_column :discourse_avatar_frames_frames, :minimum_activity_level_id, :string, limit: 64
  end
end
