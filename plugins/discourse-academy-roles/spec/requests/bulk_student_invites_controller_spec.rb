# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::StudentInvitesController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :academy_student_registration)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  def upload_csv(content, filename: "students.csv")
    file = file_from_contents("", filename)
    File.binwrite(file.path, content)
    Rack::Test::UploadedFile.new(file, "text/csv", true)
  end

  describe "#bulk" do
    it "returns 201 with a Chinese downloadable result and exposes only newly issued codes" do
      sign_in(admin)
      SiteSetting.default_locale = "zh_CN"
      expires_at = 2.days.from_now.iso8601
      file =
        upload_csv(
          Encodings::BOM +
            "学号\r\n000123\r\n#{registration.student_number}\r\n000123\r\n\r\n"
        )

      post "/academy-roles/admin/student-invites/bulk.json",
           params: {
             file:,
             expires_at:
           }

      expect(response.status).to eq(201)
      expect(response.parsed_body).to include(
        "created_count" => 1,
        "skipped_count" => 2,
        "failed_count" => 1
      )
      output = response.parsed_body["csv"]
      expect(output).to start_with(Encodings::BOM)
      exported = CSV.parse(output.delete_prefix(Encodings::BOM))
      expect(exported.first).to eq(%w[学号 邀请码 邀请链接 到期时间（UTC） 处理结果 原因])
      created =
        DiscourseAcademyRoles::StudentRegistration.find_by!(
          student_number: "000123"
        )
      expect(exported[1]).to eq(
        [
          "000123",
          created.invite.invite_key,
          created.invite.link,
          expires_at,
          "已生成",
          ""
        ]
      )
      expect(exported.drop(2).map { |row| row[1..3] }).to eq(
        [["", "", ""], ["", "", ""], ["", "", ""]]
      )
      expect(response.body).not_to include(registration.invite.invite_key)
      expect(output).not_to include(registration.invite.link)
    end

    it "returns 200 when every row is skipped or failed without creating invitations" do
      sign_in(admin)

      expect do
        post "/academy-roles/admin/student-invites/bulk.json",
             params: {
               file:
                 upload_csv("#{registration.student_number}\n\n000123,extra\n")
             }
      end.not_to change(Invite, :count)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "created_count" => 0,
        "skipped_count" => 1,
        "failed_count" => 2
      )
      expect(response.parsed_body["csv"]).not_to include(
        registration.invite.invite_key
      )
    end

    it "returns 400 for invalid uploads and invalid expiry before creating records" do
      sign_in(admin)
      registrations_before = DiscourseAcademyRoles::StudentRegistration.count
      parameters = [
        {},
        { file: "students.csv" },
        { file: upload_csv("000123\n", filename: "students.txt") },
        { file: upload_csv("") },
        { file: upload_csv("\xFF".b) },
        { file: upload_csv("\"unterminated\n") },
        { file: upload_csv("0" * (1.megabyte + 1)) },
        { file: upload_csv("student_number\n" + "000123\n" * 1501) },
        { file: upload_csv("000123\n"), expires_at: 1.day.ago.iso8601 }
      ]

      parameters.each do |params|
        expect {
          post "/academy-roles/admin/student-invites/bulk.json", params:
        }.not_to change(Invite, :count)
        expect(response.status).to eq(400)
        expect(response.parsed_body["errors"]).to be_present
      end
      expect(DiscourseAcademyRoles::StudentRegistration.count).to eq(
        registrations_before
      )
    end

    it "rejects visitors, members and moderators without disclosing the export" do
      [nil, member, moderator].each do |actor|
        sign_in(actor) if actor

        expect do
          post "/academy-roles/admin/student-invites/bulk.json",
               params: {
                 file: upload_csv("#{registration.student_number}\n000123\n")
               }
        end.not_to change(Invite, :count)

        expect(response.status).to eq(403)
        expect(response.parsed_body).not_to have_key("csv")
        expect(response.body).not_to include(registration.student_number)
        expect(response.body).not_to include(registration.invite.invite_key)
      end
    end

    it "returns 404 for a disabled plugin" do
      sign_in(admin)
      SiteSetting.academy_roles_enabled = false

      expect do
        post "/academy-roles/admin/student-invites/bulk.json",
             params: {
               file: upload_csv("000123\n")
             }
      end.not_to change(Invite, :count)

      expect(response.status).to eq(404)
    end
  end

  describe "admin bulk page reload" do
    it "serves the application page for an administrator and rejects non-administrators" do
      sign_in(admin)

      get "/admin/plugins/discourse-academy-roles/student-invites/bulk"

      expect(response.status).to eq(200)
      expect(response.body).not_to include(registration.student_number)

      [member, moderator].each do |actor|
        sign_in(actor)
        get "/admin/plugins/discourse-academy-roles/student-invites/bulk"

        expect(response.status).to eq(404)
      end
    end
  end
end
