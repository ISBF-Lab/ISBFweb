# frozen_string_literal: true

module ::IsbfJoin
  class ApplicationSerializer < ::ApplicationSerializer
    attributes :id, :name, :student_id, :phone, :created_at
  end
end
