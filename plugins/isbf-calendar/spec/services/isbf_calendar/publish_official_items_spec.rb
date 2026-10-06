# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::PublishOfficialItems do
  describe described_class::Contract, type: :model do
    it do
      is_expected.to allow_values([], [{}], Array.new(20) { {} }).for(:items)
    end

    it do
      is_expected.not_to allow_values(
        nil,
        {},
        ["invalid"],
        Array.new(21) { {} }
      ).for(:items)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:official_group, :group)
    fab!(:acting_user, :admin)
    fab!(:category)
    fab!(:topic) { Fabricate(:topic_with_op, category:, user: acting_user) }

    let(:params) { { items: } }
    let(:dependencies) do
      { topic: publishing_topic, guardian: acting_user.guardian }
    end
    let(:publishing_topic) { topic }
    let(:items) do
      [
        {
          title: "Application deadline",
          schedule_kind: "deadline",
          starts_at: "2026-10-20T00:00:00+08:00",
          ends_at: "2026-10-21T00:00:00+08:00",
          all_day: true
        }
      ]
    end

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = category.id
      SiteSetting.academy_roles_enabled = true
      topic.first_post.update!(user: acting_user)
    end

    context "when the contract is invalid" do
      let(:items) { nil }

      it { is_expected.to fail_a_contract }
    end

    context "when the category is ordinary" do
      before { topic.update!(category: Fabricate(:category)) }

      it { is_expected.to fail_a_policy(:can_publish) }
    end

    context "when the official category is disabled" do
      before { SiteSetting.academy_roles_enabled = false }

      it { is_expected.to fail_a_policy(:can_publish) }
    end

    context "when the topic is a private message" do
      before do
        topic.update!(archetype: Archetype.private_message, category_id: nil)
      end

      it { is_expected.to fail_a_policy(:can_publish) }
    end

    context "without an official publisher role" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_publish) }
    end

    context "without a signed-in publisher" do
      let(:dependencies) { { topic: publishing_topic, guardian: Guardian.new } }

      it { is_expected.to fail_a_policy(:can_publish) }
    end

    context "with an official publisher who owns the first post" do
      fab!(:acting_user) { Fabricate(:user, group_ids: [official_group.id]) }

      before do
        SiteSetting.academy_official_group = official_group.id
        SiteSetting.edit_post_allowed_groups = official_group.id.to_s
      end

      it { is_expected.to run_successfully }
    end

    context "with a publisher who cannot edit the first post" do
      fab!(:acting_user) { Fabricate(:user, group_ids: [official_group.id]) }
      fab!(:author, :user)

      before do
        SiteSetting.academy_official_group = official_group.id
        SiteSetting.edit_post_allowed_groups = official_group.id.to_s
        topic.first_post.update!(user: author)
      end

      it { is_expected.to fail_a_policy(:can_publish) }
    end

    context "when an existing source belongs to another topic" do
      fab!(:other_item, :isbf_calendar_official_item)

      let(:items) do
        [
          other_item.snapshot.as_json.merge(
            id: other_item.id,
            revision: other_item.revision
          )
        ]
      end

      it { is_expected.to fail_with_exception(ArgumentError) }
    end

    context "when a source ID is supplied twice" do
      fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

      let(:items) do
        Array.new(2) do
          item.snapshot.as_json.merge(id: item.id, revision: item.revision)
        end
      end

      it { is_expected.to fail_with_exception(ArgumentError) }
    end

    context "when a source ID is a string" do
      fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

      let(:items) do
        [item.snapshot.as_json.merge(id: item.id.to_s, revision: item.revision)]
      end

      it { is_expected.to fail_with_exception(ArgumentError) }
    end

    context "when the supplied revision is stale" do
      fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

      let(:items) { [item.snapshot.as_json.merge(id: item.id, revision: 1)] }

      before { item.update!(title: "A newer version") }

      it { is_expected.to fail_with_exception(ArgumentError) }
    end

    context "when a removed source ID is reused" do
      fab!(:item) do
        Fabricate(:isbf_calendar_official_item, topic:, cancelled: true)
      end

      let(:items) do
        [item.snapshot.as_json.merge(id: item.id, revision: item.revision)]
      end

      it { is_expected.to fail_with_exception(ArgumentError) }
    end

    context "when the time lacks an explicit offset" do
      let(:items) { [super().first.merge(starts_at: "2026-10-20T00:00:00")] }

      it { is_expected.to fail_with_exception(ArgumentError) }
    end

    context "when the source time range is invalid" do
      let(:items) do
        [super().first.merge(ends_at: "2026-10-19T00:00:00+08:00")]
      end

      it "halts without creating a source" do
        expect { result }.not_to change(IsbfCalendar::OfficialItem, :count)
        expect(result).to fail_a_step(:prepare_items)
      end
    end

    context "when a later time item is invalid" do
      fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

      let(:items) do
        [
          item.snapshot.as_json.merge(
            id: item.id,
            revision: item.revision,
            title: "Uncommitted change"
          ),
          {
            title: "Invalid activity",
            schedule_kind: "event",
            starts_at: "2026-10-22T10:00:00+08:00",
            ends_at: "2026-10-22T09:00:00+08:00",
            all_day: false
          }
        ]
      end

      it "preserves every previously published source" do
        original_snapshot = item.snapshot
        expect { result }.not_to change(IsbfCalendar::OfficialItem, :count)
        expect(result).to fail_a_step(:prepare_items)
        expect(item.reload.snapshot).to eq(original_snapshot)
        expect(item.revision).to eq(1)
      end
    end

    context "when publishing new time items" do
      it "creates the structured Beijing deadline" do
        expect { result }.to change(IsbfCalendar::OfficialItem, :count).by(1)
        expect(result).to run_successfully
        expect(
          topic.isbf_official_calendar_items.reload.sole
        ).to have_attributes(
          title: items.first[:title],
          schedule_kind: "deadline",
          all_day: true,
          starts_at: Time.iso8601(items.first[:starts_at]),
          ends_at: Time.iso8601(items.first[:ends_at]),
          revision: 1
        )
      end
    end

    context "when creating an unsaved official topic" do
      let(:publishing_topic) do
        Fabricate.build(:topic, category:, user: acting_user)
      end

      it "saves its sources together with the topic" do
        expect { result }.not_to change(IsbfCalendar::OfficialItem, :count)
        expect(result).to run_successfully

        expect { publishing_topic.save! }.to change(
          IsbfCalendar::OfficialItem,
          :count
        ).by(1)
        expect(
          publishing_topic.isbf_official_calendar_items.sole
        ).to be_persisted
      end
    end

    context "when reordering existing time items" do
      fab!(:first_item) do
        Fabricate(:isbf_calendar_official_item, topic:, position: 0)
      end
      fab!(:second_item) do
        Fabricate(:isbf_calendar_official_item, topic:, position: 1)
      end

      let(:items) do
        [second_item, first_item].map do |item|
          item.snapshot.as_json.merge(id: item.id, revision: item.revision)
        end
      end

      it "preserves source identities and revisions" do
        expect { result }.not_to change(IsbfCalendar::OfficialItem, :count)
        expect(result).to run_successfully
        expect(
          topic.isbf_official_calendar_items.reload.pluck(:id, :revision)
        ).to eq([[second_item.id, 1], [first_item.id, 1]])
      end
    end

    context "when changing an existing time item" do
      fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }
      fab!(:entry) do
        Fabricate(
          :isbf_calendar_official_entry,
          source_item: item,
          note: "My note"
        )
      end

      let(:items) do
        [
          item.snapshot.as_json.merge(
            id: item.id,
            revision: item.revision,
            title: "Updated briefing"
          )
        ]
      end

      it "keeps the stable source and the accepted personal snapshot" do
        original_snapshot =
          entry.attributes.slice(*IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS)

        expect { result }.not_to change(IsbfCalendar::OfficialItem, :count)
        expect(result).to run_successfully
        expect(item.reload).to have_attributes(
          id: item.id,
          revision: 2,
          title: "Updated briefing"
        )
        expect(
          entry.reload.attributes.slice(
            *IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS
          )
        ).to eq(original_snapshot)
        expect(entry).to have_attributes(note: "My note", accepted_revision: 1)
      end
    end

    context "when the publisher removes every time item" do
      fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }
      fab!(:entry) do
        Fabricate(
          :isbf_calendar_official_entry,
          source_item: item,
          note: "My note"
        )
      end

      let(:items) { [] }

      it "cancels the source and retains the personal record" do
        expect { result }.not_to change(IsbfCalendar::OfficialItem, :count)
        expect(result).to run_successfully
        expect(item.reload).to have_attributes(cancelled: true, revision: 2)
        expect(entry.reload).to have_attributes(
          source_item_id: item.id,
          note: "My note",
          accepted_revision: 1
        )
      end
    end
  end
end
