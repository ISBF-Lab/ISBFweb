# frozen_string_literal: true

RSpec.describe PostsController do
  fab!(:admin)
  fab!(:member) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:verified_member) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:ordinary_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.flag_post_allowed_groups = "1|2|10"
    SiteSetting.personal_message_enabled_groups = "1|2|10"
    SiteSetting.auto_silence_fast_typers_on_first_post = false
    official_group.add(verified_member)
    official_category.set_permissions(
      { everyone: :create_post }.merge(official_group => :full)
    )
    ordinary_category.set_permissions(everyone: :full)
  end

  describe "#create" do
    it "lets a newly registered member post, report, and send a private message" do
      new_member = Fabricate(:user, refresh_auto_groups: true)
      reported_post = Fabricate(:post, user: admin)
      expect(new_member.reload.trust_level).to eq(0)
      sign_in(new_member)

      post "/posts.json",
           params: {
             title: "First ordinary discussion",
             raw: "A first message for the academy community",
             category: ordinary_category.id
           }
      expect(response.status).to eq(200)

      post "/post_actions.json",
           params: {
             id: reported_post.id,
             post_action_type_id: PostActionType.types[:inappropriate]
           }
      expect(response.status).to eq(200)

      post "/posts.json",
           params: {
             title: "A private question about the academy",
             raw: "Could you help with this private question?",
             archetype: Archetype.private_message,
             target_recipients: admin.username
           }
      expect(response.status).to eq(200)
    end

    it "does not cap a new member's replies on the first day or per topic" do
      SiteSetting.max_replies_in_first_day = 1
      SiteSetting.newuser_max_replies_per_topic = 1
      topic =
        Fabricate(:topic_with_op, user: admin, category: ordinary_category)
      sign_in(member)

      post "/posts.json",
           params: {
             topic_id: topic.id,
             raw: "My first reply today"
           }
      expect(response.status).to eq(200), response.body

      post "/posts.json",
           params: {
             topic_id: topic.id,
             raw: "My second reply today"
           }
      expect(response.status).to eq(200), response.body
    end

    it "requires official membership and identity for official topics" do
      title = "Academy news for students"
      sign_in(member)

      post "/posts.json",
           params: {
             title: title,
             raw: "A new announcement for members",
             category: official_category.id
           }

      expect(response.status).to be >= 400
      expect(Topic.where(title: title)).to be_empty

      sign_in(verified_member)
      post "/posts.json",
           params: {
             title: title,
             raw: "A new announcement for members",
             category: official_category.id,
             academy_official: true
           }

      expect(response.status).to eq(200), response.body
      topic = Topic.find_by!(title: title)
      first_post = topic.first_post
      expect(
        first_post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD]
      ).to eq(true)

      get "/t/#{topic.id}.json"
      expect(
        response.parsed_body.dig(
          "post_stream",
          "posts",
          0,
          "academy_official_post"
        )
      ).to eq(true)
    end

    it "allows ordinary replies in the official category and rejects official identity elsewhere" do
      topic = Fabricate(:topic, user: admin, category: official_category)
      sign_in(member)

      post "/posts.json",
           params: {
             topic_id: topic.id,
             raw: "A question about the announcement"
           }

      expect(response.status).to eq(200)
      expect(
        Post.last.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD]
      ).to be_nil

      post "/posts.json",
           params: {
             title: "Ordinary discussion",
             raw: "An ordinary discussion for members",
             category: ordinary_category.id,
             academy_official: true
           }

      expect(response.status).to be >= 400
      expect(Topic.where(title: "Ordinary discussion")).to be_empty
    end

    it "marks an official reply without changing ordinary replies" do
      topic = Fabricate(:topic, user: admin, category: official_category)
      sign_in(verified_member)

      post "/posts.json",
           params: {
             topic_id: topic.id,
             raw: "An official answer from the academy",
             academy_official: true
           }

      expect(response.status).to eq(200)
      expect(
        Post.last.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD]
      ).to eq(true)
    end
  end
end
