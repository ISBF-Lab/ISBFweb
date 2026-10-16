# frozen_string_literal: true

RSpec.describe NestedReplies::Navigation do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  fab!(:op) { Fabricate(:post, topic: topic, user: user, post_number: 1) }

  let(:loader) { NestedReplies::TreeLoader.new(topic: topic, guardian: user.guardian) }
  let(:navigation) { described_class.new(loader) }

  before do
    SiteSetting.nested_replies_cap_nesting_depth = true
    SiteSetting.nested_replies_max_depth = 1
  end

  describe "#metadata" do
    it "returns discussion positions when model columns are enumerated" do
      Post.stubs(:enumerate_columns_in_select_statements).returns(true)
      Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)
      root = Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)

      expect(navigation.metadata(root_index: 2)).to include(
        root_count: 2,
        root_index: 2,
        root_post_id: root.id,
        root_post_number: root.post_number,
      )
    end

    it "returns an empty discussion position when the topic only has its opening post" do
      expect(navigation.metadata).to include(
        root_count: 0,
        root_index: 0,
        root_post_number: nil,
        root_post_id: nil,
        root_page: 0,
        reply_count: 0,
        child_page: 0,
      )
    end

    it "finds a deeply nested target across both root and descendant page boundaries" do
      roots = 21.times.map { Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1) }
      descendants = []
      parent = roots.last
      100.times do
        parent =
          Fabricate(:post, topic: topic, user: user, reply_to_post_number: parent.post_number)
        descendants << parent
      end

      expect(navigation.metadata(post_number: descendants.last.post_number)).to include(
        root_count: 21,
        root_index: 21,
        root_post_number: roots.last.post_number,
        root_post_id: roots.last.id,
        root_created_at: roots.last.created_at,
        root_page: 1,
        reply_count: 121,
        child_page: 1,
      )
      expect(navigation.metadata(post_number: descendants[49].post_number)[:child_page]).to eq(0)
      expect(navigation.metadata(post_number: descendants[50].post_number)[:child_page]).to eq(1)
      expect(navigation.metadata(post_number: roots.last.post_number)[:child_page]).to eq(0)
    end

    it "resolves a branch to its discussion instead of the most recent unrelated root" do
      root = Fabricate(:post, topic: topic, user: user, reply_to_post_number: nil)
      left = Fabricate(:post, topic: topic, user: user, reply_to_post_number: root.post_number)
      Fabricate(:post, topic: topic, user: user, reply_to_post_number: root.post_number)
      unrelated_root = Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)
      target = Fabricate(:post, topic: topic, user: user, reply_to_post_number: left.post_number)

      expect(navigation.metadata(post_number: target.post_number)).to include(
        root_count: 2,
        root_index: 1,
        root_post_id: root.id,
        root_post_number: root.post_number,
        child_page: 0,
      )
      expect(navigation.metadata(root_index: 2)[:root_post_id]).to eq(unrelated_root.id)
    end

    it "uses pin order before chronological order and bounds discussion index navigation" do
      roots = 3.times.map { Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1) }
      Fabricate(:nested_topic, topic: topic, pinned_post_ids: [roots.last.id, roots.first.id])

      expect(navigation.metadata(root_index: 1)).to include(
        root_index: 1,
        root_post_id: roots.last.id,
      )
      expect(navigation.metadata(post_number: roots.first.post_number)[:root_index]).to eq(2)
      expect(navigation.metadata(root_index: 0)[:root_post_id]).to eq(roots.last.id)
      expect(navigation.metadata(root_index: 99)[:root_post_id]).to eq(roots[1].id)
    end

    it "preserves a deleted discussion with a visible descendant and omits deleted leaves" do
      root = Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)
      target = Fabricate(:post, topic: topic, user: user, reply_to_post_number: root.post_number)
      deleted_leaf = Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)
      [root, deleted_leaf].each { |post| post.update!(deleted_at: Time.current) }

      expect(navigation.metadata(post_number: target.post_number)).to include(
        root_count: 1,
        root_index: 1,
        root_post_id: root.id,
        reply_count: 1,
      )
    end

    it "hides whispers from discussion counts and refuses to locate their targets" do
      SiteSetting.whispers_allowed_groups = "#{Group::AUTO_GROUPS[:staff]}"
      root = Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)
      whisper =
        Fabricate(
          :post,
          topic: topic,
          user: user,
          reply_to_post_number: 1,
          post_type: Post.types[:whisper],
        )

      expect(navigation.metadata).to include(root_count: 1, root_post_id: root.id, reply_count: 1)
      expect { navigation.metadata(post_number: whisper.post_number) }.to raise_error(
        Discourse::NotFound,
      )
    end

    it "rejects nonexistent targets and post numbers from another topic" do
      foreign_post = Fabricate(:post, post_number: 40)

      expect { navigation.metadata(post_number: foreign_post.post_number) }.to raise_error(
        Discourse::NotFound,
      )
      expect { navigation.metadata(post_number: 99_999) }.to raise_error(Discourse::NotFound)
    end

    it "rejects orphaned and cyclic targets instead of selecting an unrelated discussion" do
      root = Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)
      orphan = Fabricate(:post, topic: topic, user: user, reply_to_post_number: root.post_number)
      first = Fabricate(:post, topic: topic, user: user, reply_to_post_number: root.post_number)
      second = Fabricate(:post, topic: topic, user: user, reply_to_post_number: first.post_number)
      orphan.update_columns(reply_to_post_number: 99_999)
      first.update_columns(reply_to_post_number: second.post_number)

      [orphan, first, second].each do |target|
        expect { navigation.metadata(post_number: target.post_number) }.to raise_error(
          Discourse::NotFound,
        )
      end
    end

    context "when the viewer can read whispers" do
      fab!(:user, :admin)

      before { SiteSetting.whispers_allowed_groups = "#{Group::AUTO_GROUPS[:staff]}" }

      it "omits activity whispers when counting replies and selecting a child page" do
        root = Fabricate(:post, topic: topic, user: user, reply_to_post_number: 1)
        Fabricate(:post, topic: topic, user: user, reply_to_post_number: root.post_number)
        activity =
          Fabricate(
            :post,
            topic: topic,
            user: user,
            reply_to_post_number: root.post_number,
            post_type: Post.types[:whisper],
            action_code: "closed.enabled",
          )
        target =
          Fabricate(
            :post,
            topic: topic,
            user: user,
            reply_to_post_number: root.post_number,
            post_type: Post.types[:whisper],
          )

        stub_const(NestedReplies::TreeLoader, :CHILDREN_PER_PAGE, 2) do
          expect(navigation.metadata(post_number: target.post_number)).to include(
            root_count: 1,
            reply_count: 3,
            child_page: 0,
          )
        end
        expect { navigation.metadata(post_number: activity.post_number) }.to raise_error(
          Discourse::NotFound,
        )
      end
    end
  end
end
