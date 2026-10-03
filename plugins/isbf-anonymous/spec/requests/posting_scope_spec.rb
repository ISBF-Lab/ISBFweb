# frozen_string_literal: true

RSpec.describe "ISBF anonymous posting scope" do
  fab!(:user)
  fab!(:other_user, :user)
  fab!(:category)

  before do
    SiteSetting.allow_anonymous_mode = true
    SiteSetting.anonymous_posting_allowed_groups = "1|2|10"
    SiteSetting.isbf_anonymous_pool_size = 2
    sign_in(user)
  end

  [false, true].each do |pool_enabled|
    context "when the anonymous pool is #{pool_enabled ? "enabled" : "disabled"}" do
      before { SiteSetting.isbf_anonymous_pool_enabled = pool_enabled }

      it "rejects anonymous replies to unlisted topics before creating a post or reviewable" do
        topic = Fabricate(:topic, category: category, visible: false)
        SiteSetting.approve_post_count = 1

        expect do
          post "/posts.json",
               params: {
                 topic_id: topic.id,
                 raw: "An anonymous reply to an unlisted campus discussion.",
                 isbf_anonymous: "true",
               }
        end.not_to change { [Post.count, ReviewableQueuedPost.count] }

        expect(response.status).to eq(403)
      end

      it "keeps consecutive reply limits when the author switches back to their public identity" do
        SiteSetting.max_consecutive_replies = 2
        topic = Fabricate(:topic, category: category, user: other_user)
        Fabricate(:post, topic: topic, user: other_user)

        [
          "My first anonymous reply to this campus discussion.",
          "Following up with a second anonymous reply in sequence.",
        ].each do |raw|
          post "/posts.json", params: { topic_id: topic.id, raw: raw, isbf_anonymous: "true" }
          expect(response.status).to eq(200), response.body
        end

        expect do
          post "/posts.json",
               params: {
                 topic_id: topic.id,
                 raw: "A third consecutive reply using my public identity.",
               }
        end.not_to change { Post.count }

        expect(response.status).to eq(422)
        expect(response.parsed_body["errors"]).to include(I18n.t(:max_consecutive_replies, count: 2))
      end
    end
  end
end
