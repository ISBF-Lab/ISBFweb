# frozen_string_literal: true

module IsbfModerationSpecFixtures
  def isbf_fabricate(type, **attributes)
    token = SecureRandom.hex(5)
    case type
    when :user, :moderator
      attributes[:username] ||= "isbf_s_#{token}"
      attributes[:email] ||= "#{attributes[:username]}@example.com"
    when :topic, :private_message_topic
      attributes[:title] ||= "ISBF severe reporting test #{token}"
      attributes[:user] ||= isbf_fabricate(:user)
      attributes[:recipient] ||= isbf_fabricate(:user) if type == :private_message_topic
    when :post, :private_message_post
      attributes[:user] ||= isbf_fabricate(:user)
      topic_type = type == :private_message_post ? :private_message_topic : :topic
      attributes[:topic] ||= isbf_fabricate(topic_type, user: attributes[:user])
    when :category, :private_category
      attributes[:name] ||= "ISBF test #{token}"
      attributes[:user] ||= isbf_fabricate(:user)
      attributes[:group] ||= isbf_fabricate(:group) if type == :private_category
    when :group
      attributes[:name] ||= "isbf_s_#{token}"
    when :reviewable_flagged_post
      attributes[:target] ||= isbf_fabricate(:post)
      attributes[:created_by] ||= isbf_fabricate(:user)
      attributes[:target_created_by] ||= attributes[:target].user
      attributes[:topic] ||= attributes[:target].topic
      attributes[:reviewable_scores] ||= [
        Fabricate.build(
          :reviewable_score,
          reviewable: nil,
          user: attributes[:created_by],
          reviewed_by: nil,
          status: :pending,
        ),
      ]
    end
    Fabricate(type, **attributes)
  end
end

RSpec.configure { |config| config.include(IsbfModerationSpecFixtures) }
