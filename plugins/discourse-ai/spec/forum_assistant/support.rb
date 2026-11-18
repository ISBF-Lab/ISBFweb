# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.shared_context "with a configured forum assistant" do
  fab!(:member) { Fabricate(:user, active: true, approved: true, refresh_auto_groups: true) }
  fab!(:other_member) { Fabricate(:user, active: true, approved: true, refresh_auto_groups: true) }
  fab!(:llm_model)
  fab!(:assistant_agent) do
    Fabricate(
      :ai_agent,
      name: "Forum assistant test",
      default_llm_id: llm_model.id,
      force_default_llm: true,
      allow_personal_messages: true,
      allowed_group_ids: [Group::AUTO_GROUPS[:trust_level_0]],
    )
  end

  let(:bot_user) { llm_model.reload.user }
  let(:conversation) { Fabricate(:private_message_topic, user: member, recipient: bot_user) }
  let(:question) do
    PostCreator.create!(
      member,
      topic_id: conversation.id,
      raw: "Where can I find quartzpilot resources in this forum?",
    )
  end
  let(:accepted_request) { AiForumAssistantRequest.find_by!(post_id: question.id) }
  let(:observe_rate_limits) { false }

  before do
    SiteSetting.discourse_ai_enabled = true
    toggle_enabled_bots(bots: [llm_model])
    SiteSetting.ai_bot_allowed_groups = Group::AUTO_GROUPS[:staff].to_s
    SiteSetting.personal_message_enabled_groups = Group::AUTO_GROUPS[:trust_level_0].to_s
    SiteSetting.ai_forum_assistant_agent = assistant_agent.id.to_s
    SiteSetting.ai_forum_assistant_model = llm_model.id.to_s
    SiteSetting.ai_forum_assistant_enabled = true
    SiteSetting.ai_forum_assistant_daily_limit = 20
    SiteSetting.ai_forum_assistant_questions_per_minute = 3
    SiteSetting.ai_forum_assistant_global_daily_limit = 1000
    SiteSetting.ai_forum_assistant_timeout_seconds = 90
    SiteSetting.ai_forum_assistant_violation_limit = 5
    SiteSetting.ai_forum_assistant_violation_window_minutes = 10
    SiteSetting.ai_forum_assistant_cooldown_minutes = 30
    SiteSetting.ai_forum_assistant_timezone = "Asia/Shanghai"
    RateLimiter.enable if observe_rate_limits
  end

  after do
    RateLimiter.disable
    Discourse.redis.keys("ai_forum_assistant:*").each { |key| Discourse.redis.del(key) }
    Discourse
      .redis
      .without_namespace
      .keys("ai_forum_assistant:*")
      .each { |key| Discourse.redis.without_namespace.del(key) }
    [member, other_member].each do |user|
      RateLimiter.new(user, "ai_forum_assistant", 3, 1.minute).clear!
    end
  end
end
