# frozen_string_literal: true

require "timeout"
require_relative "../../plugin_helper"

RSpec.describe "ISBF join concurrent submissions", type: :model do
  self.use_transactional_tests = false

  let(:submission_id) { SecureRandom.uuid }
  let(:params) do
    { name: "申请人", student_id: "2026101401", phone: "13800138000", submission_id: submission_id }
  end

  around do |example|
    original_config = ActiveRecord::Base.connection_db_config.configuration_hash
    ActiveRecord::Base.establish_connection(original_config.merge(pool: 3))
    example.run
  ensure
    ActiveRecord::Base.establish_connection(original_config) if original_config
  end

  after { IsbfJoin::Application.where(submission_id: submission_id).delete_all }

  def submit_concurrently(payloads)
    ready = Queue.new
    start = Queue.new
    workers =
      payloads.map do |payload|
        Thread.new do
          Thread.current.report_on_exception = false
          ActiveRecord::Base.connection_pool.with_connection do
            ready << true
            Timeout.timeout(10) { start.pop }
            IsbfJoin::SubmitApplication.call(params: payload)
          end
        end
      end

    Timeout.timeout(10) { payloads.length.times { ready.pop } }
    payloads.length.times { start << true }
    workers.map do |worker|
      raise "Application submission timed out" if !worker.join(15)
      worker.value
    end
  ensure
    workers&.each do |worker|
      worker.kill if worker.alive?
      worker.join(2)
    end
  end

  it "stores one application and returns the same record for simultaneous identical requests" do
    results = submit_concurrently([params, params.deep_dup])

    expect(results).to all(run_successfully)
    expect(IsbfJoin::Application.where(submission_id: submission_id).count).to eq(1)
    expect(results.map { |result| result.application.id }.uniq.length).to eq(1)
  end

  it "stores one original submission and rejects a simultaneous conflicting request" do
    results = submit_concurrently([params, params.merge(name: "另一申请人")])

    expect(results.count(&:success?)).to eq(1)
    expect(results.find(&:failure?)).to fail_a_policy(:submission_matches)
    expect(IsbfJoin::Application.where(submission_id: submission_id).count).to eq(1)
    expect(IsbfJoin::Application.find_by!(submission_id: submission_id)).to eq(
      results.find(&:success?).application,
    )
  end
end
