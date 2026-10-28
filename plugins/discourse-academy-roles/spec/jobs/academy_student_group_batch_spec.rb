# frozen_string_literal: true

RSpec.describe Jobs::AcademyStudentGroupBatch do
  fab!(:admin)
  fab!(:target, :group)
  fab!(:source, :group)
  fab!(:registration, :registered_academy_student)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  def queue_preview(add_group_ids: [target.id], remove_group_ids: [])
    batch =
      DiscourseAcademyRoles::StudentGroups::Preview.create(
        actor: admin,
        mode: "groups",
        input_kind: "list",
        student_numbers: registration.student_number,
        add_group_ids:,
        remove_group_ids:,
      )
    DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
      actor: admin,
      batch:,
      selected_item_ids: batch.items.pluck(:id),
    )
    batch
  end

  describe "#execute" do
    it "uses native membership changes and preserves bindings and invitations on repeated delivery" do
      source.add(registration.user)
      batch = queue_preview(remove_group_ids: [source.id])
      binding_before = registration.reload.attributes
      invite_before = registration.invite.reload.attributes

      2.times { described_class.new.execute(batch_id: batch.id) }

      expect(batch.reload.state).to eq("completed")
      expect(batch.items.sole.status).to eq("success")
      expect(
        GroupUser.where(user_id: registration.user_id, group_id: [source.id, target.id]).pluck(
          :group_id,
        ),
      ).to eq([target.id])
      expect(target.reload.user_count).to eq(1)
      expect(source.reload.user_count).to eq(0)
      expect(batch.items.sole.completed_steps.map { |step| step.fetch("operation") }).to eq(
        %w[add remove],
      )
      expect(registration.reload.attributes).to eq(binding_before)
      expect(registration.invite.reload.attributes).to eq(invite_before)
    end

    it "blocks queued execution when the initiator loses the native administrator role" do
      batch = queue_preview
      admin.update!(admin: false, moderator: true)

      described_class.new.execute(batch_id: batch.id)

      expect(batch.reload.state).to eq("blocked")
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end

    it "rejects membership changes that happened after preview" do
      batch = queue_preview
      target.add(registration.user)
      membership = GroupUser.find_by!(group: target, user_id: registration.user_id)

      described_class.new.execute(batch_id: batch.id)

      expect(batch.items.sole.status).to eq("conflict")
      expect(GroupUser.find_by!(group: target, user_id: registration.user_id).id).to eq(
        membership.id,
      )
    end

    it "treats an interrupted native operation as ambiguous and leaves it for inspection" do
      batch = queue_preview
      item = batch.items.sole
      steps = item.steps
      steps.first["state"] = "started"
      item.update!(steps:)

      described_class.new.execute(batch_id: batch.id)

      expect(item.reload.status).to eq("conflict")
      expect(item.reason_code).to eq("uncertain_result")
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end

    it "undoes completed membership changes when their snapshots still match" do
      source.add(registration.user)
      batch = queue_preview(remove_group_ids: [source.id])
      described_class.new.execute(batch_id: batch.id)
      undo = DiscourseAcademyRoles::StudentGroups::Preview.undo(actor: admin, source: batch.reload)
      DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
        actor: admin,
        batch: undo,
        selected_item_ids: undo.items.pluck(:id),
      )

      described_class.new.execute(batch_id: undo.id)

      expect(undo.reload.state).to eq("completed")
      expect(
        GroupUser.where(user_id: registration.user_id, group_id: [source.id, target.id]).pluck(
          :group_id,
        ),
      ).to eq([source.id])
    end

    it "excludes later profile changes from undo" do
      batch = queue_preview
      described_class.new.execute(batch_id: batch.id)
      registration.user.update!(title: "Later title")

      undo = DiscourseAcademyRoles::StudentGroups::Preview.undo(actor: admin, source: batch.reload)

      expect(undo.items.sole.status).to eq("conflict")
      expect(undo.items.sole.selected).to eq(false)
      expect(registration.user.reload.title).to eq("Later title")
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(true)
    end
  end
end
