# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::Metrics do
  include ActivityLevelsSpecHelpers

  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  let(:level) { activity_tier(identifier: "reader", conditions: [], period_days: 7) }
  let(:metrics) { described_class.new(member, now: Time.current) }

  before do
    freeze_time(Time.utc(2030, 1, 12, 12))
    DiscourseAcademyRoles::ActivityLevels::Current.reset
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  after { DiscourseAcademyRoles::ActivityLevels::Current.reset }

  describe "#condition_met?" do
    it "checks cumulative visit, reading and like boundaries using their configured thresholds" do
      member.user_stat.update!(
        days_visited: 3,
        topics_entered: 5,
        posts_read_count: 30,
        time_read: 600,
        likes_given: 2,
        likes_received: 3,
      )
      thresholds = {
        "days_visited" => 3,
        "topics_entered" => 5,
        "posts_read" => 30,
        "time_read_minutes" => 10,
        "likes_given" => 2,
        "likes_received" => 3,
      }

      thresholds.each do |metric, threshold|
        expect(metrics.condition_met?(activity_condition(metric, threshold), level)).to eq(true)
        expect(metrics.condition_met?(activity_condition(metric, threshold + 1), level)).to eq(
          false,
        )
      end
    end

    it "uses the selected recent window while retaining independent historical reading totals" do
      Fabricate(
        :user_visit,
        user: member,
        visited_at: 2.days.ago.to_date,
        posts_read: 4,
        time_read: 120,
      )
      Fabricate(
        :user_visit,
        user: member,
        visited_at: 10.days.ago.to_date,
        posts_read: 8,
        time_read: 600,
      )
      Fabricate(
        :user_visit,
        user: member,
        visited_at: 1.day.ago.to_date,
        posts_read: 0,
        time_read: 0,
      )
      public_topic = Fabricate(:topic_with_op)
      old_topic = Fabricate(:topic_with_op, created_at: 20.days.ago)
      TopicViewItem.add(public_topic.id, "127.0.0.1", member.id, 2.days.ago.to_date, true)
      TopicViewItem.add(old_topic.id, "127.0.0.1", member.id, 10.days.ago.to_date, true)

      recent = {
        "days_visited" => 1,
        "topics_entered" => 1,
        "posts_read" => 4,
        "time_read_minutes" => 2,
      }
      recent.each do |metric, threshold|
        expect(
          metrics.condition_met?(activity_condition(metric, threshold, period: "recent"), level),
        ).to eq(true)
        expect(
          metrics.condition_met?(
            activity_condition(metric, threshold + 1, period: "recent"),
            level,
          ),
        ).to eq(false)
      end
      expect(metrics.condition_met?(activity_condition("topics_viewed_all_time", 2), level)).to eq(
        true,
      )
      expect(metrics.condition_met?(activity_condition("posts_read_all_time", 12), level)).to eq(
        true,
      )
    end

    it "requires enough elapsed account age as well as recorded reading minutes" do
      member.update!(created_at: 5.minutes.ago)
      member.user_stat.update!(time_read: 600)
      condition = activity_condition("time_read_minutes", 10)

      expect(metrics.condition_met?(condition, level)).to eq(false)

      freeze_time(10.minutes.from_now)
      expect(described_class.new(member, now: Time.current).condition_met?(condition, level)).to eq(
        true,
      )
    end

    it "counts different other-authored public topics rather than repeated, own or private replies" do
      other_topic = Fabricate(:topic_with_op)
      own_topic = Fabricate(:topic_with_op, user: member)
      private_topic = Fabricate(:private_message_topic)
      older_topic = Fabricate(:topic_with_op)
      Fabricate(:post, user: member, topic: other_topic)
      Fabricate(:post, user: member, topic: other_topic)
      Fabricate(:post, user: member, topic: own_topic)
      Fabricate(:post, user: member, topic: private_topic)
      Fabricate(:post, user: member, topic: older_topic, created_at: 10.days.ago)

      expect(
        metrics.condition_met?(activity_condition("topics_replied_to", 1, period: "recent"), level),
      ).to eq(true)
      expect(
        metrics.condition_met?(activity_condition("topics_replied_to", 2, period: "recent"), level),
      ).to eq(false)
      expect(metrics.condition_met?(activity_condition("topics_replied_to", 2), level)).to eq(true)
    end

    it "counts recent public likes, different sources and dates while excluding private messages" do
      topic = Fabricate(:topic_with_op)
      post = topic.first_post
      private_topic = Fabricate(:private_message_topic)
      private_post = Fabricate(:post, topic: private_topic)
      older_post = Fabricate(:post, topic: topic, created_at: 10.days.ago)
      first_liker = Fabricate(:user)
      second_liker = Fabricate(:user)
      Fabricate(
        :user_action,
        user: member,
        action_type: UserAction::LIKE,
        target_topic_id: topic.id,
        target_post_id: post.id,
        created_at: 2.days.ago,
      )
      Fabricate(
        :user_action,
        user: member,
        action_type: UserAction::LIKE,
        target_topic_id: private_topic.id,
        target_post_id: private_post.id,
        created_at: 2.days.ago,
      )
      Fabricate(
        :user_action,
        user: member,
        action_type: UserAction::WAS_LIKED,
        target_topic_id: topic.id,
        target_post_id: post.id,
        acting_user_id: first_liker.id,
        created_at: 1.day.ago,
      )
      Fabricate(
        :user_action,
        user: member,
        action_type: UserAction::WAS_LIKED,
        target_topic_id: topic.id,
        target_post_id: post.id,
        acting_user_id: second_liker.id,
        created_at: 2.days.ago,
      )
      Fabricate(
        :user_action,
        user: member,
        action_type: UserAction::WAS_LIKED,
        target_topic_id: private_topic.id,
        target_post_id: private_post.id,
        acting_user_id: first_liker.id,
        created_at: 3.days.ago,
      )
      Fabricate(
        :user_action,
        user: member,
        action_type: UserAction::WAS_LIKED,
        target_topic_id: topic.id,
        target_post_id: older_post.id,
        acting_user_id: first_liker.id,
        created_at: 10.days.ago,
      )

      thresholds = {
        "likes_given" => 1,
        "likes_received" => 2,
        "likes_received_users" => 2,
        "likes_received_days" => 2,
      }
      thresholds.each do |metric, threshold|
        expect(
          metrics.condition_met?(activity_condition(metric, threshold, period: "recent"), level),
        ).to eq(true)
        expect(
          metrics.condition_met?(
            activity_condition(metric, threshold + 1, period: "recent"),
            level,
          ),
        ).to eq(false)
      end
    end

    it "uses rounded percentage requirements and their configured caps" do
      topics = 4.times.map { Fabricate(:topic_with_op) }
      TopicViewItem.add(topics.first.id, "127.0.0.1", member.id, 1.day.ago.to_date, true)
      Fabricate(:user_visit, user: member, visited_at: 1.day.ago.to_date, posts_read: 1)

      %w[topics_viewed_percent posts_read_percent].each do |metric|
        expect(
          metrics.condition_met?(activity_condition(metric, 25, period: "recent", cap: 100), level),
        ).to eq(true)
        expect(
          metrics.condition_met?(activity_condition(metric, 50, period: "recent", cap: 100), level),
        ).to eq(false)
        expect(
          metrics.condition_met?(activity_condition(metric, 50, period: "recent", cap: 1), level),
        ).to eq(true)
      end
    end

    it "counts confirmed reports from other users and applies maxima without a buffer" do
      topic = Fabricate(:topic_with_op, user: member)
      post = Fabricate(:post, topic: topic, user: member, spam_count: 1)
      reporter = Fabricate(:user)
      Fabricate(
        :post_action,
        post: post,
        user: reporter,
        post_action_type_id: PostActionType.types[:spam],
        agreed_at: Time.current,
      )
      Fabricate(
        :post_action,
        post: post,
        user: member,
        post_action_type_id: PostActionType.types[:inappropriate],
        agreed_at: Time.current,
      )
      Fabricate(
        :post_action,
        post: post,
        post_action_type_id: PostActionType.types[:inappropriate],
        agreed_at: nil,
      )

      %w[flagged_posts flagged_by_users].each do |metric|
        expect(
          metrics.condition_met?(activity_condition(metric, 1, period: "recent"), level),
        ).to eq(true)
        expect(
          metrics.condition_met?(
            activity_condition(metric, 0, period: "recent"),
            level,
            buffer: 100,
          ),
        ).to eq(false)
      end
    end

    it "honors penalty reversals, the selected month window and ongoing penalties" do
      actor = Fabricate(:admin)
      Fabricate(
        :user_history,
        target_user_id: member.id,
        acting_user_id: actor.id,
        action: UserHistory.actions[:silence_user],
        created_at: 2.months.ago,
      )
      Fabricate(
        :user_history,
        target_user_id: member.id,
        acting_user_id: actor.id,
        action: UserHistory.actions[:unsilence_user],
        created_at: 1.month.ago,
      )
      Fabricate(
        :user_history,
        target_user_id: member.id,
        acting_user_id: actor.id,
        action: UserHistory.actions[:suspend_user],
        created_at: 7.months.ago,
      )
      condition = activity_condition("penalty_count", 0, period: "recent", months: 6)

      expect(metrics.condition_met?(condition, level)).to eq(true)

      member.update_columns(suspended_till: 1.day.from_now)
      ongoing = described_class.new(member, now: Time.current)
      expect(ongoing.condition_met?(condition, level)).to eq(false)
      expect(ongoing.condition_met?(condition.merge("value" => 1), level)).to eq(true)
    end
  end
end
