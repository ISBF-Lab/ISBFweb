# frozen_string_literal: true

class CreateGuideTables < ActiveRecord::Migration[8.1]
  def change
    create_table :isbf_guides_guides do |table|
      table.string :slug, null: false
      table.bigint :draft_revision_id
      table.bigint :published_revision_id
      table.datetime :first_published_at
      table.integer :lock_version, null: false, default: 0
      table.timestamps
    end
    add_index :isbf_guides_guides, :slug, unique: true

    create_table :isbf_guides_revisions do |table|
      table.bigint :guide_id, null: false
      table.bigint :editor_id, null: false
      table.string :title, null: false
      table.string :summary, null: false, default: ""
      table.text :raw, null: false
      table.text :cooked, null: false
      table.jsonb :toc, null: false, default: []
      table.jsonb :image_ids, null: false, default: []
      table.jsonb :anchors, null: false, default: {}
      table.string :content_digest, null: false
      table.datetime :published_at
      table.timestamps
    end
    add_index :isbf_guides_revisions, :guide_id

    create_table :isbf_guides_images do |table|
      table.bigint :guide_id, null: false
      table.bigint :creator_id, null: false
      table.string :filename, null: false
      table.string :content_type, null: false
      table.string :sha256, null: false
      table.integer :width, null: false
      table.integer :height, null: false
      table.binary :data, null: false
      table.timestamps
    end
    add_index :isbf_guides_images, %i[guide_id filename], unique: true
  end
end
