# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::Entry do
  fab!(:user)
  fab!(:item, :isbf_calendar_official_item)

  describe ".overlapping" do
    fab!(:spanning) do
      Fabricate(
        :isbf_calendar_entry,
        user:,
        starts_at: Time.utc(2026, 10, 19),
        ends_at: Time.utc(2026, 10, 21)
      )
    end
    fab!(:ending_at_from) do
      Fabricate(
        :isbf_calendar_entry,
        user:,
        starts_at: Time.utc(2026, 10, 19),
        ends_at: Time.utc(2026, 10, 20)
      )
    end
    fab!(:starting_at_to) do
      Fabricate(
        :isbf_calendar_entry,
        user:,
        starts_at: Time.utc(2026, 10, 21),
        ends_at: Time.utc(2026, 10, 22)
      )
    end
    fab!(:point_at_from) do
      Fabricate(
        :isbf_calendar_official_entry,
        user:,
        source_item: item,
        starts_at: Time.utc(2026, 10, 20),
        ends_at: Time.utc(2026, 10, 20)
      )
    end
    fab!(:point_at_to) do
      Fabricate(
        :isbf_calendar_official_entry,
        user:,
        source_item: Fabricate(:isbf_calendar_official_item),
        starts_at: Time.utc(2026, 10, 21),
        ends_at: Time.utc(2026, 10, 21)
      )
    end

    it "includes overlapping ranges and points at the lower boundary" do
      expect(
        described_class.overlapping(
          Time.utc(2026, 10, 20),
          Time.utc(2026, 10, 21)
        )
      ).to contain_exactly(spanning, point_at_from)
    end
  end

  describe ".pending_updates" do
    fab!(:pending) do
      Fabricate(:isbf_calendar_official_entry, user:, source_item: item)
    end
    fab!(:acknowledged) do
      Fabricate(
        :isbf_calendar_official_entry,
        user:,
        source_item: Fabricate(:isbf_calendar_official_item)
      )
    end
    fab!(:manual) { Fabricate(:isbf_calendar_entry, user:) }

    it "finds source revisions newer than either acknowledgement" do
      item.update!(title: "An updated source")
      acknowledged.source_item.update!(title: "An acknowledged update")
      acknowledged.update!(
        dismissed_revision: acknowledged.source_item.revision
      )

      expect(described_class.pending_updates).to contain_exactly(pending)
    end

    it "retains cancellation as a pending update" do
      item.update!(cancelled: true)

      expect(described_class.pending_updates).to contain_exactly(pending)
    end
  end

  describe "#needs_update?" do
    fab!(:entry) do
      Fabricate(:isbf_calendar_official_entry, user:, source_item: item)
    end

    it "clears a reviewed revision and prompts for later changes" do
      item.update!(title: "First revision")
      expect(entry.reload).to be_needs_update

      entry.update!(dismissed_revision: item.revision)
      expect(entry.reload).not_to be_needs_update

      item.update!(title: "Second revision")
      expect(entry.reload).to be_needs_update

      entry.update!(accepted_revision: item.revision)
      expect(entry.reload).not_to be_needs_update
    end

    it "returns no pending source for manually created entries" do
      expect(Fabricate(:isbf_calendar_entry, user:)).not_to be_needs_update
    end
  end

  describe "#valid?" do
    subject(:entry) do
      Fabricate.build(
        :isbf_calendar_entry,
        user:,
        source_item:,
        starts_at:,
        ends_at:,
        all_day:
      )
    end

    let(:source_item) { item }
    let(:starts_at) { item.starts_at }
    let(:ends_at) { starts_at }
    let(:all_day) { false }

    context "with an imported point activity" do
      it { is_expected.to be_valid }
    end

    context "with a manually created point activity" do
      let(:source_item) { nil }

      it { is_expected.not_to be_valid }
    end

    context "with an imported all-day point" do
      let(:all_day) { true }

      it { is_expected.not_to be_valid }
    end

    context "with an imported reversed range" do
      let(:ends_at) { starts_at - 1.minute }

      it { is_expected.not_to be_valid }
    end
  end

  describe "#save!" do
    fab!(:entry) do
      Fabricate(:isbf_calendar_official_entry, user:, source_item: item)
    end

    it "enforces one imported entry per user and source" do
      duplicate =
        Fabricate.build(:isbf_calendar_official_entry, user:, source_item: item)

      expect {
        described_class.transaction(requires_new: true) { duplicate.save! }
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows other users to import the same source" do
      other_entry = Fabricate(:isbf_calendar_official_entry, source_item: item)

      expect(other_entry).to be_persisted
      expect(described_class.where(source_item: item)).to contain_exactly(
        entry,
        other_entry
      )
    end

    it "allows multiple manually created personal entries" do
      expect do Fabricate.times(2, :isbf_calendar_entry, user:) end.to change {
        described_class.where(user:, source_item_id: nil).count
      }.by(2)
    end
  end
end
