# frozen_string_literal: true
class AddAvatarFrameCalibration < ActiveRecord::Migration[8.1]
  def change
    add_column :discourse_avatar_frames_frames, :scale, :float, null: false, default: 120
    add_column :discourse_avatar_frames_frames, :offset_x, :float, null: false, default: 0
    add_column :discourse_avatar_frames_frames, :offset_y, :float, null: false, default: 0
    add_column :discourse_avatar_frames_frames,
               :calibration_confirmed,
               :boolean,
               null: false,
               default: true
    change_column_default :discourse_avatar_frames_frames,
                          :calibration_confirmed,
                          from: true,
                          to: false
  end
end
