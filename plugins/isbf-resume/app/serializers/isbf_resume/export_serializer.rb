# frozen_string_literal: true

module IsbfResume
  class ExportSerializer < ::ApplicationSerializer
    attributes :id,
               :pages,
               :template,
               :expires_at,
               :docx_url,
               :pdf_url,
               :preview_urls

    def docx_url
      "#{Discourse.base_path}/isbf-resume/exports/#{object.id}/docx"
    end

    def pdf_url
      "#{Discourse.base_path}/isbf-resume/exports/#{object.id}/pdf"
    end

    def preview_urls
      (1..object.preview_count).map do |page|
        "#{Discourse.base_path}/isbf-resume/exports/#{object.id}/previews/#{page}"
      end
    end
  end
end
