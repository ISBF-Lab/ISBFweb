# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jobs::IsbfCalendarNotifyChange do
  fab!(:user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic_with_op, category:) }
  fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }
  fab!(:entry) do
    Fabricate(:isbf_calendar_official_entry, source_item: item, user:)
  end

  before do
    SiteSetting.academy_official_category = category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#execute" do
    it "notifies only subscribers and deduplicates retries" do
      item.update!(title: "New briefing time")
      job = described_class.new
      2.times { job.execute(item_id: item.id, revision: item.revision) }
      notifications =
        Notification.where(notification_type: Notification.types[:custom])
      expect(notifications.pluck(:user_id)).to eq([user.id])
      expect(notifications.first.data_hash).to include(
        "entry_id" => entry.id,
        "revision" => item.revision
      )
    end

    it "ignores obsolete jobs and acknowledged versions" do
      item.update!(title: "First change")
      first_revision = item.revision
      item.update!(title: "Second change")
      described_class.new.execute(item_id: item.id, revision: first_revision)
      entry.update!(dismissed_revision: item.revision)
      described_class.new.execute(item_id: item.id, revision: item.revision)
      expect(
        Notification.where(notification_type: Notification.types[:custom])
      ).to be_empty
    end

    it "notifies cancellation without deleting the personal record" do
      item.update!(cancelled: true)
      described_class.new.execute(item_id: item.id, revision: item.revision)
      expect(Notification.where(user:).count).to eq(1)
      expect(entry.reload.title).to eq("Campus briefing")
    end

    it "withholds new information after access is revoked" do
      item.update!(title: "Private briefing")
      category.set_permissions(staff: :full)
      category.save!
      described_class.new.execute(item_id: item.id, revision: item.revision)
      expect(Notification.where(user:)).to be_empty
    end
  end
end
