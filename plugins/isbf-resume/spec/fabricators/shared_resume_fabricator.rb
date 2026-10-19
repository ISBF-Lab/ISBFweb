# frozen_string_literal: true

Fabricator(:shared_isbf_resume, class_name: "IsbfResume::SharedResume") do
  user
  storage_key { SecureRandom.uuid }
  file_sha256 { "a" * 64 }
  file_bytes 512
  pages 1
  download_url "https://www.kdocs.cn/l/resume-example"
  status "pending"
  title { sequence(:shared_resume_title) { |number| "Shared resume #{number}" } }
  submitted_description "Uploader's original description"
  description ""
  uploader_name { |attributes| attributes[:user].name.presence || attributes[:user].username }
  uploader_username { |attributes| attributes[:user].username }
end

Fabricator(:approved_shared_isbf_resume, from: :shared_isbf_resume) do
  status "approved"
  description "Reviewed resume description"
  reviewed_at { Time.now.utc }
end

Fabricator(:rejected_shared_isbf_resume, from: :shared_isbf_resume) do
  status "rejected"
  description ""
  reviewed_at { Time.now.utc }
end
