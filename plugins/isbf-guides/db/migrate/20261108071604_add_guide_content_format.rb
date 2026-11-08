# frozen_string_literal: true
class AddGuideContentFormat < ActiveRecord::Migration[8.1]
  def change
    add_column :isbf_guides_revisions, :content_format, :string, null: false, default: "markdown"
  end
end
