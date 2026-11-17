# frozen_string_literal: true

class AiForumAssistantQuota < ActiveRecord::Base
  self.table_name = "ai_forum_assistant_quotas"

  GLOBAL_USER_ID = 0

  def self.for_period(
    user_id,
    period_start = DiscourseAi::ForumAssistant::Configuration.period_start
  )
    create_or_find_by!(user_id: user_id, period_start: period_start)
  end

  def self.used_by(user_id)
    where(
      user_id: user_id,
      period_start: DiscourseAi::ForumAssistant::Configuration.period_start,
    ).pick(:used).to_i
  end
end

# == Schema Information
#
# Table name: ai_forum_assistant_quotas
#
#  id           :bigint           not null, primary key
#  period_start :datetime         not null
#  used         :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_ai_forum_assistant_quotas_on_period_start_and_user_id  (period_start,user_id) UNIQUE
#
