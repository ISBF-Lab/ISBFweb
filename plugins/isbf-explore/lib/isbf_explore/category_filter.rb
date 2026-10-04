# frozen_string_literal: true

module IsbfExplore
  class CategoryFilter
    MAX_ID = 2_147_483_647

    def self.apply(scope, filter_values, guardian)
      return scope.none unless filter_values.is_a?(Array) && filter_values.length == 1

      value = filter_values.first
      return scope.none unless value.is_a?(String) && value.match?(/\A[1-9][0-9]{0,9}\z/)

      category_id = value.to_i
      return scope.none if category_id > MAX_ID
      return scope.none unless Category.secured(guardian).exists?(id: category_id)

      scope.where(category_id: category_id)
    end
  end
end
