# frozen_string_literal: true

require "rails_helper"

RSpec.describe IsbfCalendar::EntriesController do
  fab!(:owner, :user)
  fab!(:other_user, :user)

  let(:entry_attributes) do
    {
      title: "图书馆自习",
      starts_at: "2026-10-02T09:00:00+08:00",
      ends_at: "2026-10-02T11:00:00+08:00",
      all_day: false,
      note: "二楼"
    }
  end

  it "requires login for personal entries" do
    get "/isbf/api/entries.json",
        params: {
          from: "2026-10-01T00:00:00Z",
          to: "2026-11-01T00:00:00Z"
        }
    expect(response.status).not_to eq(200)
  end

  it "returns only the signed-in user's entries" do
    IsbfCalendar::Entry.create!(entry_attributes.merge(user: other_user))
    own = IsbfCalendar::Entry.create!(entry_attributes.merge(user: owner))
    sign_in(owner)

    get "/isbf/api/entries.json",
        params: {
          from: "2026-10-01T00:00:00Z",
          to: "2026-11-01T00:00:00Z"
        }

    expect(response.status).to eq(200)
    expect(response.parsed_body["entries"].map { |entry| entry["id"] }).to eq(
      [own.id]
    )
  end

  it "does not let another user update or delete an entry" do
    entry =
      IsbfCalendar::Entry.create!(entry_attributes.merge(user: other_user))
    sign_in(owner)

    patch "/isbf/api/entries/#{entry.id}.json",
          params: {
            entry: entry_attributes.merge(title: "改动")
          }
    expect(response.status).to eq(404)
    delete "/isbf/api/entries/#{entry.id}.json"
    expect(response.status).to eq(404)
    expect(entry.reload.title).to eq("图书馆自习")
  end

  it "creates, updates and removes an owned entry" do
    sign_in(owner)
    post "/isbf/api/entries.json", params: { entry: entry_attributes }
    expect(response.status).to eq(201)
    id = response.parsed_body.dig("entry", "id")

    patch "/isbf/api/entries/#{id}.json", params: { entry: { title: "课程复习" } }
    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("entry", "title")).to eq("课程复习")

    delete "/isbf/api/entries/#{id}.json"
    expect(response.status).to eq(200)
    expect(IsbfCalendar::Entry.exists?(id)).to eq(false)
  end

  it "rejects an end time before the start time" do
    sign_in(owner)
    post "/isbf/api/entries.json",
         params: {
           entry: entry_attributes.merge(ends_at: "2026-10-02T08:00:00+08:00")
         }
    expect(response.status).not_to eq(201)
    expect(IsbfCalendar::Entry.count).to eq(0)
  end
end
