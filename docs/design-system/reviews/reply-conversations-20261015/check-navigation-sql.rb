# frozen_string_literal: true

require "json"
require "active_record"
require "active_support/all"
require "pg"

module Discourse
  class NotFound < StandardError
  end
end

module SiteSetting
  def self.nested_replies_cap_nesting_depth = true
  def self.nested_replies_max_depth = 1
end

class Post < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }

  def self.types
    { regular: 1, moderator_action: 2, small_action: 3, whisper: 4 }
  end
end

class Topic < ActiveRecord::Base
  has_many :posts
  has_one :nested_topic
  scope :with_deleted, -> { all }
end

module DB
  def self.query(sql, **params)
    result = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql_array([sql, params]),
    )
    row_type = Struct.new(*result.columns.map(&:to_sym))
    result.rows.map { |values| row_type.new(*values) }
  end
end

require "/workspace/app/models/nested_topic"
require "/workspace/lib/nested_replies/sort"
require "/workspace/lib/nested_replies/hot_score_cache"
require "/workspace/lib/nested_replies/tree_loader"
require "/workspace/lib/nested_replies/navigation"

Viewer = Struct.new(:whisperer) do
  def whisperer? = whisperer
end
Visibility = Struct.new(:user, :staff) do
  def is_staff? = staff
end

ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  database: ENV.fetch("PGDATABASE"),
  host: ENV.fetch("PGHOST"),
  port: ENV.fetch("PGPORT"),
  username: ENV.fetch("PGUSER"),
  prepared_statements: false,
  pool: 2,
  variables: { statement_timeout: "3000ms", lock_timeout: "500ms" },
)
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :topics
  create_table :nested_topics do |table|
    table.bigint :topic_id, null: false
    table.bigint :pinned_post_ids, array: true, null: false, default: []
  end
  create_table :posts do |table|
    table.bigint :topic_id, null: false
    table.integer :post_number, null: false
    table.integer :reply_to_post_number
    table.integer :post_type, null: false, default: 1
    table.integer :like_count, null: false, default: 0
    table.string :action_code
    table.datetime :created_at, null: false
    table.datetime :deleted_at
  end
  add_index :posts, %i[topic_id post_number], unique: true
  add_index :posts, %i[topic_id reply_to_post_number]
end

checks = []
def check(checks, name, actual, expected)
  raise "#{name}: expected #{expected.inspect}, got #{actual.inspect}" unless actual == expected
  checks << { name: name, passed: true }
end

def check_not_found(checks, name)
  yield
  raise "#{name}: expected Discourse::NotFound"
rescue Discourse::NotFound
  checks << { name: name, passed: true }
end

def insert_posts(topic, entries)
  Post.insert_all!(entries.map do |entry|
    {
      topic_id: topic.id,
      post_number: entry.fetch(:post_number),
      reply_to_post_number: entry[:reply_to_post_number],
      post_type: entry.fetch(:post_type, Post.types[:regular]),
      action_code: entry[:action_code],
      created_at: Time.utc(2026, 10, 15) + entry.fetch(:post_number),
    }
  end)
end

def new_topic
  topic = Topic.create!
  NestedTopic.create!(topic: topic)
  insert_posts(topic, [{ post_number: 1 }])
  topic
end

def loader_for(topic, staff: false)
  NestedReplies::TreeLoader.new(
    topic: topic,
    guardian: Visibility.new(Viewer.new(staff), staff),
  )
end

begin
  topic = new_topic
  loader = loader_for(topic)
  navigation = NestedReplies::Navigation.new(loader)
  check(checks, "empty discussion count", navigation.metadata[:root_count], 0)
  insert_posts(topic, (2..24).map do |number|
    { post_number: number, reply_to_post_number: number.even? ? 1 : nil }
  end)
  roots = topic.posts.where(post_number: 2..).order(:post_number).to_a
  check(checks, "chronological roots", navigation.roots.pluck(:post_number), (2..24).to_a)
  check(checks, "first root page", navigation.roots.limit(20).pluck(:post_number), (2..21).to_a)
  check(checks, "second root page", navigation.roots.offset(20).pluck(:post_number), (22..24).to_a)
  check(checks, "window root index", navigation.metadata(root_index: 21).slice(:root_index, :root_page, :root_post_number), { root_index: 21, root_page: 1, root_post_number: 22 })

  topic.nested_topic.update!(pinned_post_ids: [roots.last.id, roots[3].id])
  pinned_numbers = [24, 5] + ((2..24).to_a - [24, 5])
  check(checks, "pin order", navigation.roots.pluck(:post_number), pinned_numbers)
  check(checks, "pinned root index", navigation.metadata(post_number: 24)[:root_index], 1)
  check(checks, "root index after pin promotion", navigation.metadata(post_number: 2)[:root_index], 3)
  topic.nested_topic.update!(pinned_post_ids: [])

  insert_posts(topic, (25..124).map do |number|
    { post_number: number, reply_to_post_number: number == 25 ? 22 : number - 1 }
  end)
  check(checks, "100-deep navigation", navigation.metadata(post_number: 124).slice(:root_count, :root_index, :root_page, :child_page), { root_count: 23, root_index: 21, root_page: 1, child_page: 1 })
  check(checks, "50th child page", navigation.metadata(post_number: 74)[:child_page], 0)
  check(checks, "51st child page", navigation.metadata(post_number: 75)[:child_page], 1)
  check(checks, "first descendant page", loader.flat_descendants_scope(22, sort: "old").pluck(:post_number), (25..74).to_a)
  check(checks, "second descendant page", loader.flat_descendants_scope(22, sort: "old", offset: 50).pluck(:post_number), (75..124).to_a)
  check(checks, "completed descendant pages", loader.flat_descendants_scope(22, sort: "old", offset: 100).pluck(:post_number), [])

  insert_posts(topic, [
    { post_number: 125, reply_to_post_number: 3 },
    { post_number: 126, reply_to_post_number: 3 },
    { post_number: 127, reply_to_post_number: 125 },
    { post_number: 128, reply_to_post_number: 126 },
  ])
  check(checks, "three-reply windows for separate branches", loader.flat_descendant_post_numbers_by_parent([22, 3], sort: "old", limit: 3), { 3 => [125, 126, 127], 22 => [25, 26, 27] })
  check(checks, "branch resolves to its original root", navigation.metadata(post_number: 128)[:root_post_number], 3)
  topic.posts.where(post_number: [4, 22]).update_all(deleted_at: Time.now.utc)
  check(checks, "deleted root leaf omitted", navigation.roots.pluck(:post_number), (2..24).to_a - [4])
  check(checks, "deleted parent still locates public descendant", navigation.metadata(post_number: 124)[:root_post_number], 22)

  whisper_topic = new_topic
  whisper_entries = [{ post_number: 2, reply_to_post_number: 1 }]
  whisper_entries.concat((3..51).map do |number|
    { post_number: number, reply_to_post_number: 2 }
  end)
  whisper_entries.concat([
    { post_number: 52, reply_to_post_number: 2, post_type: 4, action_code: "closed.enabled" },
    { post_number: 53, reply_to_post_number: 2, post_type: 4 },
  ])
  insert_posts(whisper_topic, whisper_entries)
  regular_loader = loader_for(whisper_topic)
  staff_loader = loader_for(whisper_topic, staff: true)
  regular_navigation = NestedReplies::Navigation.new(regular_loader)
  staff_navigation = NestedReplies::Navigation.new(staff_loader)
  check(checks, "regular reply count excludes whispers", regular_navigation.metadata[:reply_count], 50)
  check_not_found(checks, "regular viewer cannot locate whisper") { regular_navigation.metadata(post_number: 53) }
  check(checks, "staff reply count excludes activity", staff_navigation.metadata[:reply_count], 51)
  check(checks, "activity does not shift the 50th visible child", staff_navigation.metadata(post_number: 53)[:child_page], 0)
  check(checks, "staff page excludes activity and includes target", staff_loader.flat_descendants_scope(2, sort: "old").pluck(:post_number), (3..51).to_a + [53])
  check_not_found(checks, "activity is not a reply target") { staff_navigation.metadata(post_number: 52) }

  corrupt_topic = new_topic
  insert_posts(corrupt_topic, [
    { post_number: 2, reply_to_post_number: 1 },
    { post_number: 3, reply_to_post_number: 99_999 },
    { post_number: 4, reply_to_post_number: 5 },
    { post_number: 5, reply_to_post_number: 4 },
  ])
  corrupt_loader = loader_for(corrupt_topic)
  corrupt_navigation = NestedReplies::Navigation.new(corrupt_loader)
  [3, 4, 5].each do |post_number|
    check_not_found(checks, "corrupt target #{post_number} rejects unrelated root fallback") { corrupt_navigation.metadata(post_number: post_number) }
  end
  check(checks, "cyclic descendant relation terminates and deduplicates", corrupt_loader.flat_descendants_scope(4, sort: "old").pluck(:post_number), [4, 5])
  check(checks, "cyclic preview CTE terminates and deduplicates", corrupt_loader.flat_descendant_post_numbers_by_parent([4], sort: "old", limit: 10), { 4 => [4, 5] })
  check_not_found(checks, "foreign topic post number stays unavailable") { corrupt_navigation.metadata(post_number: 124) }

  result = {
    status: "passed",
    kind: "synthetic_postgresql_active_record_checks",
    full_rspec: false,
    rails_booted: false,
    active_record: ActiveRecord.version.to_s,
    postgres: ActiveRecord::Base.connection.select_value("SHOW server_version"),
    checks: checks,
    limitations: "Synthetic models and visibility actors exercise actual Navigation, TreeLoader, Sort, and HotScoreCache code. This does not run Rails, controllers, serializers, permissions, or complete RSpec.",
  }
rescue StandardError => error
  result = { status: "failed", kind: "synthetic_postgresql_active_record_checks", full_rspec: false, checks: checks, error: error.message, backtrace: error.backtrace.first(8) }
end
File.write("/review/navigation-sql-results.json", JSON.pretty_generate(result) + "\n")
puts JSON.generate(result)
exit(result[:status] == "passed" ? 0 : 1)
