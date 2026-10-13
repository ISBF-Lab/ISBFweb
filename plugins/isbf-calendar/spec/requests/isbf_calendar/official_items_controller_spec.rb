# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::OfficialItemsController do
  fab!(:owner, :user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic_with_op, category:) }
  fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

  before do
    SiteSetting.academy_official_category = category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#add" do
    it "requires login" do
      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(403)
    end

    it "adds once and returns the same entry on repeated requests" do
      sign_in(owner)
      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(201)
      id = response.parsed_body.dig("entry", "id")

      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("entry", "id")).to eq(id)
      expect(IsbfCalendar::Entry.where(user: owner).count).to eq(1)
    end

    it "returns a conflict if the displayed official version has changed" do
      sign_in(owner)
      item.update!(
        starts_at: item.starts_at + 1.day,
        ends_at: item.ends_at + 1.day
      )
      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: 1
           }
      expect(response.status).to eq(409)
      expect(IsbfCalendar::Entry.where(user: owner)).to be_empty
    end

    it "rejects cancelled or inaccessible sources" do
      sign_in(owner)
      item.update!(cancelled: true)
      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(403)

      item.update!(cancelled: false)
      category.set_permissions(staff: :full)
      category.save!
      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(403)
      expect(IsbfCalendar::Entry.where(user: owner)).to be_empty
    end

    it "adds a precise deadline at the range's first instant" do
      sign_in(owner)
      item.update!(schedule_kind: "deadline", ends_at: item.starts_at)
      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(201)
      get "/isbf/api/entries.json",
          params: {
            from: item.starts_at.iso8601,
            to: (item.starts_at + 1.day).iso8601
          }
      expect(
        response.parsed_body["entries"].map { |entry| entry["source_item_id"] }
      ).to eq([item.id])
    end

    it "adds linked activity and registration deadline independently with their own time snapshots" do
      deadline = Fabricate(:isbf_calendar_official_deadline, topic:)
      item.update!(
        location: "Main hall",
        organizer: "Student office",
        registration_deadline: deadline
      )
      sign_in(owner)

      post "/isbf/api/official-items/#{item.id}/add.json",
           params: {
             revision: item.revision
           }
      expect(response.status).to eq(201), response.body
      activity_entry = response.parsed_body["entry"]
      expect(activity_entry).to include(
        "source_item_id" => item.id,
        "starts_at" => item.starts_at.iso8601,
        "schedule_kind" => "event"
      )
      expect(activity_entry["latest_source"]).to include(
        "location" => item.location,
        "organizer" => item.organizer,
        "registration_deadline_id" => deadline.id
      )
      expect(activity_entry.keys).not_to include(
        "location",
        "organizer",
        "registration_deadline_id"
      )
      expect(
        IsbfCalendar::Entry.where(user: owner).pluck(:source_item_id)
      ).to eq([item.id])

      post "/isbf/api/official-items/#{deadline.id}/add.json",
           params: {
             revision: deadline.revision
           }
      expect(response.status).to eq(201), response.body
      expect(response.parsed_body["entry"]).to include(
        "source_item_id" => deadline.id,
        "starts_at" => deadline.starts_at.iso8601,
        "ends_at" => deadline.starts_at.iso8601,
        "schedule_kind" => "deadline"
      )
      expect(
        IsbfCalendar::Entry.where(user: owner).pluck(:source_item_id)
      ).to contain_exactly(item.id, deadline.id)
    end
  end
end
