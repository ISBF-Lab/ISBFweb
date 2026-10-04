# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::StudentInvitesController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:student_registration, :academy_student_registration)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#index" do
    it "returns codes, expiration and student numbers for administrators" do
      sign_in(admin)

      get "/academy-roles/admin/student-invites.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["student_invites"]).to contain_exactly(
        hash_including(
          "id" => student_registration.id,
          "student_number" => student_registration.student_number,
          "status" => "pending",
          "invite_key" => student_registration.invite.invite_key,
          "link" => student_registration.invite.link
        )
      )
      expect(response.parsed_body["has_more"]).to eq(false)
    end

    it "rejects visitors, members and moderators without disclosing student numbers" do
      get "/academy-roles/admin/student-invites.json"
      expect(response.status).to eq(403)
      expect(response.body).not_to include(student_registration.student_number)

      [member, moderator].each do |actor|
        sign_in(actor)
        get "/academy-roles/admin/student-invites.json"

        expect(response.status).to eq(403)
        expect(response.body).not_to include(
          student_registration.student_number
        )
      end
    end
  end

  describe "#create" do
    it "creates a student invitation with a 201 response" do
      sign_in(admin)

      post "/academy-roles/admin/student-invites.json",
           params: {
             student_number: " 0002026 "
           }

      expect(response.status).to eq(201)
      expect(response.parsed_body).to include(
        "student_number" => "0002026",
        "status" => "pending"
      )
      expect(response.parsed_body["invite_key"]).to be_present
      expect(response.parsed_body["link"]).to include(
        response.parsed_body["invite_key"]
      )
    end

    it "returns conflict for a reserved student number" do
      sign_in(admin)

      expect do
        post "/academy-roles/admin/student-invites.json",
             params: {
               student_number: student_registration.student_number
             }
      end.not_to change(Invite, :count)

      expect(response.status).to eq(409)
    end

    it "rejects invalid student numbers and expiration values" do
      sign_in(admin)

      [
        { student_number: " " },
        { student_number: "1" * 65 },
        { student_number: "0002026", expires_at: 1.day.ago.iso8601 }
      ].each do |parameters|
        post "/academy-roles/admin/student-invites.json", params: parameters

        expect(response.status).to eq(400)
        expect(response.parsed_body["errors"]).to be_present
      end
    end

    it "rejects members and moderators" do
      [member, moderator].each do |actor|
        sign_in(actor)

        expect do
          post "/academy-roles/admin/student-invites.json",
               params: {
                 student_number: "0002026"
               }
        end.not_to change(DiscourseAcademyRoles::StudentRegistration, :count)

        expect(response.status).to eq(403)
      end
    end
  end

  describe "#reissue" do
    it "returns the replacement code and invalidates the previous code" do
      sign_in(admin)
      previous_invite = student_registration.invite

      post "/academy-roles/admin/student-invites/#{student_registration.id}/reissue.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["student_number"]).to eq(
        student_registration.student_number
      )
      expect(response.parsed_body["invite_key"]).not_to eq(
        previous_invite.invite_key
      )
      expect(previous_invite.reload).not_to be_redeemable
    end

    it "returns conflict for an already registered student" do
      sign_in(admin)
      registered = Fabricate(:registered_academy_student)

      post "/academy-roles/admin/student-invites/#{registered.id}/reissue.json"

      expect(response.status).to eq(409)
    end

    it "rejects member and moderator attempts to replace a code" do
      [member, moderator].each do |actor|
        sign_in(actor)

        expect do
          post "/academy-roles/admin/student-invites/#{student_registration.id}/reissue.json"
        end.not_to change(Invite, :count)

        expect(response.status).to eq(403)
      end
    end
  end

  describe "#destroy" do
    it "revokes a pending code with an empty 204 response" do
      sign_in(admin)

      delete "/academy-roles/admin/student-invites/#{student_registration.id}.json"

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
      expect(student_registration.reload.status).to eq("revoked")
    end

    it "returns conflict for an already registered student" do
      sign_in(admin)
      registered = Fabricate(:registered_academy_student)

      delete "/academy-roles/admin/student-invites/#{registered.id}.json"

      expect(response.status).to eq(409)
    end

    it "rejects member and moderator attempts to revoke a code" do
      [member, moderator].each do |actor|
        sign_in(actor)
        delete "/academy-roles/admin/student-invites/#{student_registration.id}.json"

        expect(response.status).to eq(403)
        expect(student_registration.reload.invite.invalidated_at).to be_nil
      end
    end
  end
end
