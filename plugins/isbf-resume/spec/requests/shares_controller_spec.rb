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
        "pdf_url" => approved.download_url,
        "preview_urls" => ["/isbf-resume/shares/#{approved.id}/previews/1"],
      )
      expect(payload).to include(
        "page" => 1,
        "can_load_more" => false,
        "can_submit" => false,
        "can_review" => false,
        "can_manage_collection" => false,
        "collection_url" => SiteSetting.isbf_resume_collection_url,
      )
      expect(payload.fetch("shares").sole.keys).not_to include(
        "reviews",
        "review_ids",
        "submitted_description",
        "storage_key",
        "file_sha256",
        "student_number",
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
      associated =
        Fabricate(
          :shared_isbf_resume,
          user: developer,
          contributor_user_id: owner.id,
          student_number: "20261019",
        )
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
      ).to contain_exactly(pending.id, rejected.id, associated.id)
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

    it "shows staff submission and collection controls independently of review permission" do
      sign_in(administrator)

      get "/isbf-resume/shares.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "can_submit" => true,
        "can_manage_collection" => true,
        "can_review" => false,
        "collection_url" => SiteSetting.isbf_resume_collection_url,
      )
    end
  end

  describe "#update_collection" do
    it "lets staff update the WPS collection link and records the acting staff member" do
      [developer, administrator].each do |staff|
        sign_in(staff)
        url = "https://f.wps.cn/g/resume-#{staff.id}"

        expect do put "/isbf-resume/collection.json", params: { url: url } end.to change(
          UserHistory,
          :count,
        ).by(1)

        expect(response.status).to eq(200)
        expect(response.parsed_body).to include("collection_url" => url)
        expect(SiteSetting.isbf_resume_collection_url).to eq(url)
        expect(UserHistory.order(:id).last.acting_user_id).to eq(staff.id)
      end
    end

    it "denies visitors and ordinary members without changing the collection link" do
      [nil, member].each do |viewer|
        sign_in(viewer) if viewer

        expect do
          put "/isbf-resume/collection.json", params: { url: "https://f.wps.cn/g/forbidden" }
        end.not_to change { [SiteSetting.isbf_resume_collection_url, UserHistory.count] }

        expect(response.status).to eq(403)
      end
    end

    it "rejects insecure, unrelated and deceptive collection links" do
      sign_in(developer)

      %w[
        http://f.wps.cn/g/insecure
        https://example.com/g/unrelated
        https://f.wps.cn.example.com/g/deceptive
        https://user:password@f.wps.cn/g/credentials
        https://f.wps.cn/unrelated-path
      ].each do |url|
        expect do put "/isbf-resume/collection.json", params: { url: url } end.not_to change {
          [SiteSetting.isbf_resume_collection_url, UserHistory.count]
        }

        expect(response.status).to eq(400)
      end
    end
  end

  describe "#contributor_users" do
    it "returns only the exact registered student's public user fields to staff" do
      registration = Fabricate(:registered_academy_student, user: owner)
      sign_in(administrator)

      get "/isbf-resume/contributor-users.json",
          params: {
            student_number: registration.student_number,
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("users")).to contain_exactly(
        {
          "id" => owner.id,
          "username" => owner.username,
          "name" => owner.name,
          "avatar_template" => owner.avatar_template,
        },
      )
      expect(response.body).not_to include(registration.student_number)

      get "/isbf-resume/contributor-users.json",
          params: {
            student_number: registration.student_number[0...-1],
          }
      expect(response.parsed_body.fetch("users")).to be_empty
    end

    it "excludes unclaimed registrations and staged users" do
      unclaimed = Fabricate(:academy_student_registration)
      staged = Fabricate(:registered_academy_student, user: Fabricate(:user, staged: true))
      sign_in(developer)

      [unclaimed, staged].each do |registration|
        get "/isbf-resume/contributor-users.json",
            params: {
              student_number: registration.student_number,
            }

        expect(response.status).to eq(200)
        expect(response.parsed_body.fetch("users")).to be_empty
      end
    end

    it "denies visitors and ordinary members access to student-number searches" do
      registration = Fabricate(:registered_academy_student, user: owner)
      [nil, member].each do |viewer|
        sign_in(viewer) if viewer

        get "/isbf-resume/contributor-users.json",
            params: {
              student_number: registration.student_number,
            }

        expect(response.status).to eq(403)
        expect(response.body).not_to include(registration.student_number, owner.username)
      end
    end
  end

  describe "#show" do
    it "returns approved details to forum members without private review identity" do
      approved.update!(
        contributor: "Resume contributor",
        contributor_user_id: owner.id,
        student_number: "20261019",
      )
      Fabricate(:isbf_resume_share_review, shared_resume: approved, reviewer: developer)
      sign_in(member)

      get "/isbf-resume/shares/#{approved.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "id" => approved.id,
        "description" => approved.description,
        "contributor" => approved.contributor,
        "contributor_user" =>
          include(
            "id" => owner.id,
            "username" => owner.username,
            "name" => owner.name,
            "avatar_template" => owner.avatar_template,
          ),
      )
      expect(response.parsed_body.keys).not_to include(
        "reviews",
        "review_ids",
        "submitted_description",
        "lock_version",
        "storage_key",
        "student_number",
      )
      expect(response.body).not_to include(approved.student_number)
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
    it "accepts an administrator's PDF and WPS link with blank optional contributor details" do
      sign_in(developer)
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
        download_url: "https://www.kdocs.cn/l/portfolio",
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
        "download_url" => details[:download_url],
        "contributor" => nil,
        "contributor_user" => nil,
      )
      expect(payload.keys).not_to include("storage_key", "file_sha256")
      expect(payload.fetch("reviews")).to be_empty
      created_submission = IsbfResume::SharedResume.find(payload.fetch("id"))
      expect(created_submission.user_id).to eq(developer.id)
      expect(created_submission.reviewable).to have_attributes(
        status: "pending",
        created_by_id: developer.id,
      )
      expect(created_submission.pdf.available_path).to eq(nil)
      expect(File.binread(created_submission.pdf.preview_path(1), 8)).to eq(
        IsbfResume::SharedPdf::PNG_SIGNATURE,
      )
    end

    it "requires authentication before storing an upload" do
      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               file: sharing_request_upload,
               consent: "true",
               download_url: "https://www.kdocs.cn/l/portfolio",
             },
           }

      expect(response.status).to eq(403)
      expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
    end

    it "returns a contract error for absent consent and an upload error for invalid PDF content" do
      sign_in(developer)
      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               file: sharing_request_upload,
               consent: "false",
               download_url: "https://www.kdocs.cn/l/portfolio",
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
               download_url: "https://www.kdocs.cn/l/portfolio",
             },
           }

      expect(response.status).to eq(422)
      expect(response.parsed_body.keys).to contain_exactly("errors")
      expect(response.body).not_to include(IsbfResume::SharedPdf.storage_path)
      expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
    end

    it "uses the signed-in uploader instead of identity supplied in the request" do
      sign_in(developer)

      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               file: sharing_request_upload,
               consent: "true",
               download_url: "https://www.kdocs.cn/l/portfolio",
               user_id: member.id,
               uploader_name: member.name,
               uploader_username: member.username,
               status: "approved",
             },
           }

      expect(response.status).to eq(201)
      shared_resume = IsbfResume::SharedResume.find(response.parsed_body.fetch("id"))
      expect(shared_resume).to have_attributes(
        user_id: developer.id,
        uploader_name: developer.name.presence || developer.username,
        uploader_username: developer.username,
        status: "pending",
      )
    end

    it "denies an ordinary member's direct upload without creating files or review entries" do
      sign_in(member)

      expect do
        post "/isbf-resume/shares.json",
             params: {
               shared_resume: {
                 file: sharing_request_upload,
                 consent: "true",
                 download_url: "https://www.kdocs.cn/l/forbidden",
               },
             }
      end.not_to change { [IsbfResume::SharedResume.count, ReviewableIsbfResume.count] }

      expect(response.status).to eq(403)
      expect(Dir.children(IsbfResume::SharedPdf.storage_path)).to be_empty
    end

    it "lets administrators submit images while their resume review switch is disabled" do
      sign_in(administrator)

      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               preview_images: [sharing_request_image_upload],
               title: "Image preview",
               consent: "true",
               download_url: "https://www.kdocs.cn/l/image-preview",
               contributor: "Named contributor",
             },
           }

      expect(response.status).to eq(201)
      expect(response.parsed_body).to include(
        "pages" => 1,
        "contributor" => "Named contributor",
        "contributor_user" => nil,
      )
      created_submission = IsbfResume::SharedResume.find(response.parsed_body.fetch("id"))
      expect(created_submission.user_id).to eq(administrator.id)
      expect(created_submission.pdf.available_path).to eq(nil)
      expect(administrator.guardian.can_review_isbf_resumes?).to eq(false)
    end

    it "associates a selected registered contributor while preserving the staff uploader" do
      registration = Fabricate(:registered_academy_student, user: owner)
      sign_in(developer)

      post "/isbf-resume/shares.json",
           params: {
             shared_resume: {
               preview_images: [sharing_request_image_upload],
               title: "Student contribution",
               consent: "true",
               download_url: "https://www.kdocs.cn/l/student-contribution",
               contributor: "Graduate contributor",
               student_number: registration.student_number,
               contributor_user_id: owner.id,
             },
           }

      expect(response.status).to eq(201)
      payload = response.parsed_body
      expect(payload).to include(
        "student_number" => registration.student_number,
        "contributor" => "Graduate contributor",
        "contributor_user" => include("id" => owner.id),
      )
      shared_resume = IsbfResume::SharedResume.find(payload.fetch("id"))
      expect(shared_resume).to have_attributes(
        user_id: developer.id,
        contributor_user_id: owner.id,
        student_number: registration.student_number,
      )
      sign_in(owner)
      get "/isbf-resume/shares.json", params: { list: "mine" }
      expect(response.parsed_body.fetch("shares").map { |entry| entry.fetch("id") }).to include(
        shared_resume.id,
      )
    end

    it "rejects a forged contributor association without storing files or queue entries" do
      registration = Fabricate(:registered_academy_student, user: owner)
      sign_in(developer)

      expect do
        post "/isbf-resume/shares.json",
             params: {
               shared_resume: {
                 preview_images: [sharing_request_image_upload],
                 consent: "true",
                 download_url: "https://www.kdocs.cn/l/forged-contributor",
                 student_number: registration.student_number,
                 contributor_user_id: member.id,
               },
             }
      end.not_to change { [IsbfResume::SharedResume.count, ReviewableIsbfResume.count] }

      expect(response.status).to eq(422)
      expect(Dir.glob(File.join(IsbfResume::SharedPdf.storage_path, "*"))).to be_empty
    end

    it "rejects a missing download link and simultaneous PDF and image sources" do
      sign_in(developer)
      image = sharing_request_image_upload

      expect do
        post "/isbf-resume/shares.json",
             params: {
               shared_resume: {
                 preview_images: [image],
                 consent: "true",
               },
             }
      end.not_to change { [IsbfResume::SharedResume.count, ReviewableIsbfResume.count] }
      expect(response.status).to eq(400)

      expect do
        post "/isbf-resume/shares.json",
             params: {
               shared_resume: {
                 file: sharing_request_upload,
                 preview_images: [image],
                 consent: "true",
                 download_url: "https://www.kdocs.cn/l/mixed-sources",
               },
             }
      end.not_to change { [IsbfResume::SharedResume.count, ReviewableIsbfResume.count] }
      expect(response.status).to eq(422)
      expect(Dir.glob(File.join(IsbfResume::SharedPdf.storage_path, "*"))).to be_empty
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
    it "redirects forum members to the WPS document instead of serving the historical PDF" do
      materialize_shared_pdf(approved)
      original_pdf = File.binread(approved.pdf.available_path)
      sign_in(member)

      get "/isbf-resume/shares/#{approved.id}/pdf"

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq(approved.download_url)
      expect(response.media_type).not_to eq("application/pdf")
      expect(response.body.b).not_to eq(original_pdf)
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      expect(File.binread(approved.pdf.available_path)).to eq(original_pdf)
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

    it "redirects the owner and authorized reviewers to a private submission's WPS link" do
      materialize_shared_pdf(pending)
      SiteSetting.academy_moderators_review_resumes = true
      [owner, developer, administrator].each do |viewer|
        sign_in(viewer)
        get "/isbf-resume/shares/#{pending.id}/pdf"
        expect(response.status).to eq(302)
        expect(response.headers["Location"]).to eq(pending.download_url)
      end
    end

    it "requires authentication and keeps historical PDFs without links inaccessible" do
      materialize_shared_pdf(approved)
      approved.update!(download_url: "")
      get "/isbf-resume/shares/#{approved.id}/pdf"
      expect(response.status).to eq(403)
      sign_in(member)
      get "/isbf-resume/shares/#{approved.id}/pdf"
      expect(response.status).to eq(404)
      expect(File.binread(approved.pdf.available_path, 5)).to eq("%PDF-")
      get "/isbf-resume/shares/#{approved.id}.json"
      expect(response.parsed_body.fetch("pdf_url")).to eq(nil)
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
          expect(shared_resume.pdf.preview_path(1)).to eq(nil)
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

    it "returns a retryable response if preview processing is unavailable without losing the PDF" do
      materialize_shared_pdf(approved)
      sign_in(member)

      with_sharing_environment("ISBF_RESUME_PYTHON" => "/missing-preview-python") do
        get "/isbf-resume/shares/#{approved.id}/previews/1"
      end

      expect(response.status).to eq(503)
      expect(response.headers["Retry-After"]).to eq("5")
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      get "/isbf-resume/shares/#{approved.id}/pdf"
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq(approved.download_url)
      expect(File.binread(approved.pdf.available_path, 5)).to eq("%PDF-")
    end

    it "exposes only three pages for historical documents with more pages" do
      pdf = IsbfResume::SharedPdf.store(sharing_pdf_upload(pages: 58))
      approved.update!(storage_key: pdf.key, pages: pdf.pages)
      sign_in(member)

      get "/isbf-resume/shares/#{approved.id}.json"

      expect(response.parsed_body).to include(
        "pages" => 3,
        "preview_urls" =>
          (1..3).map { |page| "/isbf-resume/shares/#{approved.id}/previews/#{page}" },
      )
      get "/isbf-resume/shares/#{approved.id}/previews/3"
      expect(response.status).to eq(200)
      %w[4 58].each do |page|
        get "/isbf-resume/shares/#{approved.id}/previews/#{page}"
        expect(response.status).to eq(404)
      end
      expect(Dir.children(pdf.directory)).to contain_exactly("resume.pdf", "preview-3.png")
      expect(approved.reload.pages).to eq(58)
    end

    it "serves cached previews after the uploaded PDF has been discarded" do
      materialize_shared_preview(approved)
      sign_in(member)

      get "/isbf-resume/shares/#{approved.id}/previews/1"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("image/png")
      expect(response.body.b).to eq(File.binread(approved.pdf.preview_path(1)))
      expect(approved.pdf.available_path).to eq(nil)
    end
  end
end
