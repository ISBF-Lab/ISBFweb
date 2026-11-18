# frozen_string_literal: true

require_relative "support"

RSpec.describe DiscourseAi::ForumAssistant::Evidence do
  include_context "with a configured forum assistant"

  describe "#retrieve" do
    subject(:evidence) { described_class.new(user: member, decision: decision).retrieve }

    let(:decision) do
      DiscourseAi::ForumAssistant::QuestionClassifier::Decision.new(
        action: "allow",
        intent: intent,
        query: query,
        reason: "forum_question",
      )
    end
    let(:intent) { "forum" }
    let(:query) { "quartzprivacy" }

    before { SearchIndexer.enable }
    after { SearchIndexer.disable }

    it "returns visible regular posts and excludes private, hidden and deleted content" do
      visible = Fabricate(:post, raw: "Visible quartzprivacy documentation.")
      hidden = Fabricate(:post, raw: "Hidden quartzprivacy material.", hidden: true)
      deleted = Fabricate(:post, raw: "Deleted quartzprivacy material.", deleted_at: Time.current)
      unlisted =
        Fabricate(
          :post,
          raw: "Unlisted quartzprivacy material.",
          topic: Fabricate(:topic, visible: false),
        )
      private_message =
        Fabricate(
          :post,
          raw: "Private quartzprivacy material.",
          user: member,
          topic: Fabricate(:private_message_topic, user: member, recipient: other_member),
        )
      moderator_note =
        Fabricate(
          :post,
          raw: "Moderator quartzprivacy material.",
          post_type: Post.types[:moderator_action],
        )

      expect(evidence.references).to eq([{ kind: "post", id: visible.id }])
      expect(evidence.sources.to_json).not_to include(
        hidden.raw,
        deleted.raw,
        unlisted.raw,
        private_message.raw,
        moderator_note.raw,
      )
    end

    it "rechecks restricted-category membership for every retrieval" do
      group = Fabricate(:group)
      category = Fabricate(:category)
      category.set_permissions(group => :readonly)
      category.save!
      restricted =
        Fabricate(
          :post,
          topic: Fabricate(:topic, category: category),
          raw: "Restricted quartzprivacy material.",
        )

      expect(evidence.references).to eq([])

      group.add(member)
      allowed = described_class.new(user: User.find(member.id), decision: decision).retrieve
      expect(allowed.references).to eq([{ kind: "post", id: restricted.id }])

      group.remove(member)
      revoked = described_class.new(user: User.find(member.id), decision: decision).retrieve
      expect(revoked.sources).to eq([])
    end

    context "when a forum query includes generic discussion and link terms" do
      let(:query) { "quartzpilot 讨论 原帖链接" }

      it "finds the visible keyword match without exposing hidden or private posts or unrelated context matches" do
        visible = Fabricate(:post, raw: "Quartzpilot setup instructions.")
        hidden = Fabricate(:post, raw: "Hidden quartzpilot instructions.", hidden: true)
        group = Fabricate(:group)
        category = Fabricate(:category)
        category.set_permissions(group => :readonly)
        category.save!
        restricted =
          Fabricate(
            :post,
            topic: Fabricate(:topic, category: category),
            raw: "Restricted quartzpilot instructions.",
          )
        private_message =
          Fabricate(
            :post,
            user: member,
            topic: Fabricate(:private_message_topic, user: member, recipient: other_member),
            raw: "Private quartzpilot instructions.",
          )
        context_only = Fabricate(:post, raw: "论坛 帖子 讨论 原帖链接 help unrelated to the subject.")

        expect(evidence.references).to eq([{ kind: "post", id: visible.id }])
        expect(evidence.sources.first).to include(url: visible.relative_url, content: visible.raw)
        expect(evidence.sources.to_json).not_to include(
          hidden.raw,
          restricted.raw,
          private_message.raw,
          context_only.raw,
        )
      end
    end

    context "when a forum query contains more than three independent subject keywords" do
      let(:query) { "quartzfirst quartzsecond quartzthird quartzfourth quartzfifth" }

      it "limits keyword fallback results to three separate subject searches" do
        matching_posts =
          query.split.map { |keyword| Fabricate(:post, raw: "#{keyword} reference material.") }

        expect(evidence.references.length).to eq(3)
        expect(matching_posts.map(&:id)).to include(
          *evidence.references.map { |reference| reference[:id] },
        )
      end
    end

    context "when looking for forum help" do
      let(:intent) { "help" }
      let(:query) { "notifications" }

      it "uses only the current published guide, excluding drafts and withdrawn guides" do
        SiteSetting.isbf_guides_enabled = true
        guide = Fabricate(:published_isbf_guide)
        guide.draft_revision.update!(raw: "Unreleased notifications instructions.")
        draft = Fabricate(:isbf_guide)
        withdrawn = Fabricate(:published_isbf_guide)
        withdrawn.update!(published_revision: nil)

        expect(evidence.references).to eq([{ kind: "guide", id: guide.id }])
        expect(evidence.sources.first[:content]).to include("Enable forum messages")
        expect(evidence.sources.to_json).not_to include(guide.draft_revision.raw)
        expect(evidence.references.map { |reference| reference[:id] }).not_to include(
          draft.id,
          withdrawn.id,
        )
      end
    end

    context "when asking about the assistant's usage limits" do
      let(:intent) { "help" }
      let(:query) { "助手 额度" }

      it "uses authoritative current settings without exposing another account's usage or questions" do
        SiteSetting.ai_forum_assistant_daily_limit = 17
        SiteSetting.ai_forum_assistant_questions_per_minute = 2
        SiteSetting.ai_forum_assistant_timezone = "UTC"
        SiteSetting.ai_forum_assistant_cooldown_minutes = 45
        AiForumAssistantQuota.for_period(other_member.id).update!(used: 14)
        other_topic = Fabricate(:private_message_topic, user: other_member, recipient: bot_user)
        other_question =
          PostCreator.create!(
            other_member,
            topic_id: other_topic.id,
            raw: "A private assistant quota question for this other account.",
          )

        expect(evidence.references).to eq([{ kind: "assistant_help", id: 0 }])
        help = evidence.sources.first
        expect(help).to include(authority: "official", url: "/discourse-ai/ai-bot/conversations")
        expect(help[:content]).to include("17", "2", "UTC", "45")
        expect(help[:content]).not_to include(other_member.username, other_question.raw)
      end
    end

    context "when locating workbench resources" do
      fab!(:admin)
      fab!(:resource_category, :category)
      fab!(:library_category, :category)

      let(:intent) { "resources" }
      let(:query) { "quartzpilot" }

      before do
        SiteSetting.isbf_learning_enabled = true
        SiteSetting.isbf_learning_category_id = resource_category.id
        resource_category.set_permissions(trust_level_0: :full, staff: :full)
        resource_category.save!
      end

      it "returns authorized course metadata and links without private contributor fields or unrelated posts" do
        course = IsbfLearning::Courses.create(admin, name: "Quartzpilot", grade: 1)
        topic =
          Fabricate(
            :topic,
            user: admin,
            category: resource_category,
            title: "Quartzpilot lecture notes",
          )
        topic.custom_fields[IsbfLearning::COURSE_FIELD] = course["id"]
        topic.custom_fields[IsbfLearning::LINK_FIELD] = "https://example.org/quartzpilot-notes.pdf"
        topic.custom_fields[IsbfLearning::DESCRIPTION_FIELD] = "Quartzpilot revision notes."
        topic.custom_fields["isbf_learning_student_number"] = "student-private-field"
        topic.save_custom_fields
        Fabricate(
          :post,
          user: admin,
          topic: topic,
          raw: "[quartzpilot-notes.pdf](https://example.org/quartzpilot-notes.pdf)",
        )
        ordinary =
          Fabricate(:post, raw: "An unrelated quartzpilot discussion, not a course resource.")

        expect(evidence.references).to eq([{ kind: "resource", id: topic.id }])
        metadata = JSON.parse(evidence.sources.first[:content])
        expect(metadata).to include(
          "title" => topic.title,
          "description" => "Quartzpilot revision notes.",
          "links" => [topic.custom_fields[IsbfLearning::LINK_FIELD]],
        )
        expect(evidence.sources.first[:url]).to eq(topic.relative_url)
        expect(metadata.keys).not_to include("student_number", "contributor_user_id")
        expect(evidence.sources.to_json).not_to include(
          topic.custom_fields["isbf_learning_student_number"],
          ordinary.raw,
        )
      end

      it "returns resource-library metadata through its existing directory permission checks" do
        SiteSetting.isbf_library_enabled = true
        SiteSetting.isbf_library_category_id = library_category.id
        library_category.set_permissions(trust_level_0: :full, staff: :full)
        library_category.save!
        category =
          IsbfLibrary::Catalog.create(admin, kind: "category", name: "Quartzpilot references")
        group =
          IsbfLibrary::Catalog.create(
            admin,
            kind: "group",
            category_id: category["id"],
            name: "Quartzpilot links",
          )
        topic =
          Fabricate(
            :topic,
            user: admin,
            category: library_category,
            title: "Quartzpilot resource library",
          )
        topic.custom_fields[IsbfLibrary::GROUP_FIELD] = group["id"]
        topic.custom_fields[IsbfLibrary::LINK_FIELD] = "https://example.org/quartzpilot-library"
        topic.custom_fields[IsbfLibrary::DESCRIPTION_FIELD] = "Quartzpilot library introduction."
        topic.save_custom_fields
        Fabricate(:post, user: admin, topic: topic, raw: "Quartzpilot library reference.")

        expect(evidence.references).to eq([{ kind: "resource", id: topic.id }])
        expect(JSON.parse(evidence.sources.first[:content])).to include(
          "description" => "Quartzpilot library introduction.",
          "links" => [topic.custom_fields[IsbfLibrary::LINK_FIELD]],
        )
      end
    end

    it "caps the amount of retrieved source text" do
      10.times { Fabricate(:post, raw: "quartzprivacy " + "Length-limited source text. " * 300) }

      expect(evidence.sources.length).to be <= 8
      expect(evidence.sources.sum { |source| source[:content].length }).to be <= 12_000
    end
  end
end
