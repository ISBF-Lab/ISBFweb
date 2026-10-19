# frozen_string_literal: true

module IsbfResume
  class ContributorSerializer < ApplicationSerializer
    attributes :id, :username, :name, :avatar_template
  end
end
