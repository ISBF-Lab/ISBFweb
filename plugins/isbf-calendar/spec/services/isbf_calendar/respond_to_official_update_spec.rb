# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::RespondToOfficialUpdate do
  describe described_class::Contract, type: :model do
    it { is_expected.to allow_values(1, 2, "3").for(:id) }
    it { is_expected.not_to allow_values(nil, 0, -1, "invalid").for(:id) }
    it { is_expected.to allow_values(1, 2, "3").for(:revision) }
    it { is_expected.not_to allow_values(nil, 0, -1, "invalid").for(:revision) }
    it { is_expected.to allow_values(true, false).for(:accept) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:owner, :user)
    fab!(:acting_user) { owner }
    fab!(:official_group, :group)
    fab!(:category)
    fab!(:topic) { Fabricate(:topic_with_op, category:) }
    fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }
    fab!(:entry) do
      Fabricate(
        :isbf_calendar_official_entry,
        source_item: item,
        user: owner,
        note: "My private note"
      )
    end

    let(:params) { { id: entry_id, revision:, accept: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:entry_id) { entry.id }
    let(:revision) { item.revision }
    let(:accept) { true }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = category.id
      SiteSetting.academy_roles_enabled = true
      item.update!(
        title: "Rescheduled briefing",
        starts_at: item.starts_at + 2.months,
        ends_at: item.ends_at + 2.months
      )
    end

    context "when the contract is invalid" do
      let(:entry_id) { 0 }

      it { is_expected.to fail_a_contract }
    end

    context "when the entry is missing" do
      let(:entry_id) { entry.id + 1 }

      it { is_expected.to fail_to_find_a_model(:entry) }
    end

    context "without a signed-in owner" do
      let(:dependencies) { { guardian: Guardian.new } }

      it "returns an ordinary missing entry result" do
        expect(result).to fail_to_find_a_model(:entry)
        expect(result["result.model.entry"].exception).to be_nil
      end
    end

    context "when the entry belongs to another user" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_to_find_a_model(:entry) }
    end

    context "when the entry was created manually" do
      fab!(:entry) { Fabricate(:isbf_calendar_entry, user: owner) }

      it { is_expected.to fail_to_find_a_model(:item) }
    end

    context "when accepting a cancelled source" do
      before { item.update!(cancelled: true) }

      it { is_expected.to fail_a_policy(:can_respond) }
    end

    context "when accepting a source in a private category" do
      before do
        category.set_permissions(staff: :full)
        category.save!
      end

      it { is_expected.to fail_a_policy(:can_respond) }
    end

    context "when accepting a hidden first post" do
      before { topic.first_post.update!(hidden: true) }

      it { is_expected.to fail_a_policy(:can_respond) }
    end

    context "when dismissing a source with revoked access" do
      let(:accept) { false }

      before do
        category.set_permissions(staff: :full)
        category.save!
      end

      it { is_expected.to fail_a_policy(:can_respond) }
    end

    context "when the source changes after review" do
      let(:revision) { item.revision - 1 }

      it "leaves the user's snapshot and acknowledgement intact" do
        original_snapshot =
          entry.attributes.slice(*IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS)

        expect(result).to fail_a_policy(:current_revision)
        expect(
          entry.reload.attributes.slice(
            *IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS
          )
        ).to eq(original_snapshot)
        expect(entry).to have_attributes(
          accepted_revision: 1,
          dismissed_revision: 0,
          note: "My private note"
        )
      end
    end

    context "when accepting the current source version" do
      it "updates official fields and preserves the private note" do
        expect(result).to run_successfully
        expect(
          result[:entry].reload.attributes.slice(
            *IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS
          )
        ).to eq(item.snapshot)
        expect(result[:entry]).to have_attributes(
          accepted_revision: item.revision,
          note: "My private note"
        )
        expect(result[:entry]).not_to be_needs_update
      end
    end

    context "when keeping the accepted snapshot" do
      let(:accept) { false }

      it "dismisses the current revision without changing the snapshot" do
        original_snapshot =
          entry.attributes.slice(*IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS)

        expect(result).to run_successfully
        expect(
          entry.reload.attributes.slice(
            *IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS
          )
        ).to eq(original_snapshot)
        expect(entry).to have_attributes(
          accepted_revision: 1,
          dismissed_revision: item.revision,
          note: "My private note"
        )
        expect(entry).not_to be_needs_update
      end

      it "shows a later revision as a new pending update" do
        expect(result).to run_successfully
        item.update!(title: "Another schedule change")

        expect(entry.reload).to be_needs_update
      end
    end

    context "when keeping a cancelled source record" do
      let(:accept) { false }

      before do
        item.update!(cancelled: true)
        category.set_permissions(staff: :full)
        category.save!
      end

      it "acknowledges cancellation and retains the personal note" do
        expect(result).to run_successfully
        expect(entry.reload).to have_attributes(
          source_item_id: item.id,
          accepted_revision: 1,
          dismissed_revision: item.revision,
          note: "My private note"
        )
        expect(entry).not_to be_needs_update
      end
    end
  end
end
