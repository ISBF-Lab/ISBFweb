# frozen_string_literal: true

require "json"

unless Rails.env.development? && ENV["ISBF_DEV_ENVIRONMENT"] == "1" &&
         ActiveRecord::Base.connection_db_config.database == "discourse_development"
  abort "The action fixture requires the isolated development database"
end

credentials = JSON.parse(STDIN.read)
admin = User.find_by!(username: credentials.fetch("admin_username"))
student = User.find_by!(username: credentials.fetch("student_username"))
alumni = User.find_by!(username: credentials.fetch("alumni_username"))
title = "Development fixture: post action pulse"
topic = Topic.find_by(title: title)
first =
  topic&.first_post ||
    PostCreator.create!(
      admin,
      title: title,
      category: Category.find_by!(slug: "campus").id,
      raw: "本地开发验证帖子：检查点赞、引用、评论和收藏的回弹动效。此主题及其回复均为虚构测试数据。",
      skip_validations: true,
      skip_guardian: true,
    )
topic = first.topic

def fixture_reply(topic, author, raw, parent = nil)
  topic.posts.find_by(user_id: author.id, raw: raw) ||
    PostCreator.create!(
      author,
      topic_id: topic.id,
      raw: raw,
      reply_to_post_number: parent&.post_number,
      skip_validations: true,
      skip_guardian: true,
    )
end

root = fixture_reply(topic, student, "根评论测试：保留原有回复动作、赞数入口、收藏提醒和五列图标布局。")
child = fixture_reply(topic, admin, "子回复测试：缩进和操作栏保持现有布局，仅增加按钮交互动效。", root)
own = fixture_reply(topic, alumni, "本人评论测试：保留本人收到点赞的数字入口，不提供给自己点赞的动作。")

[[student, first], [admin, root], [student, child], [student, own]].each do |actor, post|
  unless PostAction.exists?(
           user_id: actor.id,
           post_id: post.id,
           post_action_type_id: 2,
           deleted_at: nil,
         )
    result = PostActionCreator.like(actor, post)
    abort "Fixture like creation failed" unless result.success?
  end
end

puts JSON.generate(
       id: topic.id,
       slug: topic.slug,
       first: first.id,
       root: root.id,
       child: child.id,
       own: own.id,
     )
