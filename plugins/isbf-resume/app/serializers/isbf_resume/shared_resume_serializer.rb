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
               :download_url,
               :contributor,
               :preview_urls

    has_one :contributor_user, serializer: ContributorSerializer, embed: :objects

    def pages
      object.preview_pages
    end

    def contributor
      object.contributor_label
    end

    def pdf_url
      object.download_url.presence
    end

    def preview_urls
      (1..object.preview_pages).map { |page| "/isbf-resume/shares/#{object.id}/previews/#{page}" }
    end
  end
end
