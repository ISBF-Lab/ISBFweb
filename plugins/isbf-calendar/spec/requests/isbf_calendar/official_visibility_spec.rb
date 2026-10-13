# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Official calendar visibility" do
  fab!(:admin)
  fab!(:user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic_with_op, user: admin, category:) }
  fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }
  fab!(:entry) do
    Fabricate(:isbf_calendar_official_entry, user:, source_item: item)
  end

  before do
    SiteSetting.academy_official_category = category.id
    SiteSetting.academy_roles_enabled = true
  end

  it "only marks the current user's imported item in the first post" do
    sign_in(user)
    get "/posts/#{topic.first_post.id}.json"
    expect(response.status).to eq(200)
    expect(
      response.parsed_body[IsbfCalendar::OFFICIAL_ITEMS_FIELD].first
    ).to include(
      "id" => item.id,
      "personal_entry_id" => entry.id,
      "timezone" => "Asia/Shanghai"
    )
    sign_in(admin)
    get "/posts/#{topic.first_post.id}.json"
    expect(
      response.parsed_body[IsbfCalendar::OFFICIAL_ITEMS_FIELD].first[
        "personal_entry_id"
      ]
    ).to be_nil
  end

  it "omits schedule metadata from replies and hidden first posts" do
    reply = Fabricate(:post, topic:)
    sign_in(user)
    get "/posts/#{reply.id}.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body).not_to have_key(
      IsbfCalendar::OFFICIAL_ITEMS_FIELD
    )
    topic.first_post.update!(hidden: true)
    get "/posts/#{topic.first_post.id}.json"
    expect(response.parsed_body).not_to have_key(
      IsbfCalendar::OFFICIAL_ITEMS_FIELD
    )
    post "/isbf/api/official-items/#{item.id}/add.json",
         params: {
           revision: item.revision
         }
    expect(response.status).to eq(403)
  end

  it "rejects time metadata on replies without changing the source" do
    reply = Fabricate(:post, topic:, user: admin)
    sign_in(admin)
    put "/posts/#{reply.id}.json",
        params: {
          post: {
            isbf_official_calendar_items: "[]"
          }
        }
    expect(response.status).to eq(400)
    expect(item.reload).to have_attributes(cancelled: false, revision: 1)
  end

  it "cancels source items when a topic is deleted and retains private records" do
    sign_in(admin)
    delete "/t/#{topic.id}.json"
    expect(response.status).to eq(200)
    expect(item.reload).to have_attributes(cancelled: true, revision: 2)
    expect(entry.reload).to have_attributes(
      title: "Campus briefing",
      accepted_revision: 1
    )
    sign_in(user)
    get "/isbf/api/entry-updates.json"
    expect(response.parsed_body["entries"].first).to include(
      "id" => entry.id,
      "cancelled" => true
    )
  end

  it "hides activity information and its linked registration deadline after access is revoked" do
    deadline = Fabricate(:isbf_calendar_official_deadline, topic:)
    item.update!(
      location: "Restricted hall",
      organizer: "Restricted office",
      registration_deadline: deadline
    )
    category.set_permissions(staff: :full)
    category.save!
    sign_in(user)

    get "/t/#{topic.id}.json"
    expect(response.status).to eq(404)

    get "/isbf/api/entries/#{entry.id}.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body["entry"]).to include(
      "latest_source" => nil,
      "source_unavailable" => true,
      "title" => entry.title
    )
    expect(response.body).not_to include(item.location, item.organizer)

    get "/latest.json"
    expect(response.status).to eq(200)
    expect(
      response.parsed_body.dig("topic_list", "topics").map { |data| data["id"] }
    ).not_to include(topic.id)
  end

  it "cancels linked activity and registration sources when the topic is deleted" do
    deadline = Fabricate(:isbf_calendar_official_deadline, topic:)
    activity =
      Fabricate(
        :isbf_calendar_official_item,
        topic:,
        registration_deadline: deadline
      )
    activity_entry =
      Fabricate(:isbf_calendar_official_entry, source_item: activity, user:)
    deadline_entry =
      Fabricate(:isbf_calendar_official_entry, source_item: deadline, user:)
    sign_in(admin)

    delete "/t/#{topic.id}.json"
    expect(response.status).to eq(200), response.body
    expect(activity.reload).to be_cancelled
    expect(deadline.reload).to be_cancelled
    expect(activity_entry.reload).to have_attributes(
      source_item_id: activity.id,
      accepted_revision: 1
    )
    expect(deadline_entry.reload).to have_attributes(
      source_item_id: deadline.id,
      accepted_revision: 1
    )
  end
end
