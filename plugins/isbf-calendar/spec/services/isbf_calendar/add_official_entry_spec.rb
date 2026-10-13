# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::AddOfficialEntry do
  describe described_class::Contract, type: :model do
    it { is_expected.to allow_values(1, 2, "3").for(:id) }
    it { is_expected.not_to allow_values(nil, 0, -1, "invalid").for(:id) }
    it { is_expected.to allow_values(1, 2, "3").for(:revision) }
    it { is_expected.not_to allow_values(nil, 0, -1, "invalid").for(:revision) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :user)
    fab!(:official_group, :group)
    fab!(:category)
    fab!(:topic) { Fabricate(:topic_with_op, category:) }
    fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

    let(:params) { { id: item_id, revision: } }
    let(:dependencies) { { guardian: acting_user.guardian } }
    let(:item_id) { item.id }
    let(:revision) { item.revision }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = category.id
      SiteSetting.academy_roles_enabled = true
    end

    context "when the contract is invalid" do
      let(:item_id) { 0 }

      it { is_expected.to fail_a_contract }
    end

    context "when the source is missing" do
      let(:item_id) { item.id + 1 }

      it { is_expected.to fail_to_find_a_model(:item) }
    end

    context "without a signed-in user" do
      let(:dependencies) { { guardian: Guardian.new } }

      it { is_expected.to fail_a_policy(:can_add) }
    end

    context "when the source is cancelled" do
      before { item.update!(cancelled: true) }

      it { is_expected.to fail_a_policy(:can_add) }
    end

    context "when the category has become private" do
      before do
        category.set_permissions(staff: :full)
        category.save!
      end

      it { is_expected.to fail_a_policy(:can_add) }
    end

    context "when the first post is hidden" do
      before { topic.first_post.update!(hidden: true) }

      it { is_expected.to fail_a_policy(:can_add) }
    end

    context "when the official topic is deleted" do
      before { topic.update!(deleted_at: Time.current) }

      it { is_expected.to fail_a_policy(:can_add) }
    end

    context "when the topic has left the official category" do
      before { topic.update!(category: Fabricate(:category)) }

      it { is_expected.to fail_a_policy(:can_add) }
    end

    context "when the reviewed source revision is stale" do
      let(:revision) { item.revision - 1 }

      before { item.update!(title: "A newer title") }

      it "rejects the stale revision before creating a record" do
        expect { result }.not_to change(IsbfCalendar::Entry, :count)
        expect(result).to fail_a_policy(:current_revision)
      end
    end

    context "when adding a visible official item" do
      it "creates the user's accepted snapshot" do
        expect { result }.to change(IsbfCalendar::Entry, :count).by(1)
        expect(result).to run_successfully
        expect(result[:created]).to eq(true)
        expect(result[:entry]).to have_attributes(
          user_id: acting_user.id,
          source_item_id: item.id,
          accepted_revision: item.revision,
          notified_revision: item.revision
        )
        expect(
          result[:entry].attributes.slice(
            *IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS
          )
        ).to eq(item.snapshot)
      end
    end

    context "when adding a point deadline" do
      before do
        item.update!(schedule_kind: "deadline", ends_at: item.starts_at)
      end

      it "preserves the exact deadline without adding a duration" do
        expect(result).to run_successfully
        expect(result[:entry]).to have_attributes(
          schedule_kind: "deadline",
          starts_at: item.starts_at,
          ends_at: item.starts_at,
          all_day: false
        )
      end
    end

    context "when adding an activity with a registration deadline and display information" do
      fab!(:deadline) { Fabricate(:isbf_calendar_official_deadline, topic:) }

      before do
        item.update!(
          location: "Main hall",
          organizer: "Student office",
          registration_deadline: deadline
        )
      end

      it "imports only the selected activity's existing time snapshot" do
        expect { result }.to change(IsbfCalendar::Entry, :count).by(1)
        expect(result).to run_successfully
        expect(
          result[:entry].attributes.slice(
            *IsbfCalendar::OfficialItem::SNAPSHOT_FIELDS
          )
        ).to eq(item.snapshot)
        expect(result[:entry]).to have_attributes(
          source_item_id: item.id,
          accepted_revision: 1
        )
        expect(IsbfCalendar::Entry.where(source_item: deadline)).to be_empty
      end
    end

    context "when the user has already added the source" do
      fab!(:entry) do
        Fabricate(
          :isbf_calendar_official_entry,
          source_item: item,
          user: acting_user,
          note: "Bring notes"
        )
      end

      before { item.update!(title: "A newer source title") }

      it "returns the existing snapshot and private note" do
        expect { result }.not_to change(IsbfCalendar::Entry, :count)
        expect(result).to run_successfully
        expect(result[:created]).to eq(false)
        expect(result[:entry]).to have_attributes(
          id: entry.id,
          title: entry.title,
          note: "Bring notes",
          accepted_revision: 1
        )
        expect(result[:entry]).to be_needs_update
      end
    end

    context "when another user has added the same source" do
      fab!(:entry) do
        Fabricate(:isbf_calendar_official_entry, source_item: item)
      end

      it "creates an independent personal snapshot" do
        expect { result }.to change(IsbfCalendar::Entry, :count).by(1)
        expect(result).to run_successfully
        expect(result[:entry].user).to eq(acting_user)
        expect(result[:entry].id).not_to eq(entry.id)
      end
    end
  end
end
