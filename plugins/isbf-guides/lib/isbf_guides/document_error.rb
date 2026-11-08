# frozen_string_literal: true

module ::IsbfGuides
  class DocumentError < StandardError
    attr_reader :key

    def initialize(key, **values)
      @key = key
      super(I18n.t("isbf_guides.errors.document_#{key}", **values))
    end
  end
end
