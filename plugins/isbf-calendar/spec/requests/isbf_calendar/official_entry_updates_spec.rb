# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::EntriesController do
  fab!(:owner, :user)
  fab!(:other_user, :user)
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

  before do
    SiteSetting.academy_official_category = category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#show" do
    it "keeps personal records private" do
      sign_in(other_user)
      get "/isbf/api/entries/#{entry.id}.json"
      expect(response.status).to eq(404)
    end

    it "keeps the accepted snapshot and hides new information after access is revoked" do
      item.update!(title: "A restricted new title")
      category.set_permissions(staff: :full)
      category.save!
      sign_in(owner)
      get "/isbf/api/entries/#{entry.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["entry"]).to include(
        "title" => entry.title,
        "source_unavailable" => true,
        "latest_source" => nil
      )
      expect(response.body).not_to include(item.title)
    end
  end

  describe "#update" do
    before { sign_in(owner) }

    it "allows private notes but protects official fields" do
      patch "/isbf/api/entries/#{entry.id}.json",
            params: {
              entry: {
                note: "Bring a notebook"
              }
            }
      expect(response.status).to eq(200)
      expect(entry.reload.note).to eq("Bring a notebook")

      patch "/isbf/api/entries/#{entry.id}.json",
            params: {
              entry: {
                title: "My replacement title"
              }
            }
      expect(response.status).to eq(400)
      expect(entry.reload.title).to eq(item.title)
    end
  end

  describe "#updates" do
    it "returns pending changes across months without moving the personal entry" do
      original_start = entry.starts_at
      item.update!(
        starts_at: item.starts_at + 3.months,
        ends_at: item.ends_at + 3.months
      )
      sign_in(owner)
      get "/isbf/api/entry-updates.json"
      expect(response.parsed_body["entries"].map { |data| data["id"] }).to eq(
        [entry.id]
      )
      expect(entry.reload.starts_at).to eq_time(original_start)
    end

    it "marks a cancelled item while preserving the entry and note" do
      item.update!(cancelled: true)
      sign_in(owner)
      get "/isbf/api/entry-updates.json"
      expect(response.parsed_body["entries"].first).to include(
        "id" => entry.id,
        "cancelled" => true,
        "note" => entry.note
      )
      expect(IsbfCalendar::Entry.exists?(entry.id)).to eq(true)
    end
  end

  describe "#accept_update" do
    before { sign_in(owner) }

    it "copies the reviewed version and preserves private notes" do
      item.update!(
        starts_at: item.starts_at + 1.day,
        ends_at: item.ends_at + 1.day,
        title: "Rescheduled briefing"
      )
      post "/isbf/api/entries/#{entry.id}/accept-update.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(200)
      expect(entry.reload).to have_attributes(
        starts_at: item.starts_at,
        title: item.title,
        note: "My private note",
        accepted_revision: item.revision
      )
    end

    it "rejects a version changed after the user reviewed it" do
      item.update!(title: "Latest briefing")
      post "/isbf/api/entries/#{entry.id}/accept-update.json",
           params: {
             revision: 1
           }
      expect(response.status).to eq(409)
      expect(entry.reload.accepted_revision).to eq(1)
    end

    it "rejects another user's entry" do
      sign_in(other_user)
      post "/isbf/api/entries/#{entry.id}/accept-update.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(404)
    end
  end

  describe "#dismiss_update" do
    it "dismisses one version and shows later changes again" do
      sign_in(owner)
      item.update!(title: "First change")
      post "/isbf/api/entries/#{entry.id}/dismiss-update.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(204)
      expect(entry.reload.title).to eq("Campus briefing")
      get "/isbf/api/entry-updates.json"
      expect(response.parsed_body["entries"]).to eq([])

      item.update!(title: "Second change")
      get "/isbf/api/entry-updates.json"
      expect(response.parsed_body["entries"].map { |data| data["id"] }).to eq(
        [entry.id]
      )
    end
  end
end
