# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::Admin::StudentGroupBatchesController do
  fab!(:developer, :admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:group_owner, :user)
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
    before do
      target.add(group_owner)
      GroupUser.find_by!(group: target, user: group_owner).update!(owner: true)
      DiscourseAcademyRoles::ModeratorPermissions::SETTINGS.values.each do |setting|
        SiteSetting.public_send("#{setting}=", true)
      end
    end

    %i[guest member group_owner moderator].each do |role|
      it "denies a #{role} on every endpoint with all moderator permissions enabled" do
        batch
        sign_in(public_send(role)) unless role == :guest
        batch_count = DiscourseAcademyRoles::StudentGroupBatch.count

        [
          "#{base}.json",
          "#{base}/options.json",
          "#{base}/#{batch.id}.json",
          "#{base}/#{batch.id}/download.csv",
        ].each do |path|
          get path
          expect(response.status).to eq(403), "#{role}: GET #{path}"
        end
        [
          "#{base}/preview.json",
          "#{base}/#{batch.id}/execute.json",
          "#{base}/#{batch.id}/retry.json",
          "#{base}/#{batch.id}/undo-preview.json",
        ].each do |path|
          post path, params: preview_params, as: :json
          expect(response.status).to eq(403), "#{role}: POST #{path}"
        end

        expect(DiscourseAcademyRoles::StudentGroupBatch.count).to eq(batch_count)
        expect(batch.reload.state).to eq("preview")
        expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
      end
    end
  end

  describe "CSRF protection" do
    around do |example|
      previous = described_class.allow_forgery_protection
      described_class.allow_forgery_protection = true
      example.run
    ensure
      described_class.allow_forgery_protection = previous
    end

    it "requires a CSRF token for every mutation even from a signed-in developer" do
      batch_count = DiscourseAcademyRoles::StudentGroupBatch.count
      batch
      [
        "#{base}/preview.json",
        "#{base}/#{batch.id}/execute.json",
        "#{base}/#{batch.id}/retry.json",
        "#{base}/#{batch.id}/undo-preview.json",
      ].each do |path|
        sign_in(developer)
        post path, params: preview_params, as: :json
        expect(response.status).to eq(403),
        "POST #{path} without a CSRF token returned #{response.status}"
        expect(response.body).to include("BAD CSRF")
      end

      expect(DiscourseAcademyRoles::StudentGroupBatch.count).to eq(batch_count + 1)
      expect(batch.reload.state).to eq("preview")
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end
  end

  describe "#show" do
    it "lets another developer inspect an existing batch" do
      sign_in(Fabricate(:admin))
      get "#{base}/#{batch.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("items").sole.fetch("student_number")).to eq(
        registration.student_number,
      )
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end

  describe "#execute" do
    it "rejects another developer even when the request spoofs the initiator" do
      sign_in(Fabricate(:admin))
      post "#{base}/#{batch.id}/execute.json",
           params: {
             selected_item_ids: [batch.items.sole.id],
             actor_id: developer.id,
           },
           as: :json

      expect(response.status).to eq(403)
      expect(batch.reload.state).to eq("preview")
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end

    it "rejects selected accounts from a different batch" do
      other_registration = Fabricate(:registered_academy_student)
      other_batch =
        DiscourseAcademyRoles::StudentGroups::Preview.create(
          actor: developer,
          **preview_params.merge(student_numbers: other_registration.student_number),
        )
      sign_in(developer)
      post "#{base}/#{batch.id}/execute.json",
           params: {
             selected_item_ids: [other_batch.items.sole.id],
           },
           as: :json

      expect(response.status).to eq(409)
      expect([batch.reload.state, other_batch.reload.state]).to eq(%w[preview preview])
      expect(
        GroupUser.exists?(
          group: target,
          user_id: [registration.user_id, other_registration.user_id],
        ),
      ).to eq(false)
    end
  end

  describe "#retry" do
    it "rejects another developer even for a retryable batch" do
      batch.update!(state: "blocked")
      batch.items.update_all(selected: true, status: "queued")
      sign_in(Fabricate(:admin))
      post "#{base}/#{batch.id}/retry.json", params: { actor_id: developer.id }, as: :json

      expect(response.status).to eq(403)
      expect(batch.reload.state).to eq("blocked")
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end
  end

  describe "preview, execute and undo" do
    it "keeps preview read-only, executes the confirmed list, restores a batch after refresh and undoes only confirmed changes" do
      student_group = Fabricate(:group)
      student_group.add(registration.user)
      sign_in(developer)
      post "#{base}/preview.json",
           params: preview_params.merge(remove_group_ids: [student_group.id]),
           as: :json
      expect(response.status).to eq(200)
      result = response.parsed_body
      batch_id = result.fetch("batch").fetch("id")
      item_id = result.fetch("items").sole.fetch("id")
      expect(result.fetch("batch")).to include(
        "add_groups" => [{ "id" => target.id, "name" => target.name }],
        "remove_groups" => [{ "id" => student_group.id, "name" => student_group.name }],
      )
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
      expect(undo.fetch("batch")).to include(
        "add_groups" => [{ "id" => student_group.id, "name" => student_group.name }],
        "remove_groups" => [{ "id" => target.id, "name" => target.name }],
      )
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(true)
      post "#{base}/#{undo.fetch("batch").fetch("id")}/execute.json",
           params: {
             selected_item_ids: undo.fetch("batch").fetch("selected_item_ids"),
           },
           as: :json
      expect(response.status).to eq(200)
      Jobs::AcademyStudentGroupBatch.new.execute(batch_id: undo.fetch("batch").fetch("id"))
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
      expect(GroupUser.exists?(group: student_group, user_id: registration.user_id)).to eq(true)
    end
  end

  describe "#download" do
    it "exports UTF-8 CSV with a BOM, escaped values and actual completed deltas without invitation secrets" do
      registration.update_column(:student_number, "=1+1")
      title = "@SUM(1,2) \"\u5b66\u53f7\"\r\nnext line"
      registration.user.update!(title:)
      sign_in(developer)
      get "#{base}/#{batch.id}/download.csv"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include(
        "attachment",
        "student-group-batch-#{batch.id}.csv",
      )
      expect(response.headers["Cache-Control"]).to include("no-store")
      output = response.body.dup.force_encoding(Encoding::UTF_8)
      expect(output.valid_encoding?).to eq(true)
      expect(output).to start_with(Encodings::BOM)
      rows = CSV.parse(output.delete_prefix(Encodings::BOM), headers: true)
      expect(rows.sole.to_h).to include(
        "student_number" => "'=1+1",
        "requested_additions" => target.name,
        "completed_additions" => "",
        "title_before" => "'#{title}",
      )
      expect(rows.headers).to include(
        "completed_additions",
        "completed_removals",
        "primary_group_before",
        "title_after",
        "flair_group_after",
      )
      expect(output.include?(registration.invite.invite_key)).to eq(false)
      expect(output.include?(registration.invite.link)).to eq(false)

      DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
        actor: developer,
        batch:,
        selected_item_ids: [batch.items.sole.id],
      )
      Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)
      get "#{base}/#{batch.id}/download.csv"

      expect(response.status).to eq(200)
      output = response.body.dup.force_encoding(Encoding::UTF_8)
      rows = CSV.parse(output.delete_prefix(Encodings::BOM), headers: true)
      expect(rows.sole.to_h).to include(
        "status" => "success",
        "requested_additions" => target.name,
        "completed_additions" => target.name,
        "completed_removals" => "",
        "title_after" => "'#{title}",
      )
      expect(output.include?(registration.invite.invite_key)).to eq(false)
      expect(output.include?(registration.invite.link)).to eq(false)
    end
  end
end
