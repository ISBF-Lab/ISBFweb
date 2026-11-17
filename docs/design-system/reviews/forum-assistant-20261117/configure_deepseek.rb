# frozen_string_literal: true

require "json"

unless Rails.env.development? && ENV["ISBF_DEV_ENVIRONMENT"] == "1" &&
         ActiveRecord::Base.connection_db_config.database == "discourse_development"
  abort "Requires the isolated development database"
end

payload = JSON.parse(STDIN.read)
api_key = payload.fetch("api_key").strip
abort "Invalid development API key" unless api_key.match?(/\Ask-[A-Za-z0-9_-]+\z/)

ActiveRecord::Base.transaction do
  secret = AiSecret.find_or_initialize_by(name: "Forum assistant development DeepSeek")
  secret.update!(secret: api_key)
  model = LlmModel.find_or_initialize_by(display_name: "DeepSeek forum assistant (development)")
  model.update!(
    name: "deepseek-flash",
    provider: "open_ai",
    url: "https://api.deepseek.com/chat/completions",
    tokenizer: "DiscourseAi::Tokenizer::OpenAiTokenizer",
    max_prompt_tokens: 100_000,
    ai_secret: secret,
  )
  agent = AiAgent.find(-1)
  agent.create_user! unless agent.user
  agent.update!(
    enabled: true,
    allow_personal_messages: true,
    default_llm_id: model.id,
    force_default_llm: true,
  )
  SiteSetting.discourse_ai_enabled = true
  SiteSetting.ai_bot_enabled = true
  SiteSetting.ai_forum_assistant_agent = agent.id
  SiteSetting.ai_forum_assistant_model = model.id.to_s
  SiteSetting.ai_forum_assistant_enabled = true
  abort "Forum assistant is not ready" unless DiscourseAi::ForumAssistant::Configuration.available?
  puts(
    {
      configured: true,
      model_id: model.id,
      model_name: model.name,
      agent_id: agent.id,
      bot_username: agent.user.username,
    }.to_json,
  )
end
