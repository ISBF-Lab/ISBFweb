# frozen_string_literal: true

class ReviewableIsbfLibraryDirectorySerializer < ReviewableSerializer
  payload_attributes :kind, :name, :category_id, :directory_id
end
