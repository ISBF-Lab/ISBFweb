# frozen_string_literal: true

require_relative "../support/isbf_resume_sharing_helpers"

RSpec.describe ReviewablesController do
  include_context "with resume review permissions"

  fab!(:developer, :admin)
  fab!(:administrator, :moderator)
  fab!(:owner, :user)
  fab!(:submission) { Fabricate(:shared_isbf_resume, user: owner) }

  let(:reviewable) { submission.reviewable }

  describe "#index and #show" do
    it "shows developers the native queue and linked resume with administrator review disabled" do
      sign_in(developer)

      get "/review.json", params: { type: "ReviewableIsbfResume" }

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("reviewables").map { |item| item.fetch("id") }).to eq(
        [reviewable.id],
      )
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(200)
      data = response.parsed_body.fetch("reviewable")
      expect(data).to include(
        "type" => "ReviewableIsbfResume",
        "can_edit" => false,
        "can_edit_resume" => true,
      )
      expect(data.fetch("payload")).to include(
        "title" => submission.title,
        "industry" => submission.industry,
        "description" => submission.submitted_description,
      )
      expect(data.fetch("shared_resume")).to include("id" => submission.id, "status" => "pending")
    end

    it "revokes list, details and old edit or decision requests in the same administrator session" do
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_review_resumes = true
      sign_in(administrator)
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(200)
      version = response.parsed_body.fetch("reviewable").fetch("version")
      SiteSetting.academy_moderators_review_resumes = false

      get "/review.json", params: { type: "ReviewableIsbfResume" }
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("reviewables")).to be_empty
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(404)
      put "/review/#{reviewable.id}.json",
          params: {
            version: version,
            reviewable: {
              payload: {
                description: "Old editor draft",
              },
            },
          }
      expect(response.status).to eq(404)
      put "/review/#{reviewable.id}/perform/approve_resume.json", params: { version: version }
      expect(response.status).to eq(404)
      expect(submission.reload).to be_pending
      expect(submission.reviews).to be_empty
      expect(reviewable.reload).to have_attributes(status: "pending", version: version)
    end

    it "denies ordinary uploaders access to the native list, details, editing and decisions" do
      sign_in(owner)
      SiteSetting.academy_moderators_review_resumes = true

      get "/review.json", params: { type: "ReviewableIsbfResume" }
      expect(response.status).to eq(403)
      get "/review/#{reviewable.id}.json"
      expect(response.status).to eq(403)
      put "/review/#{reviewable.id}.json",
          params: {
            version: reviewable.version,
            reviewable: {
              payload: {
                description: "Self approval",
              },
            },
          }
      expect(response.status).to eq(403)
      put "/review/#{reviewable.id}/perform/approve_resume.json",
          params: {
            version: reviewable.version,
          }
      expect(response.status).to eq(403)
      expect(submission.reload).to be_pending
      expect(submission.reviews).to be_empty
    end
  end

  describe "#update" do
    it "edits approved resumes from the approved queue while preserving approval and audit snapshots" do
      reviewable.perform(
        developer,
        :approve_resume,
        version: reviewable.version,
        description: "Approved summary",
      )
      approval = submission.reviews.sole
      approved_at = submission.reload.reviewed_at
      original_download_url = submission.download_url
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_review_resumes = true
      sign_in(administrator)

      get "/review.json", params: { type: "ReviewableIsbfResume", status: "approved" }
      expect(response.status).to eq(200)
      item =
        response
          .parsed_body
          .fetch("reviewables")
          .find { |entry| entry.fetch("id") == reviewable.id }
      expect(item).to include("can_edit_resume" => true)
      version = reviewable.reload.version
      registration = Fabricate(:registered_academy_student, user: owner)
      details = {
        title: "Updated public title",
        industry: "Finance",
        position: "Analyst",
        salary: "25k",
        experience: "5 years",
        description: "  Updated public summary  ",
        download_url: "https://www.kdocs.cn/l/revised-resume",
        contributor: "Reviewed contributor",
        student_number: registration.student_number,
        contributor_user_id: owner.id,
      }

      put "/review/#{reviewable.id}.json",
          params: {
            version: version,
            reviewable: {
              payload: details,
            },
          }

      expect(response.status).to eq(200)
      expect(submission.reload).to have_attributes(
        status: "approved",
        reviewed_at: approved_at,
        title: details[:title],
        description: details[:description].strip,
        salary: details[:salary],
        download_url: details[:download_url],
        contributor: details[:contributor],
        student_number: registration.student_number,
        contributor_user_id: owner.id,
      )
      expect(reviewable.reload).to be_approved
      revision = submission.reviews.order(:id).last
      expect(revision).to have_attributes(
        decision: "edit",
        reviewer_id: administrator.id,
        reviewer_name: administrator.name.presence || administrator.username,
        reviewer_username: administrator.username,
        previous_description: approval.description,
        description: details[:description].strip,
        original_description: submission.submitted_description,
      )
      expect(approval.reload).to have_attributes(
        decision: "approve",
        reviewer_id: developer.id,
        description: "Approved summary",
      )
      history = reviewable.reviewable_histories.where(type: ReviewableHistory.types[:edited]).sole
      expect(history).to have_attributes(created_by_id: administrator.id)
      expect(history.edited.fetch("payload").last).to include(
        "description" => details[:description].strip,
        "salary" => details[:salary],
        "download_url" => details[:download_url],
        "contributor" => details[:contributor],
        "submitted_details" => include("download_url" => original_download_url),
      )
      administrator.update!(name: "Renamed editor", username: "resume_editor_new")
      expect(revision.reload.reviewer_username).not_to eq(administrator.username)
      get "/isbf-resume/shares.json"
      expect(
        response.parsed_body.fetch("shares").find { |entry| entry.fetch("id") == submission.id },
      ).to include("description" => details[:description].strip, "title" => details[:title])

      put "/review/#{reviewable.id}.json",
          params: {
            version: version,
            reviewable: {
              payload: {
                description: "Stale published edit",
              },
            },
          }
      expect(response.status).to eq(409)
      expect(submission.reload.description).to eq(details[:description].strip)
      expect(submission.reviews.count).to eq(2)
    end

    it "keeps a published description nonempty and prefills the current text for legacy approved entries" do
      reviewable.perform(
        developer,
        :approve_resume,
        version: reviewable.version,
        description: "Current public text",
      )
      reviewable.update!(payload: { shared_resume_id: submission.id })
      sign_in(developer)
      get "/review/#{reviewable.id}.json"
      expect(response.parsed_body.fetch("reviewable").fetch("payload")).to include(
        "description" => "Current public text",
      )
      version = reviewable.version

      put "/review/#{reviewable.id}.json",
          params: {
            version: version,
            reviewable: {
              payload: {
                description: "   ",
              },
            },
          }

      expect(response.status).to eq(400)
      expect(reviewable.reload.version).to eq(version)
      expect(submission.reload.description).to eq("Current public text")
      expect(submission.reviews.count).to eq(1)
    end

    it "rolls back approved edits with an invalid document link or mismatched contributor" do
      reviewable.perform(
        developer,
        :approve_resume,
        version: reviewable.version,
        description: "Approved summary",
      )
      registration = Fabricate(:registered_academy_student, user: owner)
      original_payload = reviewable.reload.payload.deep_dup
      version = reviewable.version
      original_details = submission.reload.attributes
      sign_in(developer)

      [
        { download_url: "https://example.com/untrusted" },
        { student_number: registration.student_number, contributor_user_id: administrator.id },
      ].each do |invalid|
        put "/review/#{reviewable.id}.json",
            params: {
              version: version,
              reviewable: {
                payload: invalid,
              },
            }

        expect(response.status).to eq(400)
        expect(reviewable.reload).to have_attributes(payload: original_payload, version: version)
        expect(submission.reload.attributes).to eq(original_details)
        expect(submission.reviews.count).to eq(1)
      end
    end

    it "revokes approved edits immediately and denies uploaders and rejected entries" do
      reviewable.perform(
        developer,
        :approve_resume,
        version: reviewable.version,
        description: "Approved summary",
      )
      SiteSetting.academy_moderators_review_content = true
      SiteSetting.academy_moderators_review_resumes = true
      sign_in(administrator)
      get "/review/#{reviewable.id}.json"
      expect(response.parsed_body.fetch("reviewable")).to include("can_edit_resume" => true)
      version = reviewable.version
      SiteSetting.academy_moderators_review_resumes = false
      put "/review/#{reviewable.id}.json",
          params: {
            version: version,
            reviewable: {
              payload: {
                description: "Revoked editor",
              },
            },
          }
      expect(response.status).to eq(404)
      sign_in(owner)
      put "/review/#{reviewable.id}.json",
          params: {
            version: version,
            reviewable: {
              payload: {
                description: "Uploader edit",
              },
            },
          }
      expect(response.status).to eq(403)
      expect(submission.reload.description).to eq("Approved summary")
      expect(submission.reviews.count).to eq(1)
      rejected = Fabricate(:shared_isbf_resume).reviewable
      rejected.perform(
        developer,
        :reject_resume,
        version: rejected.version,
        description: "Rejected",
      )
      sign_in(developer)
      put "/review/#{rejected.id}.json",
          params: {
            version: rejected.version,
            reviewable: {
              payload: {
                description: "Rejected edit",
              },
            },
          }
      expect(response.status).to eq(403)
    end

    it "prefills legacy submissions and rejects invalid field types or lengths without saving" do
      reviewable.update!(payload: { shared_resume_id: submission.id, description: "Original" })
      sign_in(developer)
      get "/review/#{reviewable.id}.json"
      expect(response.parsed_body.fetch("reviewable").fetch("payload")).to include(
        "title" => submission.title,
        "position" => submission.position,
        "description" => "Original",
      )
      version = reviewable.version
      [{ salary: ["untrusted"] }, { title: "a" * 201 }].each do |invalid|
        put "/review/#{reviewable.id}.json",
            params: {
              version: version,
              reviewable: {
                payload: invalid,
              },
            }
        expect(response.status).to eq(400)
        expect(reviewable.reload.version).to eq(version)
      end
    end

    it "refuses to retarget a native review through payload.shared_resume_id" do
      other_submission = Fabricate(:shared_isbf_resume)
      original_payload = reviewable.payload.deep_dup
      version = reviewable.version
      sign_in(developer)

      put "/review/#{reviewable.id}.json",
          params: {
            version: version,
            reviewable: {
              payload: {
                description: "Retargeted draft",
                shared_resume_id: other_submission.id,
              },
            },
          }

      expect(response.status).to eq(403)
      expect(reviewable.reload).to have_attributes(payload: original_payload, version: version)
      expect(submission.reload).to be_pending
      expect(other_submission.reload).to be_pending
      expect(submission.reviews).to be_empty
      expect(other_submission.reviews).to be_empty
    end
  end

  describe "#perform" do
    it "keeps a resume with no description pending when native approval fails" do
      SiteSetting.default_locale = "en"
      blank_submission = Fabricate(:shared_isbf_resume, submitted_description: "")
      blank_review = blank_submission.reviewable
      version = blank_review.version
      sign_in(developer)

      put "/review/#{blank_review.id}/perform/approve_resume.json", params: { version: version }

      expect(response.status).to eq(422)
      expect(response.parsed_body.fetch("errors")).to include(
        I18n.t("isbf_resume.sharing.review_description_required"),
      )
      expect(blank_submission.reload).to have_attributes(
        status: "pending",
        description: "",
        reviewed_at: nil,
      )
      expect(blank_submission.reviews).to be_empty
      expect(blank_review.reload).to have_attributes(status: "pending", version: version)
      expect(IsbfResume::SharedResume.published).not_to include(blank_submission)
    end

    it "edits and approves with only the resume capability while ordinary review remains forbidden" do
      SiteSetting.academy_moderators_review_resumes = true
      SiteSetting.academy_moderators_review_content = false
      SiteSetting.academy_moderators_edit_others_content = false
      unrelated = Fabricate(:reviewable_queued_post, force_review: true)
      recorded_name = administrator.name.presence || administrator.username
      recorded_username = administrator.username
      original_description = submission.submitted_description
      original_version = reviewable.version
      sign_in(administrator)

      get "/review.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("reviewables").map { |item| item.fetch("id") }).to eq(
        [reviewable.id],
      )
      get "/review/#{unrelated.id}.json"
      expect(response.status).to eq(404)
      put "/review/#{unrelated.id}/perform/approve_post.json",
          params: {
            version: unrelated.version,
          }
      expect(response.status).to eq(404)
      expect(unrelated.reload).to be_pending

      put "/review/#{reviewable.id}.json",
          params: {
            version: original_version,
            reviewable: {
              payload: {
                description: "  Administrator's native summary  ",
                title: "Reviewed title",
                industry: "Finance",
                position: "Analyst",
                salary: "20k per month",
                experience: "3 years",
              },
            },
          }
      expect(response.status).to eq(200)
      expect(submission.reload).to be_pending
      expect(submission.reviews).to be_empty
      version = response.parsed_body.fetch("version")
      edited_history =
        reviewable.reviewable_histories.where(type: ReviewableHistory.types[:edited]).sole
      expect(edited_history).to have_attributes(created_by_id: administrator.id)
      expect(edited_history.edited.fetch("payload").last).to include(
        "salary" => "20k per month",
        "submitted_details" => include("title" => submission.title),
      )

      put "/review/#{reviewable.id}/perform/approve_resume.json",
          params: {
            version: original_version,
          }
      expect(response.status).to eq(409)
      expect(submission.reload).to be_pending
      put "/review/#{reviewable.id}/perform/approve_resume.json", params: { version: version }
      expect(response.status).to eq(200)
      expect(reviewable.reload).to have_attributes(status: "approved")
      expect(reviewable.payload).to include("description" => "Administrator's native summary")
      expect(submission.reload).to have_attributes(
        status: "approved",
        description: "Administrator's native summary",
        submitted_description: original_description,
        title: "Reviewed title",
        industry: "Finance",
        position: "Analyst",
        salary: "20k per month",
        experience: "3 years",
      )
      review = submission.reviews.sole
      expect(review).to have_attributes(
        reviewer_id: administrator.id,
        reviewer_name: recorded_name,
        reviewer_username: recorded_username,
        original_description: original_description,
        description: "Administrator's native summary",
      )
      administrator.update!(name: "Later native reviewer name", username: "renamed_native_user")
      expect(review.reload).to have_attributes(
        reviewer_name: recorded_name,
        reviewer_username: recorded_username,
      )
      expect(IsbfResume::SharedResume.published).to contain_exactly(submission)
    end

    it "rejects legacy submissions without a WPS link or public description" do
      blank_submission = Fabricate(:shared_isbf_resume, submitted_description: "", download_url: "")
      native_review = blank_submission.reviewable
      sign_in(developer)

      put "/review/#{native_review.id}/perform/reject_resume.json",
          params: {
            version: native_review.version,
          }

      expect(response.status).to eq(200)
      expect(native_review.reload).to be_rejected
      expect(blank_submission.reload).to have_attributes(
        status: "rejected",
        description: "",
        download_url: "",
      )
      expect(blank_submission.reviews.sole).to have_attributes(
        reviewer_id: developer.id,
        decision: "reject",
        original_description: "",
        description: "",
      )
      expect(IsbfResume::SharedResume.published).to be_empty
    end
  end
end
