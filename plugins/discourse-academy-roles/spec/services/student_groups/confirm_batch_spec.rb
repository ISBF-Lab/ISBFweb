# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentGroups::ConfirmBatch do
  fab!(:admin)
  fab!(:target, :group)
  fab!(:registration, :registered_academy_student)

  before { SiteSetting.academy_roles_enabled = true }

  let(:batch) do
    DiscourseAcademyRoles::StudentGroups::Preview.create(
      actor: admin, mode: "groups", input_kind: "list",
      student_numbers: registration.student_number, add_group_ids: [target.id],
    )
  end

  describe ".call" do
    it "queues only the confirmed selection and accepts an identical repeated confirmation" do
      other = Fabricate(:registered_academy_student)
      preview = DiscourseAcademyRoles::StudentGroups::Preview.create(
        actor: admin, mode: "groups", input_kind: "list",
        student_numbers: [registration.student_number, other.student_number].join("\n"),
        add_group_ids: [target.id],
      )
      selected_id = preview.items.order(:position).first.id
      params = { batch_id: preview.id, selected_item_ids: [selected_id] }
      jobs_before = Jobs::AcademyStudentGroupBatch.jobs.size

      2.times do
        expect(described_class.call(params:, guardian: admin.guardian)).to run_successfully
      end

      expect(preview.reload.state).to eq("queued")
      expect(preview.items.order(:position).pluck(:status, :selected)).to eq([["queued", true], ["excluded", false]])
      expect(Jobs::AcademyStudentGroupBatch.jobs.size).to eq(jobs_before + 1)
      expect(GroupUser.exists?(group: target, user_id: registration.user_id)).to eq(false)
    end

    it "rejects expired previews without queuing membership changes" do
      batch.update!(expires_at: 1.second.ago)

      expect do
        described_class.call(params: { batch_id: batch.id, selected_item_ids: batch.items.pluck(:id) }, guardian: admin.guardian)
      end.to raise_error(DiscourseAcademyRoles::StudentGroups::Error) { |error| expect(error.code).to eq("preview_expired") }
      expect(batch.reload.state).to eq("preview")
    end

    it "rejects item identifiers outside the preview and empty selections" do
      [[], [batch.items.maximum(:id) + 1]].each do |selection|
        expect do
          described_class.call(params: { batch_id: batch.id, selected_item_ids: selection }, guardian: admin.guardian)
        end.to raise_error(DiscourseAcademyRoles::StudentGroups::Error)
      end
      expect(batch.reload.state).to eq("preview")
    end

    it "requires the native administrator role and the original initiator" do
      [Fabricate(:moderator), Fabricate(:user)].each do |actor|
        result = described_class.call(params: { batch_id: batch.id, selected_item_ids: batch.items.pluck(:id) }, guardian: actor.guardian)
        expect(result).to fail_a_policy(:developer)
      end
      result = described_class.call(params: { batch_id: batch.id, selected_item_ids: batch.items.pluck(:id) }, guardian: Fabricate(:admin).guardian)
      expect(result).to fail_a_policy(:initiator)
      expect(batch.reload.state).to eq("preview")
    end

    it "rejects configuration changes after preview" do
      batch
      target.update!(title: "Changed after preview")

      expect do
        described_class.call(params: { batch_id: batch.id, selected_item_ids: batch.items.pluck(:id) }, guardian: admin.guardian)
      end.to raise_error(DiscourseAcademyRoles::StudentGroups::Error) { |error| expect(error.code).to eq("groups_changed") }
    end
  end
end
