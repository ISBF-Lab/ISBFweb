# frozen_string_literal: true

require_relative "../plugin_helper"
require "timeout"

RSpec.describe IsbfMbti::Result, type: :model do
  self.use_transactional_tests = false

  let!(:owner) { Fabricate(:user) }

  after do
    described_class.where(user_id: owner.id).delete_all
    owner.destroy!
  end

  describe ".record!" do
    it "commits one history when two connections submit the same attempt concurrently" do
      ready = Queue.new
      start = Queue.new
      attempt_id = SecureRandom.uuid
      answers = (1..40).map { |question_id| { id: question_id, choice: 1 } }
      threads =
        Array.new(2) do
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              account = User.find(owner.id)
              ready.push(true)
              start.pop
              described_class.record!(
                user: account,
                variant: "40",
                version: "isbf-1",
                attempt_id: attempt_id,
                answers: answers,
              ).id
            end
          end
        end
      result_ids =
        Timeout.timeout(15) do
          2.times { ready.pop }
          2.times { start.push(true) }
          threads.map(&:value)
        end
      expect(result_ids.uniq.size).to eq(1)
      expect(described_class.where(user_id: owner.id).count).to eq(1)
    ensure
      threads&.each do |thread|
        thread.kill if thread.alive?
        thread.join
      end
    end
  end
end
