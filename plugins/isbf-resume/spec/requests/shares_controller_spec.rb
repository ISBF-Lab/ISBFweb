# frozen_string_literal: true

require_relative "../support/isbf_resume_sharing_helpers"

RSpec.describe IsbfResume::SharesController do
  include_context "with private shared resume storage"
  include_context "with resume review permissions"

  fab!(:owner, :user)
  fab!(:member, :user)
  fab!(:developer, :admin)
  fab!(:administrator, :moderator)
  fab!(:pending) { Fabricate(:shared_isbf_resume, user: owner) }
  fab!(:rejected) { Fabricate(:rejected_shared_isbf_resume, user: owner) }
  fab!(:approved, :approved_shared_isbf_resume)

  describe "#index" do
    it "requires authentication for every list" do
      %w[published mine review].each do |list|
        get "/isbf-resume/shares.json", params: { list: list }
        expect(response.status).to eq(403)
      end
    end

    it "lists approved resumes with public descriptions and excludes private file and audit metadata" do
      review = Fabricate(:isbf_resume_share_review, shared_resume: approved, reviewer: developer)
      sign_in(member)

      get "/isbf-resume/shares.json"

      expect(response.status).to eq(200)
      payload = response.parsed_body
      expect(payload.fetch("shares").map { |share| share.fetch("id") }).to eq([approved.id])
      expect(payload.fetch("shares").sole).to include(
        "title" => approved.title,
        "description" => approved.description,
        "pdf_url" => "/isbf-resume/shares/#{approved.id}/pdf",
        "preview_urls" => ["/isbf-resume/shares/#{approved.id}/previews/1"],
      )
      expect(payload).to include(
        "page" => 1,
        "can_load_more" => false,
        "can_submit" => true,
        "can_review" => false,
      )
      expect(payload.fetch("shares").sole.keys).not_to include(
        "reviews",
        "review_ids",
        "submitted_description",
        "storage_key",
        "file_sha256",
      )
      expect(response.body).not_to include(pending.title, rejected.title, review.reviewer_username)
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
    end

    it "paginates the published list without mixing in private submissions" do
      freeze_time
      approved.update!(reviewed_at: Time.now.utc)
      later_resumes = Fabricate.times(20, :approved_shared_isbf_resume, reviewed_at: Time.now.utc)
      expected_ids = (later_resumes.map(&:id) + [approved.id]).sort.reverse
      sign_in(member)

      get "/isbf-resume/shares.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("shares").map { |share| share.fetch("id") }).to eq(
        expected_ids.first(20),
      )
      expect(response.parsed_body.fetch("can_load_more")).to eq(true)
      get "/isbf-resume/shares.json", params: { page: 2 }
      expect(response.parsed_body.fetch("shares").map { |share| share.fetch("id") }).to eq(
        expected_ids.drop(20),
      )
      expect(response.parsed_body).to include("page" => 2, "can_load_more" => false)
    end

    it "limits the owner's list to their own submissions without exposing administrator history" do
      Fabricate(
        :isbf_resume_share_review,
        shared_resume: rejected,
        reviewer: developer,
        decision: "reject",
        description: "",
      )
      sign_in(owner)

      get "/isbf-resume/shares.json", params: { list: "mine" }

      expect(response.status).to eq(200)
      expect(
        response.parsed_body.fetch("shares").map { |share| share.fetch("id") },
      ).to contain_exactly(pending.id, rejected.id)
      expect(response.parsed_body.fetch("shares").map(&:keys).flatten).not_to include(
        "reviews",
        "review_ids",
      )
    end

    it "filters each review state for a developer and rejects unknown list parameters" do
      sign_in(developer)

      {
        "pending" => pending,
        "approved" => approved,
        "rejected" => rejected,
      }.each do |status, shared_resume|
        get "/isbf-resume/shares.json", params: { list: "review", status: status }
        expect(response.status).to eq(200)
        expect(response.parsed_body.fetch("shares").map { |share| share.fetch("id") }).to eq(
          [shared_resume.id],
        )
      end
      [
        { list: "all" },
        { list: "review", status: "unknown" },
        { page: "0" },
        { page: "01" },
        { page: "1001" },
      ].each do |parameters|
        get "/isbf-resume/shares.json", params: parameters
        expect(response.status).to eq(400)
      end
    end

    it "requires the dedicated resume capability and revokes queue access in the same session" do
      SiteSetting.academy_moderators_review_content = true
      sign_in(administrator)

      get "/isbf-resume/shares.json", params: { list: "review" }
      expect(response.status).to eq(403)
      SiteSetting.academy_moderators_review_resumes = true
      get "/isbf-resume/shares.json", params: { list: "review" }
      expect(response.status).to eq(200)
      SiteSetting.academy_moderators_review_resumes = false
      get "/isbf-resume/shares.json", params: { list: "review" }
      expect(response.status).to eq(403)
    end
  end

  describe "#show" do
    it "returns approved details to forum members without private review identity" do
      Fabricate(:isbf_resume_share_review, shared_resume: approved, reviewer: developer)
      sign_in(member)

      get "/isbf-resume/shares/#{approved.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "id" => approved.id,
        "description" => approved.description,
      )
      expect(response.parsed_body.keys).not_to include(
        "reviews",
        "review_ids",
        "submitted_description",
        "lock_version",
        "storage_key",
      )
    end

    it "hides pending and rejected metadata from ordinary members and unauthorized administrators" do
      [member, administrator].each do |viewer|
        sign_in(viewer)
        [pending, rejected].each do |shared_resume|
          get "/isbf-resume/shares/#{shared_resume.id}.json"
          expect(response.status).to eq(404)
          expect(response.body).not_to include(
            shared_resume.title,
            shared_resume.submitted_description,
            shared_resume.storage_key,
          )
        end
      end
    end

    it "lets the owner inspect their status while limiting audit history to authorized reviewers" do
      review =
        Fabricate(
          :isbf_resume_share_review,
          shared_resume: rejected,
          reviewer: developer,
          decision: "reject",
          description: "",
        )
      sign_in(owner)

      get "/isbf-resume/shares/#{rejected.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "status" => "rejected",
        "submitted_description" => rejected.submitted_description,
      )
      expect(response.parsed_body).not_to have_key("reviews")
      expect(response.parsed_body).not_to have_key("review_ids")
      sign_in(developer)
      get "/isbf-resume/shares/#{rejected.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body).to have_key("reviews"), response.parsed_body.inspect
      expect(response.parsed_body.fetch("reviews").sole).to include(
        "reviewer_id" => developer.id,
        "reviewer_name" => review.reviewer_name,
        "reviewer_username" => review.reviewer_username,
        "original_description" => rejected.submitted_description,
      )
    end

    it "requires authentication and hides disabled sharing" do
      get "/isbf-resume/shares/#{approved.id}.json"
      expect(response.status).to eq(403)
      sign_in(member)
      SiteSetting.isbf_resume_enabled = false
      get "/isbf-resume/shares/#{approved.id}.json"
      expect(response.status).to eq(404)
    end
  end

  describe "#create" do
    it "accepts a real PDF with blank optional metadata and explicit free-sharing consent" do
      sign_in(owner)
      upload = sharing_request_upload(filename: "Portfolio.pdf")
      details = {
        file: upload,
        consent: "true",
        title: "",
        description: "",
        salary: "",
        industry: "",
        position: "",
        experience: "",
      }

      expect do post "/isbf-resume/shares.json", params: { shared_resume: details } end.to change(
        IsbfResume::SharedResume,
        :count,
      ).by(1).and change(ReviewableIsbfResume, :count).by(1)

      expect(response.status).to eq(201)
      payload = response.parsed_body
      expect(payload).to include(
        "title" => "Portfolio",
        "status" => "pending",
        "description" => "",
        "submitted_description" => "",
      )
      expect(payload.keys).not_to include("storage_key", "file_sha256", "reviews")
      created_submission = IsbfResume::SharedResume.find(payload.fetch("id"))
      expect(created_submission.user_id).to eq(owner.id)
      expect(created_submission.reviewable).to have_attributes(
        status: "pending",
        created_by_id: owner.id,
      )
    end

    it "requires authentication before storing an upload" do
      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               file: sharing_request_upload,
               consent: "true",
             },
           }

      expect(response.status).to eq(403)
      expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
    end

    it "returns a contract error for absent consent and an upload error for invalid PDF content" do
      sign_in(owner)
      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               file: sharing_request_upload,
               consent: "false",
             },
           }
      expect(response.status).to eq(400)
      invalid = sharing_raw_upload(content: "not a PDF")
      invalid_request = Rack::Test::UploadedFile.new(invalid.path, "application/pdf", true)

      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               file: invalid_request,
               consent: "true",
             },
           }

      expect(response.status).to eq(422)
      expect(response.parsed_body.keys).to contain_exactly("errors")
      expect(response.body).not_to include(IsbfResume::SharedPdf.storage_path)
      expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
    end

    it "uses the signed-in uploader instead of identity supplied in the request" do
      sign_in(owner)

      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               file: sharing_request_upload,
               consent: "true",
               user_id: member.id,
               uploader_name: member.name,
               uploader_username: member.username,
               status: "approved",
             },
           }

      expect(response.status).to eq(201)
      shared_resume = IsbfResume::SharedResume.find(response.parsed_body.fetch("id"))
      expect(shared_resume).to have_attributes(
        user_id: owner.id,
        uploader_name: owner.name.presence || owner.username,
        uploader_username: owner.username,
        status: "pending",
      )
    end
  end

  describe "#review" do
    let(:details) do
      {
        decision: "approve",
        description: "Administrator's description",
        expected_version: pending.lock_version,
      }
    end

    it "allows developers to approve, revise descriptions and record their server identity" do
      sign_in(developer)
      original_name = developer.name.presence || developer.username
      original_username = developer.username

      post "/isbf-resume/shares/#{pending.id}/review.json",
           params: {
             share_review:
               details.merge(
                 reviewer_id: member.id,
                 reviewer_name: "Spoofed name",
                 reviewer_username: member.username,
               ),
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "description" => details[:description],
        "status" => "approved",
        "can_review" => false,
      )
      expect(pending.reload.reviews.sole).to have_attributes(
        reviewer_id: developer.id,
        reviewer_name: original_name,
        reviewer_username: original_username,
        original_description: pending.submitted_description,
        description: details[:description],
      )
      expect(pending.reviewable).to be_approved
      developer.update!(name: "Renamed developer", username: "renamed_http_user")
      get "/isbf-resume/shares/#{pending.id}.json"
      expect(response.parsed_body.fetch("reviews").sole).to include(
        "reviewer_name" => original_name,
        "reviewer_username" => original_username,
      )
    end

    it "requires a brief approval description for a submission with no uploader description" do
      pending.update!(submitted_description: "")
      sign_in(developer)

      post "/isbf-resume/shares/#{pending.id}/review.json",
           params: {
             share_review: details.merge(description: " "),
           }

      expect(response.status).to eq(400)
      expect(pending.reload).to be_pending
      expect(pending.reviews).to be_empty
    end

    it "requires the resume capability and applies immediate revocation to administrators" do
      SiteSetting.academy_moderators_review_content = true
      sign_in(administrator)
      post "/isbf-resume/shares/#{pending.id}/review.json", params: { share_review: details }
      expect(response.status).to eq(403)
      SiteSetting.academy_moderators_review_resumes = true
      get "/isbf-resume/shares/#{pending.id}.json"
      expect(response.status).to eq(200)
      SiteSetting.academy_moderators_review_resumes = false
      post "/isbf-resume/shares/#{pending.id}/review.json", params: { share_review: details }

      expect(response.status).to eq(403)
      expect(pending.reload).to be_pending
      expect(pending.reviews).to be_empty
    end

    it "allows administrators with the dedicated switch to approve" do
      SiteSetting.academy_moderators_review_resumes = true
      sign_in(administrator)

      post "/isbf-resume/shares/#{pending.id}/review.json", params: { share_review: details }

      expect(response.status).to eq(200)
      expect(pending.reload).to be_approved
      expect(pending.reviews.sole.reviewer_id).to eq(administrator.id)
    end

    it "records rejection without publishing or requiring a public description" do
      sign_in(developer)

      post "/isbf-resume/shares/#{pending.id}/review.json",
           params: {
             share_review: details.merge(decision: "reject", description: ""),
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("status" => "rejected", "description" => "")
      expect(pending.reviewable).to be_rejected
      sign_in(member)
      get "/isbf-resume/shares/#{pending.id}.json"
      expect(response.status).to eq(404)
    end

    it "returns conflicts for stale and repeated reviews while preserving the first decision" do
      sign_in(developer)
      native_version = pending.reviewable.version
      post "/isbf-resume/shares/#{pending.id}/review.json",
           params: {
             share_review: details.merge(expected_version: pending.lock_version + 1),
           }
      expect(response.status).to eq(409)
      expect(pending.reviews).to be_empty
      expect(pending.reviewable).to have_attributes(status: "pending", version: native_version)
      post "/isbf-resume/shares/#{pending.id}/review.json", params: { share_review: details }
      expect(response.status).to eq(200)
      post "/isbf-resume/shares/#{pending.id}/review.json",
           params: {
             share_review: details.merge(decision: "reject"),
           }

      expect(response.status).to eq(409)
      expect(pending.reload).to be_approved
      expect(pending.reviewable).to be_approved
      expect(pending.reviews.count).to eq(1)
    end

    it "returns a missing-resource status for an unknown submission" do
      sign_in(developer)

      post "/isbf-resume/shares/#{IsbfResume::SharedResume.maximum(:id) + 1}/review.json",
           params: {
             share_review: details,
           }

      expect(response.status).to eq(404)
    end
  end

  describe "#download" do
    it "serves approved PDF bytes to every forum member with private cache headers" do
      materialize_shared_pdf(approved)
      sign_in(member)

      get "/isbf-resume/shares/#{approved.id}/pdf"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("application/pdf")
      expect(response.body.b).to eq(File.binread(approved.pdf.available_path))
      expect(response.headers["Content-Disposition"]).to include(
        "attachment",
        "resume-#{approved.id}.pdf",
      )
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    end

    it "hides pending and rejected PDF bytes from ordinary members and unauthorized administrators" do
      [pending, rejected].each { |shared_resume| materialize_shared_pdf(shared_resume) }
      [member, administrator].each do |viewer|
        sign_in(viewer)
        [pending, rejected].each do |shared_resume|
          get "/isbf-resume/shares/#{shared_resume.id}/pdf"
          expect(response.status).to eq(404)
          expect(response.media_type).not_to eq("application/pdf")
          expect(response.body.b).not_to eq(File.binread(shared_resume.pdf.available_path))
        end
      end
    end

    it "lets the owner and authorized reviewers inspect private PDF bytes" do
      materialize_shared_pdf(pending)
      SiteSetting.academy_moderators_review_resumes = true
      [owner, developer, administrator].each do |viewer|
        sign_in(viewer)
        get "/isbf-resume/shares/#{pending.id}/pdf"
        expect(response.status).to eq(200)
        expect(response.body.b).to eq(File.binread(pending.pdf.available_path))
      end
    end

    it "requires authentication and handles a missing document safely" do
      get "/isbf-resume/shares/#{approved.id}/pdf"
      expect(response.status).to eq(403)
      sign_in(member)
      get "/isbf-resume/shares/#{approved.id}/pdf"
      expect(response.status).to eq(404)
    end
  end

  describe "#preview" do
    it "serves approved preview images to forum members and rejects invalid page identifiers" do
      materialize_shared_pdf(approved)
      sign_in(member)

      get "/isbf-resume/shares/#{approved.id}/previews/1"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("image/png")
      expect(response.body.b).to eq(File.binread(approved.pdf.preview_path(1)))
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
      %w[0 2 -1 01 1.0 invalid %2e%2e].each do |page|
        get "/isbf-resume/shares/#{approved.id}/previews/#{page}"
        expect(response.status).to eq(404)
      end
    end

    it "hides pending and rejected preview images from unauthorized viewers" do
      [pending, rejected].each { |shared_resume| materialize_shared_pdf(shared_resume) }
      [member, administrator].each do |viewer|
        sign_in(viewer)
        [pending, rejected].each do |shared_resume|
          get "/isbf-resume/shares/#{shared_resume.id}/previews/1"
          expect(response.status).to eq(404)
          expect(response.media_type).not_to eq("image/png")
          expect(response.body.b).not_to eq(File.binread(shared_resume.pdf.preview_path(1)))
        end
      end
    end

    it "lets the owner and authorized reviewers inspect private previews" do
      materialize_shared_pdf(rejected)
      SiteSetting.academy_moderators_review_resumes = true
      [owner, developer, administrator].each do |viewer|
        sign_in(viewer)
        get "/isbf-resume/shares/#{rejected.id}/previews/1"
        expect(response.status).to eq(200)
        expect(response.body.b).to eq(File.binread(rejected.pdf.preview_path(1)))
      end
    end

    it "requires authentication before sending preview bytes" do
      get "/isbf-resume/shares/#{approved.id}/previews/1"

      expect(response.status).to eq(403)
    end
  end
end
