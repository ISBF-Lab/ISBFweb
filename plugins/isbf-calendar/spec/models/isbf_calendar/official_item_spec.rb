# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::OfficialItem do
  fab!(:user)
  fab!(:official_group, :group)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic_with_op, category:) }

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe ".attributes_from_payload" do
    subject(:attributes) { described_class.attributes_from_payload(payload) }

    let(:payload) do
      {
        title: "  Campus briefing  ",
        schedule_kind: "event",
        starts_at: "2026-10-20T09:00:00+08:00",
        ends_at: "2026-10-20T10:00:00+08:00",
        all_day: false
      }
    end

    it "accepts symbol keys and normalizes the snapshot fields" do
      expect(attributes).to eq(
        "title" => "Campus briefing",
        "schedule_kind" => "event",
        "starts_at" => Time.iso8601(payload[:starts_at]),
        "ends_at" => Time.iso8601(payload[:ends_at]),
        "all_day" => false
      )
    end

    it "omits source identifiers and unpublished control fields" do
      original = attributes
      payload.merge!(
        id: 99,
        topic_id: 100,
        cancelled: true,
        revision: 50,
        position: 10,
        registration_deadline_id: 20,
        registration_deadline_index: 1
      )

      expect(described_class.attributes_from_payload(payload)).to eq(original)
    end

    it "normalizes the optional activity information without adding missing fields" do
      expect(attributes.keys).not_to include("location", "organizer")

      payload.merge!(location: "  Main hall  ", organizer: "  Student office  ")
      expect(described_class.attributes_from_payload(payload)).to include(
        "location" => "Main hall",
        "organizer" => "Student office"
      )

      payload.merge!(location: "  ", organizer: nil)
      expect(described_class.attributes_from_payload(payload)).to include(
        "location" => "",
        "organizer" => ""
      )
    end

    context "with activity information of an invalid type" do
      let(:payload) { super().merge(location: ["Main hall"]) }

      it "rejects the malformed information" do
        expect { attributes }.to raise_error(ArgumentError)
      end
    end

    context "without an explicit timezone" do
      let(:payload) { super().merge(starts_at: "2026-10-20T09:00:00") }

      it "rejects the ambiguous instant" do
        expect { attributes }.to raise_error(ArgumentError)
      end
    end

    context "with an impossible calendar date" do
      let(:payload) { super().merge(starts_at: "2026-02-30T09:00:00+08:00") }

      it "rejects the date instead of normalizing it" do
        expect { attributes }.to raise_error(ArgumentError)
      end
    end

    context "with a valid leap day" do
      let(:payload) do
        super().merge(
          starts_at: "2028-02-29T09:00:00+08:00",
          ends_at: "2028-02-29T10:00:00+08:00"
        )
      end

      it "preserves the leap day" do
        expect(attributes["starts_at"]).to eq(Time.utc(2028, 2, 29, 1))
      end
    end
  end

  describe "#valid?" do
    subject(:item) do
      Fabricate.build(
        :isbf_calendar_official_item,
        topic:,
        schedule_kind:,
        starts_at:,
        ends_at:,
        all_day:,
        location:,
        organizer:,
        registration_deadline:
      )
    end

    let(:schedule_kind) { "event" }
    let(:starts_at) { Time.iso8601("2026-10-20T09:00:00+08:00") }
    let(:ends_at) { starts_at + 1.hour }
    let(:all_day) { false }
    let(:location) { nil }
    let(:organizer) { nil }
    let(:registration_deadline) { nil }

    it "accepts absent activity information" do
      expect(item).to be_valid
    end

    context "with activity information at the length limits" do
      let(:location) { "地" * 255 }
      let(:organizer) { "方" * 120 }

      it { is_expected.to be_valid }
    end

    context "with activity information above the length limits" do
      let(:location) { "地" * 256 }
      let(:organizer) { "方" * 121 }

      it "rejects the oversized fields" do
        expect(item).not_to be_valid
        expect(item.errors.attribute_names).to contain_exactly(
          :location,
          :organizer
        )
      end
    end

    context "with an active registration deadline in the same topic" do
      fab!(:deadline) { Fabricate(:isbf_calendar_official_deadline, topic:) }

      let(:registration_deadline) { deadline }

      it { is_expected.to be_valid }
    end

    context "with a registration deadline from another topic" do
      fab!(:deadline, :isbf_calendar_official_deadline)

      let(:registration_deadline) { deadline }

      it { is_expected.not_to be_valid }
    end

    context "with a cancelled registration deadline" do
      fab!(:deadline) do
        Fabricate(:isbf_calendar_official_deadline, topic:, cancelled: true)
      end

      let(:registration_deadline) { deadline }

      it { is_expected.not_to be_valid }
    end

    context "with an activity used as a registration deadline" do
      fab!(:other_activity) { Fabricate(:isbf_calendar_official_item, topic:) }

      let(:registration_deadline) { other_activity }

      it { is_expected.not_to be_valid }
    end

    context "with a deadline that owns another deadline" do
      fab!(:deadline) { Fabricate(:isbf_calendar_official_deadline, topic:) }

      let(:registration_deadline) { deadline }
      let(:schedule_kind) { "deadline" }
      let(:ends_at) { starts_at }

      it { is_expected.not_to be_valid }
    end

    context "with a point activity" do
      let(:ends_at) { starts_at }

      it { is_expected.to be_valid }
    end

    context "with a precise deadline" do
      let(:schedule_kind) { "deadline" }
      let(:ends_at) { starts_at }

      it { is_expected.to be_valid }
    end

    context "with a deadline that has a duration" do
      let(:schedule_kind) { "deadline" }

      it "rejects the range" do
        expect(item).not_to be_valid
        expect(item.errors[:ends_at]).to contain_exactly(
          I18n.t("isbf_calendar.invalid_time")
        )
      end
    end

    context "with an end before the start" do
      let(:ends_at) { starts_at - 1.minute }

      it { is_expected.not_to be_valid }
    end

    context "with an all-day Beijing deadline" do
      let(:schedule_kind) { "deadline" }
      let(:starts_at) { Time.utc(2026, 10, 19, 16) }
      let(:ends_at) { starts_at + 1.day }
      let(:all_day) { true }

      it { is_expected.to be_valid }
    end

    context "with an all-day deadline at UTC midnight" do
      let(:schedule_kind) { "deadline" }
      let(:starts_at) { Time.utc(2026, 10, 20) }
      let(:ends_at) { starts_at + 1.day }
      let(:all_day) { true }

      it "requires midnight in Beijing" do
        expect(item).not_to be_valid
        expect(item.errors[:ends_at]).to contain_exactly(
          I18n.t("isbf_calendar.invalid_time")
        )
      end
    end

    context "with an all-day deadline spanning several dates" do
      let(:schedule_kind) { "deadline" }
      let(:starts_at) { Time.utc(2026, 10, 19, 16) }
      let(:ends_at) { starts_at + 2.days }
      let(:all_day) { true }

      it { is_expected.not_to be_valid }
    end

    context "with an all-day activity spanning several dates" do
      let(:starts_at) { Time.utc(2026, 10, 19, 16) }
      let(:ends_at) { starts_at + 3.days }
      let(:all_day) { true }

      it { is_expected.to be_valid }
    end

    context "with an all-day point activity" do
      let(:starts_at) { Time.utc(2026, 10, 19, 16) }
      let(:ends_at) { starts_at }
      let(:all_day) { true }

      it { is_expected.not_to be_valid }
    end

    context "with a missing all-day choice" do
      let(:all_day) { nil }

      it { is_expected.not_to be_valid }
    end
  end

  describe "#update!" do
    fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }
    fab!(:entry) do
      Fabricate(
        :isbf_calendar_official_entry,
        source_item: item,
        user:,
        note: "My note"
      )
    end

    it "advances one revision for a meaningful edit and queues notice" do
      expect_enqueued_with(
        job: :isbf_calendar_notify_change,
        args: {
          item_id: item.id,
          revision: 2
        }
      ) do
        item.update!(
          title: "Rescheduled briefing",
          starts_at: item.starts_at + 1.day,
          ends_at: item.ends_at + 1.day
        )
      end

      expect(item.reload).to have_attributes(
        revision: 2,
        title: "Rescheduled briefing"
      )
      expect(entry.reload).to have_attributes(
        title: "Campus briefing",
        accepted_revision: 1,
        note: "My note"
      )
    end

    it "keeps the revision for position-only changes" do
      expect_not_enqueued_with(job: :isbf_calendar_notify_change) do
        item.update!(position: 1)
      end

      expect(item.reload).to have_attributes(position: 1, revision: 1)
    end

    it "keeps the revision for an unchanged snapshot" do
      expect_not_enqueued_with(job: :isbf_calendar_notify_change) do
        item.update!(item.snapshot)
      end

      expect(item.reload.revision).to eq(1)
    end

    it "updates display information without changing calendar snapshots or notifying subscribers" do
      deadline = Fabricate(:isbf_calendar_official_deadline, topic:)
      original_snapshot =
        entry.attributes.slice(*IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS)

      expect_not_enqueued_with(job: :isbf_calendar_notify_change) do
        item.update!(
          location: "Main hall",
          organizer: "Student office",
          registration_deadline: deadline
        )
      end

      expect(item.reload).to have_attributes(
        revision: 1,
        location: "Main hall",
        organizer: "Student office",
        registration_deadline_id: deadline.id
      )
      expect(
        entry.reload.attributes.slice(
          *IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS
        )
      ).to eq(original_snapshot)
      expect(entry).not_to be_needs_update
    end

    it "notifies cancellation while retaining subscribed entries" do
      expect_enqueued_with(
        job: :isbf_calendar_notify_change,
        args: {
          item_id: item.id,
          revision: 2
        }
      ) { item.update!(cancelled: true) }

      expect(item.reload).to have_attributes(cancelled: true, revision: 2)
      expect(entry.reload).to have_attributes(
        source_item_id: item.id,
        accepted_revision: 1,
        note: "My note"
      )
    end

    it "rolls back a source edit and its notice together" do
      expect_not_enqueued_with(job: :isbf_calendar_notify_change) do
        described_class.transaction do
          item.update!(title: "A rolled-back title")
          raise ActiveRecord::Rollback
        end
      end

      expect(item.reload).to have_attributes(
        title: "Campus briefing",
        revision: 1
      )
    end
  end

  describe "#visible_to?" do
    subject(:visible) { item.visible_to?(user.guardian) }

    fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

    it { is_expected.to eq(true) }

    context "when access to the category is revoked" do
      before do
        category.set_permissions(staff: :full)
        category.save!
      end

      it { is_expected.to eq(false) }
    end

    context "when the first post is hidden" do
      before { topic.first_post.update!(hidden: true) }

      it { is_expected.to eq(false) }
    end

    context "when the first post is deleted" do
      before { topic.first_post.update!(deleted_at: Time.current) }

      it { is_expected.to be_falsey }
    end

    context "when the topic is deleted" do
      before { topic.update!(deleted_at: Time.current) }

      it { is_expected.to eq(false) }
    end

    context "when the topic leaves the official category" do
      before { topic.update!(category: Fabricate(:category)) }

      it { is_expected.to be_falsey }
    end

    context "when the topic is a private message" do
      before do
        topic.update!(archetype: Archetype.private_message, category_id: nil)
      end

      it { is_expected.to be_falsey }
    end
  end
end
