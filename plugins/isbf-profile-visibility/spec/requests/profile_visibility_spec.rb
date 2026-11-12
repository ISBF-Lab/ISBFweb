# frozen_string_literal: true

RSpec.describe "ISBF profile visibility" do
  fab!(:owner) { Fabricate(:user, trust_level: 2, refresh_auto_groups: true) }
  fab!(:viewer) { Fabricate(:user, trust_level: 2, refresh_auto_groups: true) }
  fab!(:moderator)

  before do
    SiteSetting.isbf_profile_visibility_enabled = true
    owner.user_stat.update!(post_count: 1)
    owner.user_profile.update!(
      bio_raw: "A bio that only some people may read",
      location: "Somewhere quiet",
      website: "https://example.com/hidden-profile",
    )
  end

  def hide(*sections)
    sections.each { |section| owner.custom_fields[IsbfProfileVisibility::FIELDS[section]] = true }
    owner.save_custom_fields
  end

  describe "profile and user card" do
    it "omits the bio fields and lists the section when the bio is hidden" do
      hide(:bio)
      sign_in(viewer)

      get "/u/#{owner.username}.json"

      parsed = response.parsed_body["user"]
      expect(parsed.keys).not_to include("bio_raw", "bio_cooked", "location", "website")
      expect(parsed["isbf_hidden_profile_sections"]).to eq(["bio"])
      expect(parsed["profile_hidden"]).to be_blank
    end

    it "does not render a hidden bio for crawlers" do
      hide(:bio)

      get "/u/#{owner.username}", headers: { "User-Agent" => "Googlebot" }

      expect(response.status).to eq(200)
      expect(response.body).not_to include(owner.user_profile.bio_raw)
    end

    it "omits read time from the card and keeps the bio when the summary is hidden" do
      hide(:summary)
      sign_in(viewer)

      get "/u/#{owner.username}/card.json"

      parsed = response.parsed_body["user"]
      expect(parsed.keys).not_to include("time_read", "recent_time_read")
      expect(parsed["location"]).to eq(owner.user_profile.location)
    end

    it "omits the featured topic from the card when the bio is hidden" do
      owner.user_profile.update!(featured_topic: Fabricate(:topic))
      sign_in(viewer)

      get "/u/#{owner.username}/card.json"
      expect(response.parsed_body["user"].keys).to include("featured_topic", "bio_excerpt")

      hide(:bio)

      get "/u/#{owner.username}/card.json"
      expect(response.parsed_body["user"].keys).not_to include("featured_topic", "bio_excerpt")
    end

    it "returns the full profile and the saved choices to the owner" do
      hide(:bio, :activity)
      sign_in(owner)

      get "/u/#{owner.username}.json"

      parsed = response.parsed_body["user"]
      expect(parsed["bio_raw"]).to eq(owner.user_profile.bio_raw)
      expect(parsed["isbf_hidden_profile_sections"]).to eq([])
      expect(parsed["isbf_profile_visibility"]).to eq(
        "bio" => true,
        "summary" => false,
        "activity" => true,
      )
    end

    it "returns the full profile to staff without exposing the owner's choices to others" do
      hide(:bio, :summary, :activity)

      sign_in(moderator)
      get "/u/#{owner.username}.json"
      expect(response.parsed_body["user"]["bio_raw"]).to eq(owner.user_profile.bio_raw)
      expect(response.parsed_body["user"]["isbf_hidden_profile_sections"]).to eq([])

      sign_in(viewer)
      get "/u/#{owner.username}.json"
      expect(response.parsed_body["user"]).not_to have_key("isbf_profile_visibility")
    end
  end

  describe "saving" do
    it "lets the owner save the section choices with the profile" do
      sign_in(owner)

      put "/u/#{owner.username}.json",
          params: {
            custom_fields: {
              isbf_hide_profile_bio: true,
              isbf_hide_profile_summary: true,
              isbf_hide_profile_activity: false,
            },
          }

      expect(response.status).to eq(200)
      expect(IsbfProfileVisibility.choices(owner.reload)).to eq(
        bio: true,
        summary: true,
        activity: false,
      )
    end
  end

  describe "summary" do
    before { hide(:summary) }

    it "returns 404 to anonymous and other users" do
      get "/u/#{owner.username}/summary.json"
      expect(response.status).to eq(404)

      sign_in(viewer)
      get "/u/#{owner.username}/summary.json"
      expect(response.status).to eq(404)
    end

    it "returns the summary to the owner and to staff" do
      sign_in(owner)
      get "/u/#{owner.username}/summary.json"
      expect(response.status).to eq(200)

      sign_in(moderator)
      get "/u/#{owner.username}/summary.json"
      expect(response.status).to eq(200)
    end

    it "still serves the page so the client can move to a public section" do
      get "/u/#{owner.username}/summary"
      expect(response.status).to eq(200)
    end
  end

  it "stops reporting visible activity in a cached summary once activity is hidden" do
    sign_in(viewer)

    get "/u/#{owner.username}/summary.json"
    expect(response.parsed_body["user_summary"]["can_see_user_actions"]).to eq(true)

    hide(:activity)

    get "/u/#{owner.username}/summary.json"
    expect(response.parsed_body["user_summary"]["can_see_user_actions"]).to eq(false)
  end

  describe "activity" do
    fab!(:topic) { Fabricate(:topic, user: owner) }

    before { Fabricate(:post, topic: topic, user: owner) }

    it "returns every activity list to other users while it is public" do
      get "/user_actions.json", params: { username: owner.username }
      expect(response.status).to eq(200)

      get "/topics/created-by/#{owner.username}.json"
      expect(response.status).to eq(200)

      get "/u/#{owner.username}/activity.rss"
      expect(response.status).to eq(200)
    end

    it "returns 404 for every activity list when the activity section is hidden" do
      hide(:activity)

      [
        "/user_actions.json?username=#{owner.username}",
        "/topics/created-by/#{owner.username}.json",
        "/u/#{owner.username}/activity.json",
        "/u/#{owner.username}/activity.rss",
        "/u/#{owner.username}/activity/topics.rss",
      ].each do |path|
        get path
        expect(response.status).to eq(404), path
      end
    end

    it "keeps activity lists for the owner and staff" do
      hide(:activity)

      [owner, moderator].each do |privileged|
        sign_in(privileged)

        get "/topics/created-by/#{owner.username}.json"
        expect(response.status).to eq(200)

        get "/u/#{owner.username}/activity.json"
        expect(response.status).to eq(200)
      end
    end

    it "closes the voted-by list when activity or the whole profile is hidden" do
      skip "Topic voting is not loaded" unless defined?(DiscourseTopicVoting)
      SiteSetting.topic_voting_enabled = true
      SiteSetting.topic_voting_show_votes_on_profile = true

      get "/topics/voted-by/#{owner.username}.json"
      expect(response.status).to eq(200)

      hide(:activity)
      get "/topics/voted-by/#{owner.username}.json"
      expect(response.status).to eq(404)

      owner.custom_fields[IsbfProfileVisibility::FIELDS[:activity]] = false
      owner.save_custom_fields
      owner.user_option.update!(hide_profile: true)
      get "/topics/voted-by/#{owner.username}.json"
      expect(response.status).to eq(404)
    end
  end

  describe "local user previews" do
    it "leaves out the bio, location and website when the bio is hidden" do
      profile = owner.user_profile
      preview = -> do
        Oneboxer.preview("#{Discourse.base_url}/u/#{owner.username}", user_id: viewer.id).to_s
      end

      expect(preview.call).to include(profile.location, profile.website)

      hide(:bio)
      html = preview.call

      expect(html).to include(owner.username)
      expect(html).not_to include(profile.location)
      expect(html).not_to include(profile.website)
      expect(html).not_to include(profile.bio_raw)
    end
  end

  describe "MCP user tools" do
    let(:request_context) do
      instance_double(DiscourseMcp::RequestContext, guardian: viewer.guardian, user: viewer)
    end

    it "leaves out a hidden bio" do
      hide(:bio)

      result =
        DiscourseMcp::Tools::GetUser.call(
          arguments: {
            "username" => owner.username,
          },
          request_context:,
        )

      expect(result.dig(:structuredContent, :bio)).to eq("")
      expect(result.dig(:content, 0, :text)).not_to include(owner.user_profile.bio_raw)
    end

    it "does not expose a hidden summary" do
      hide(:summary)

      expect do
        DiscourseMcp::Tools::GetUserSummary.call(
          arguments: {
            "username" => owner.username,
          },
          request_context:,
        )
      end.to raise_error(DiscourseMcp::ToolError, I18n.t("mcp.errors.user_not_found"))
    end
  end
end
