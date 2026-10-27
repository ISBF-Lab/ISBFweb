# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::StudentGroupBatchesController do
  fab!(:developer, :admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:target, :group)
  fab!(:registration, :registered_academy_student)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  let(:base) { "/academy-roles/admin/student-group-batches" }
  let(:preview_params) do
    {
      mode: "groups",
      input_kind: "list",
      student_numbers: registration.student_number,
      add_group_ids: [target.id],
    }
  end
  let(:batch) do
    DiscourseAcademyRoles::StudentGroups::Preview.create(actor: developer, **preview_params)
  end

  describe "developer authorization" do
    it "denies guests, members, group owners and restricted administrators on every endpoint" do
      target.add(member)
      GroupUser.find_by!(group: target, user: member).update!(owner: true)
      DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end
      batch
      [nil, member, moderator].each do |actor|
        sign_in(actor) if actor
        [
          "#{base}.json",
          "#{base}/options.json",
          "#{base}/#{batch.id}.json",
          "#{base}/#{batch.id}/download.csv",
        ].each do |path|
          get path
          expect(response.status).to eq(403)
        end
        [
          "#{base}/preview.json",
          "#{base}/#{batch.id}/execute.json",
          "#{base}/#{batch.id}/retry.json",
          "#{base}/#{batch.id}/undo-preview.json",
        ].each do |path|
          post path, params: preview_params, as: :json
          expect(response.status).to eq(403)
        end
      end
      expect(batch.reload.state).to eq("preview")
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end
  end

  describe "preview, execute and undo" do
    it "keeps preview read-only, executes the confirmed list, restores a batch after refresh and undoes only confirmed changes" do
      sign_in(developer)
      post "#{base}/preview.json", params: preview_params, as: :json
      expect(response.status).to eq(200)
      result = response.parsed_body
      batch_id = result.fetch("batch").fetch("id")
      item_id = result.fetch("items").sole.fetch("id")
      expect(result.fetch("items").sole).to include(
        "student_number" => registration.student_number,
        "selectable" => true,
      )
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)

      post "#{base}/#{batch_id}/execute.json", params: { selected_item_ids: [item_id] }, as: :json
      expect(response.status).to eq(200)
      Jobs::AcademyStudentGroupBatch.new.execute(batch_id:)
      get "#{base}/#{batch_id}.json"
      expect(response.parsed_body.fetch("batch")).to include(
        "state" => "completed",
        "can_undo" => true,
      )
      expect(response.parsed_body.fetch("items").sole.fetch("completed_add_groups")).to eq(
        [target.name],
      )
      post "#{base}/#{batch_id}/undo-preview.json", as: :json
      expect(response.status).to eq(200)
      undo = response.parsed_body
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(true)
      post "#{base}/#{undo.fetch("batch").fetch("id")}/execute.json",
           params: {
             selected_item_ids: undo.fetch("batch").fetch("selected_item_ids"),
           },
           as: :json
      expect(response.status).to eq(200)
      Jobs::AcademyStudentGroupBatch.new.execute(batch_id: undo.fetch("batch").fetch("id"))
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end
  end

  describe "#download" do
    it "exports escaped student numbers and completed deltas without invitation secrets" do
      registration.update_column(:student_number, "=1+1")
      sign_in(developer)
      get "#{base}/#{batch.id}/download.csv"
      expect(response.status).to eq(200)
      rows = CSV.parse(response.body, headers: true)
      expect(rows.sole["student_number"]).to eq("'=1+1")
      expect(rows.headers).to include(
        "completed_additions",
        "completed_removals",
        "primary_group_before",
        "title_after",
        "flair_group_after",
      )
      expect(response.body).not_to include(registration.invite.invite_key)
    end
  end
end
