# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostsController do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:category)
  fab!(:ordinary_category, :category)

  before do
    SiteSetting.academy_official_category = category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.auto_silence_fast_typers_on_first_post = false
  end

  let(:items) do
    [
      {
        title: "Application deadline",
        schedule_kind: "deadline",
        starts_at: "2026-10-20T00:00:00+08:00",
        ends_at: "2026-10-21T00:00:00+08:00",
        all_day: true
      },
      {
        title: "Campus briefing",
        schedule_kind: "event",
        starts_at: "2026-10-22T09:00:00+08:00",
        ends_at: "2026-10-22T10:00:00+08:00",
        all_day: false
      }
    ]
  end

  describe "#create" do
    it "saves multiple time items together with the official first post" do
      sign_in(admin)
      post "/posts.json",
           params: {
             title: "Campus event announcement",
             raw: "A campus event announcement with application information.",
             category: category.id,
             academy_official: true,
             isbf_official_calendar_items: items.to_json
           }
      expect(response.status).to eq(200), response.body
      topic = Topic.find(response.parsed_body["topic_id"])
      expect(topic.isbf_official_calendar_items.map(&:title)).to eq(
        items.map { |data| data[:title] }
      )
      expect(topic.isbf_official_calendar_items.first.starts_at).to eq_time(
        Time.iso8601(items.first[:starts_at])
      )
    end

    it "returns activity information and its persisted registration deadline in official responses" do
      sign_in(admin)
      activity_items = items.deep_dup
      activity_items.last.merge!(
        location: "  Main hall  ",
        organizer: "  Student office  ",
        registration_deadline_index: 0
      )

      post "/posts.json",
           params: {
             title: "Campus briefing with registration",
             raw: "A campus briefing with a linked registration deadline.",
             category: category.id,
             academy_official: true,
             isbf_official_calendar_items: activity_items.to_json
           }
      expect(response.status).to eq(200), response.body
      topic = Topic.find(response.parsed_body["topic_id"])
      deadline, activity = topic.isbf_official_calendar_items.to_a
      expected_activity = {
        "id" => activity.id,
        "location" => "Main hall",
        "organizer" => "Student office",
        "registration_deadline_id" => deadline.id
      }

      get "/posts/#{topic.first_post.id}.json"
      expect(response.status).to eq(200)
      expect(
        response.parsed_body[IsbfCalendar::OFFICIAL_ITEMS_FIELD].last
      ).to include(expected_activity)

      get "/t/#{topic.id}.json"
      expect(response.status).to eq(200)
      expect(
        response.parsed_body[IsbfCalendar::OFFICIAL_ITEMS_FIELD].last
      ).to include(expected_activity)

      get "/latest.json"
      expect(response.status).to eq(200)
      listed_topic =
        response
          .parsed_body
          .dig("topic_list", "topics")
          .find { |data| data["id"] == topic.id }
      expect(listed_topic[IsbfCalendar::OFFICIAL_ITEMS_FIELD].last).to include(
        expected_activity
      )
    end

    it "rolls back the post and time items on invalid official input" do
      sign_in(admin)
      invalid = items.deep_dup
      invalid.last[:ends_at] = "2026-10-20T09:00:00+08:00"
      expect do
        post "/posts.json",
             params: {
               title: "Invalid campus announcement",
               raw: "This announcement has an invalid activity time.",
               category: category.id,
               academy_official: true,
               isbf_official_calendar_items: invalid.to_json
             }
      end.not_to change(IsbfCalendar::OfficialItem, :count)
      expect(response.status).to eq(400), response.body
      expect(Topic.where(title: "Invalid campus announcement")).to be_empty
    end

    it "rolls back an invalid registration link together with the official topic" do
      sign_in(admin)
      invalid = items.deep_dup
      invalid.last[:registration_deadline_index] = 99

      expect do
        post "/posts.json",
             params: {
               title: "Announcement with invalid registration",
               raw:
                 "This announcement points to a registration deadline that is missing.",
               category: category.id,
               academy_official: true,
               isbf_official_calendar_items: invalid.to_json
             }
      end.not_to change(IsbfCalendar::OfficialItem, :count)
      expect(response.status).to eq(400), response.body
      expect(
        Topic.where(title: "Announcement with invalid registration")
      ).to be_empty
    end

    it "rejects calendar payloads in ordinary posts" do
      sign_in(admin)
      post "/posts.json",
           params: {
             title: "An ordinary post with time items",
             raw: "A message in an ordinary category for testing permissions.",
             category: ordinary_category.id,
             isbf_official_calendar_items: items.to_json
           }
      expect(response.status).to eq(400), response.body
    end
  end

  describe "#update" do
    fab!(:topic) { Fabricate(:topic_with_op, user: admin, category:) }
    fab!(:item) { Fabricate(:isbf_calendar_official_item, topic:) }

    before { sign_in(admin) }

    it "updates time metadata without changing the body" do
      original_raw = topic.first_post.raw
      data =
        item.snapshot.merge(
          id: item.id,
          revision: item.revision,
          title: "Updated briefing"
        )
      put "/posts/#{topic.first_post.id}.json",
          params: {
            post: {
              isbf_official_calendar_items: [data].to_json
            }
          }
      expect(response.status).to eq(200), response.body
      expect(item.reload).to have_attributes(
        title: "Updated briefing",
        revision: 2
      )
      expect(topic.first_post.reload.raw).to eq(original_raw)
    end

    it "records a display information edit in the post revision without changing the calendar version" do
      SiteSetting.editing_grace_period = 0
      original_raw = topic.first_post.raw
      original_item =
        item.snapshot.as_json.merge(
          "id" => item.id,
          "location" => item.location,
          "organizer" => item.organizer,
          "registration_deadline_id" => nil
        )
      data =
        item.snapshot.merge(
          id: item.id,
          revision: item.revision,
          location: "Main hall",
          organizer: "Student office"
        )

      put "/posts/#{topic.first_post.id}.json",
          params: {
            post: {
              isbf_official_calendar_items: [data].to_json
            }
          }
      expect(response.status).to eq(200), response.body
      expect(item.reload).to have_attributes(
        location: "Main hall",
        organizer: "Student office",
        revision: 1
      )
      expect(topic.first_post.reload.raw).to eq(original_raw)
      before_items, after_items =
        topic.first_post.revisions.last.modifications[
          IsbfCalendar::OFFICIAL_ITEMS_FIELD
        ]
      expect(before_items).to eq([original_item])
      expect(after_items).to eq(
        [
          original_item.merge(
            "location" => "Main hall",
            "organizer" => "Student office"
          )
        ]
      )
    end

    it "rejects a nonpublisher editing activity information" do
      item.update!(location: "Original hall", organizer: "Original office")
      sign_in(member)
      data =
        item.snapshot.merge(
          id: item.id,
          revision: item.revision,
          location: "Unauthorized hall",
          organizer: "Unauthorized office"
        )

      put "/posts/#{topic.first_post.id}.json",
          params: {
            post: {
              isbf_official_calendar_items: [data].to_json
            }
          }
      expect(response.status).to eq(403), response.body
      expect(item.reload).to have_attributes(
        location: "Original hall",
        organizer: "Original office",
        revision: 1
      )
    end

    it "preserves items on ordinary edits and cancels them only when explicitly removed" do
      put "/posts/#{topic.first_post.id}.json",
          params: {
            post: {
              raw: "An updated announcement with the same time information."
            }
          }
      expect(response.status).to eq(200), response.body
      expect(item.reload).to have_attributes(cancelled: false, revision: 1)

      put "/posts/#{topic.first_post.id}.json",
          params: {
            post: {
              isbf_official_calendar_items: "[]"
            }
          }
      expect(response.status).to eq(200), response.body
      expect(item.reload).to have_attributes(cancelled: true, revision: 2)
    end
  end
end
