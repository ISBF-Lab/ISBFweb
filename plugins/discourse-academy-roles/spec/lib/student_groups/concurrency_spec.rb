# frozen_string_literal: true

RSpec.describe "Student group batch concurrency", type: :model do
  self.use_transactional_tests = false

  before do
    SiteSetting.academy_roles_enabled = true
    @developer = Fabricate(:admin)
    @target = Fabricate(:group)
    @registration = Fabricate(:registered_academy_student)
    @threads = []
  end

  after do
    @threads.each do |thread|
      thread.kill if thread.alive?
      thread.join
    end
    if @batch
      DiscourseAcademyRoles::StudentGroupBatchItem.where(batch_id: @batch.id).delete_all
      @batch.delete
    end
    @target&.destroy!
    if @registration
      invite = @registration.invite
      user = @registration.user
      @registration.delete
      invite&.destroy!
      user&.destroy!
    end
    @developer&.destroy!
    SiteSetting.academy_roles_enabled = false
  end

  it "keeps one native membership and one audit entry under simultaneous job delivery" do
    @batch = DiscourseAcademyRoles::StudentGroups::Preview.create(
      actor: @developer, mode: "groups", input_kind: "list", student_numbers: @registration.student_number, add_group_ids: [@target.id],
    )
    DiscourseAcademyRoles::StudentGroups::Confirmation.execute(actor: @developer, batch: @batch, selected_item_ids: @batch.items.pluck(:id))
    batch_id = @batch.id
    ready = Queue.new
    start = Queue.new
    ActiveRecord::Base.connection_handler.clear_active_connections!
    @threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          Jobs::AcademyStudentGroupBatch.new.execute(batch_id:)
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    @threads.each { |thread| raise "Concurrent membership task timed out" unless thread.join(25) }
    @threads.each(&:value)

    expect(@batch.reload.state).to eq("completed")
    expect(@target.reload.user_count).to eq(1)
    expect(GroupUser.where(group_id: @target.id, user_id: @registration.user_id).count).to eq(1)
    expect(GroupHistory.where(group_id: @target.id, action: GroupHistory.actions[:add_user_to_group], target_user_id: @registration.user_id).count).to eq(1)
  end
end
