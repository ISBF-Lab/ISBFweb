# frozen_string_literal: true

module IsbfResume
  class SharedResumeSerializer < ApplicationSerializer
    attributes :id,
               :title,
               :description,
               :industry,
               :position,
               :salary,
               :experience,
               :status,
               :uploader_name,
               :uploader_username,
               :pages,
               :file_bytes,
               :created_at,
               :reviewed_at,
               :pdf_url,
               :preview_urls

    def pdf_url
      "/isbf-resume/shares/#{object.id}/pdf"
    end

    def preview_urls
      (1..object.pages).map { |page| "/isbf-resume/shares/#{object.id}/previews/#{page}" }
    end
  end
end
