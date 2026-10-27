# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentGroups::Runner do
  fab!(:developer, :admin)
  fab!(:registration, :registered_academy_student)
  fab!(:source, :group)
  fab!(:target, :group)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  def confirmed_batch
    batch =
      DiscourseAcademyRoles::StudentGroups::Preview.create(
        actor: developer,
        mode: "groups",
        input_kind: "list",
        student_numbers: registration.student_number,
        add_group_ids: [target.id],
        remove_group_ids: [source.id],
      )
    DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
      actor: developer,
      batch:,
      selected_item_ids: batch.items.pluck(:id),
    )
    batch
  end

  it "restores primary group, title and flair after native membership changes" do
    source.update!(primary_group: true, title: "Student")
    target.update!(primary_group: true, title: "Alumni")
    source.add(registration.user)
    original_display =
      registration.user.reload.attributes.slice("primary_group_id", "title", "flair_group_id")
    batch = confirmed_batch

    Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)
    expect(registration.user.reload.primary_group_id).to eq(target.id)
    expect(registration.user.title).to eq(target.title)
    undo =
      DiscourseAcademyRoles::StudentGroups::Preview.undo(actor: developer, source: batch.reload)
    DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
      actor: developer,
      batch: undo,
      selected_item_ids: undo.items.pluck(:id),
    )
    Jobs::AcademyStudentGroupBatch.new.execute(batch_id: undo.id)

    expect(undo.reload.state).to eq("completed")
    expect(
      registration.user.reload.attributes.slice("primary_group_id", "title", "flair_group_id"),
    ).to eq(original_display)
    expect(undo.items.sole.display_restored).to eq(true)
  end

  it "preserves completed additions when a later native step has an uncertain result" do
    source.add(registration.user)
    batch = confirmed_batch
    Group.any_instance.stubs(:bulk_remove).raises(StandardError)

    Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)

    expect(batch.reload.state).to eq("partial")
    expect(batch.items.sole.completed_steps.map { |step| step["operation"] }).to eq(["add"])
    expect(batch.items.sole.status).to eq("conflict")
    expect(batch.items.sole.reason_code).to eq("uncertain_result")
    expect(
      GroupUser.where(user_id: registration.user_id, group_id: [source.id, target.id]).pluck(
        :group_id,
      ),
    ).to contain_exactly(source.id, target.id)
    expect(batch.can_retry?).to eq(false)
  end

  it "retries only pending steps after a pre-mutation connection failure" do
    batch = confirmed_batch
    Group.stubs(:transaction).raises(ActiveRecord::ConnectionNotEstablished)
    Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)
    expect(batch.items.sole.status).to eq("failed")
    expect(batch.can_retry?).to eq(true)
    Group.unstub(:transaction)

    DiscourseAcademyRoles::StudentGroups::Confirmation.retry(actor: developer, batch: batch.reload)
    2.times { Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id) }

    expect(batch.reload.state).to eq("completed")
    expect(target.reload.user_count).to eq(1)
    expect(
      GroupHistory.where(
        group_id: target.id,
        action: GroupHistory.actions[:add_user_to_group],
        target_user_id: registration.user_id,
      ).count,
    ).to eq(1)
  end

  it "publishes progress only to native developers without student numbers" do
    batch = confirmed_batch
    messages =
      MessageBus.track_publish(batch.channel) do
        Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)
      end

    expect(messages).not_to be_empty
    expect(messages.last.user_ids).to include(developer.id)
    expect(messages.last.data.to_json).not_to include(registration.student_number)
    expect(GroupHistory.where(group_id: target.id).pluck(:subject)).to include(
      "academy-group-batch:#{batch.id}:#{batch.items.sole.id}:0",
    )
  end

  it "continues a bounded slice without replaying the preceding accounts" do
    others = 2.times.map { Fabricate(:registered_academy_student) }
    batch =
      DiscourseAcademyRoles::StudentGroups::Preview.create(
        actor: developer,
        mode: "groups",
        input_kind: "list",
        student_numbers: ([registration] + others).map(&:student_number).join("\n"),
        add_group_ids: [target.id],
      )
    DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
      actor: developer,
      batch:,
      selected_item_ids: batch.items.pluck(:id),
    )
    stub_const(DiscourseAcademyRoles::StudentGroups, :CHUNK_SIZE, 2) do
      Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)
      expect(batch.reload.state).to eq("queued")
      expect(batch.items.group(:status).count).to eq("success" => 2, "queued" => 1)
      Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)
    end
    expect(batch.reload.state).to eq("completed")
    expect(target.reload.user_count).to eq(3)
  end

  it "skips restoring an original primary group removed after the batch" do
    source.update!(primary_group: true, title: "Student")
    target.update!(primary_group: true, title: "Alumni")
    source.add(registration.user)
    batch =
      DiscourseAcademyRoles::StudentGroups::Preview.create(
        actor: developer,
        mode: "groups",
        input_kind: "list",
        student_numbers: registration.student_number,
        add_group_ids: [target.id],
      )
    DiscourseAcademyRoles::StudentGroups::Confirmation.execute(
      actor: developer,
      batch:,
      selected_item_ids: batch.items.pluck(:id),
    )
    Jobs::AcademyStudentGroupBatch.new.execute(batch_id: batch.id)
    source.destroy!

    undo =
      DiscourseAcademyRoles::StudentGroups::Preview.undo(actor: developer, source: batch.reload)

    expect(undo.items.sole.status).to eq("conflict")
    expect(registration.user.reload.primary_group_id).to eq(target.id)
    expect(GroupUser.exists?(user_id: registration.user_id, group_id: target.id)).to eq(true)
  end
end
