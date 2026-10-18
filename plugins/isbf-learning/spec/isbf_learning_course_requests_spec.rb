# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF learning course requests", type: :request do
  fab!(:category)
  fab!(:admin)
  fab!(:moderator) do
    Fabricate(:moderator, active: true, approved: true, refresh_auto_groups: true)
  end
  fab!(:member) do
    Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
  end
  fab!(:new_member) do
    Fabricate(:user, active: true, approved: true, trust_level: 0, refresh_auto_groups: true)
  end

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = category.id
    category.set_permissions(trust_level_0: :full, staff: :full)
    category.save!
  end

  def submit_course(actor = member, extra = {})
    sign_in(actor)
    post "/isbf/learning/courses.json", params: { name: "高等数学", grade: 1 }.merge(extra)
  end

  def request_course(actor = member, name: "高等数学", grade: 1)
    IsbfLearning::Courses.request(actor, name: name, grade: grade)
  end

  it "requires login before creating or requesting a course" do
    expect do
      post "/isbf/learning/courses.json", params: { name: "高等数学", grade: 1 }
      expect(response.status).to eq(403)
    end.not_to change(ReviewableIsbfLearningCourse, :count)
    expect(IsbfLearning::Courses.list).to be_empty
  end

  %w[admin moderator].each do |role|
    it "creates #{role} courses directly in the shared catalog" do
      expect do
        submit_course(public_send(role))
        expect(response.status).to eq(200), response.body
      end.not_to change(ReviewableIsbfLearningCourse, :count)
      data = response.parsed_body
      expect(data.slice("success", "pending")).to eq("success" => true, "pending" => false)
      expect(data.fetch("course").slice("name", "grade")).to eq("name" => "高等数学", "grade" => 1)
      sign_in(member)
      get "/isbf/learning/courses.json"
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.fetch("courses")).to include(data.fetch("course"))
    end
  end

  %w[new_member member].each do |role|
    it "queues #{role} requests without publishing a catalog entry" do
      actor = public_send(role)
      expect do
        submit_course(actor)
        expect(response.status).to eq(200), response.body
      end.to change(ReviewableIsbfLearningCourse, :count).by(1)
      data = response.parsed_body
      expect(data.slice("success", "pending")).to eq("success" => true, "pending" => true)
      expect(data["course"]).to be_nil
      reviewable = ReviewableIsbfLearningCourse.find(data.fetch("reviewable_id"))
      expect(reviewable).to be_pending
      expect(reviewable.created_by_id).to eq(actor.id)
      expect(reviewable.target_created_by_id).to eq(actor.id)
      expect(reviewable.category_id).to eq(category.id)
      expect(reviewable.payload).to include("course_name" => "高等数学", "grade" => 1)
      expect(reviewable.force_review).to eq(true)
      expect(reviewable.score).to eq(0)
      expect(IsbfLearning::Courses.list).to be_empty
    end
  end

  it "returns the same pending reviewable for a repeated normalized request" do
    submit_course(member, name: "  Ｃａｌｃｕｌｕｓ  ")
    expect(response.status).to eq(200), response.body
    id = response.parsed_body.fetch("reviewable_id")
    expect do
      submit_course(member, name: "calculus")
      expect(response.status).to eq(200), response.body
    end.not_to change(ReviewableIsbfLearningCourse, :count)
    expect(response.parsed_body.fetch("reviewable_id")).to eq(id)
  end

  it "normalizes staff duplicates by compatibility characters and case within each grade" do
    submit_course(admin, name: " Ｃａｌｃｕｌｕｓ ")
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("course").fetch("name")).to eq("Calculus")
    submit_course(admin, name: "calculus")
    expect(response.status).to eq(422), response.body
    submit_course(member, name: "CALCULUS")
    expect(response.status).to eq(422), response.body
    submit_course(admin, name: "calculus", grade: 2)
    expect(response.status).to eq(200), response.body
    expect(IsbfLearning::Courses.list.length).to eq(2)
    expect(ReviewableIsbfLearningCourse.count).to eq(0)
  end

  it "shows a zero score forced request in the native review queue at high priority" do
    reviewable = request_course
    SiteSetting.reviewable_default_visibility = "high"
    Reviewable.set_priorities(high: 10.0)
    expect(Reviewable.min_score_for_priority(:high)).to eq(10.0)
    sign_in(moderator)
    get "/review.json",
        params: {
          type: "ReviewableIsbfLearningCourse",
          status: "pending",
          priority: "high",
        }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("reviewables").map { |item| item["id"] }).to include(
      reviewable.id,
    )
  end

  it "approves through the native action endpoint and creates a course only once" do
    first = request_course(member, name: "Calculus")
    second = request_course(new_member, name: "CALCULUS")
    sign_in(moderator)
    [first, second].each do |reviewable|
      put "/review/#{reviewable.id}/perform/approve_course.json",
          params: {
            version: reviewable.version,
          }
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.dig("reviewable_perform_result", "success")).to eq(true)
      expect(reviewable.reload).to be_approved
    end
    courses = IsbfLearning::Courses.list
    expect(courses.length).to eq(1)
    expect(first.payload.fetch("course_id")).to eq(courses.first.fetch("id"))
    expect(second.payload.fetch("course_id")).to eq(courses.first.fetch("id"))
  end

  it "reuses a matching staff course created while a request awaits approval" do
    reviewable = request_course
    existing = IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1)
    expect(reviewable.perform(admin, :approve_course).success?).to eq(true)
    expect(reviewable.reload.payload.fetch("course_id")).to eq(existing.fetch("id"))
    expect(IsbfLearning::Courses.list.length).to eq(1)
  end

  it "allows a new application after native rejection" do
    reviewable = request_course
    sign_in(admin)
    put "/review/#{reviewable.id}/perform/reject_course.json",
        params: {
          version: reviewable.version,
        }
    expect(response.status).to eq(200), response.body
    expect(reviewable.reload).to be_rejected
    submit_course
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("reviewable_id")).not_to eq(reviewable.id)
    expect(IsbfLearning::Courses.list).to be_empty
  end

  it "denies ordinary users access to native review details and actions" do
    reviewable = request_course
    sign_in(member)
    get "/review/#{reviewable.id}.json"
    expect(response.status).to eq(403), response.body
    %i[approve_course reject_course].each do |action|
      put "/review/#{reviewable.id}/perform/#{action}.json", params: { version: reviewable.version }
      expect(response.status).to eq(403), response.body
    end
    expect(reviewable.reload).to be_pending
    expect(IsbfLearning::Courses.list).to be_empty
  end

  it "does not permit approval of a request moved outside the configured learning category" do
    reviewable = request_course
    reviewable.update!(category_id: Fabricate(:category).id)
    expect { reviewable.perform(admin, :approve_course) }.to raise_error(Reviewable::InvalidAction)
    expect(reviewable.reload).to be_pending
    expect(IsbfLearning::Courses.list).to be_empty
  end

  it "respects native category visibility and creation permissions" do
    category.set_permissions(trust_level_0: :readonly, staff: :full)
    category.save!
    submit_course
    expect(response.status).to eq(403), response.body
    category.set_permissions(staff: :full)
    category.save!
    submit_course
    expect(response.status).to eq(403), response.body
    expect(ReviewableIsbfLearningCourse.count).to eq(0)
  end

  it "denies silenced, suspended, inactive and unapproved ordinary applicants" do
    [
      { silenced_till: 1.day.from_now },
      { suspended_till: 1.day.from_now },
      { active: false },
      { approved: false },
    ].each do |attributes|
      actor =
        Fabricate(:user, active: true, approved: true, trust_level: 1, refresh_auto_groups: true)
      actor.update!(attributes)
      submit_course(actor)
      expect(response.status).to eq(403), response.body
    end
    expect(ReviewableIsbfLearningCourse.count).to eq(0)
    expect(IsbfLearning::Courses.list).to be_empty
  end

  [nil, "", "x" * 81, { invalid: "name" }].each_with_index do |name, index|
    it "rejects invalid course name #{index + 1}" do
      submit_course(member, name: name)
      expect(response.status).to eq(422), response.body
      expect(ReviewableIsbfLearningCourse.count).to eq(0)
    end
  end

  [0, 5, "abc", "1.0"].each do |grade|
    it "rejects grade #{grade.inspect}" do
      submit_course(member, grade: grade)
      expect(response.status).to eq(422), response.body
      expect(ReviewableIsbfLearningCourse.count).to eq(0)
    end
  end

  it "rolls back native review state when catalog persistence fails" do
    reviewable = request_course
    original_version = reviewable.version
    write_attempted = false
    allow(PluginStore).to receive(:set).and_wrap_original do |original, store, key, value|
      if store == IsbfLearning::STORE && key == "courses"
        write_attempted = true
        false
      else
        original.call(store, key, value)
      end
    end
    result = reviewable.perform(admin, :approve_course)
    expect(write_attempted).to eq(true)
    expect(result.success?).to eq(false)
    expect(result.errors).to include(I18n.t("isbf_learning.course_storage_error"))
    expect(reviewable.reload).to be_pending
    expect(reviewable.version).to eq(original_version)
    expect(reviewable.payload).not_to have_key("course_id")
    expect(IsbfLearning::Courses.list).to be_empty
  end

  it "rolls back the catalog and native transition together when the transition fails" do
    reviewable = request_course
    original_version = reviewable.version
    original_histories = reviewable.reviewable_histories.count
    expect(PluginStoreRow.connection).to equal(Reviewable.connection)
    allow(reviewable).to receive(:transition_to).and_wrap_original do |original, *args|
      original.call(*args)
      raise ActiveRecord::RecordInvalid.new(reviewable)
    end
    expect { reviewable.perform(admin, :approve_course) }.to raise_error(
      ActiveRecord::RecordInvalid,
    )
    expect(reviewable.reload).to be_pending
    expect(reviewable.version).to eq(original_version)
    expect(reviewable.payload).not_to have_key("course_id")
    expect(reviewable.reviewable_histories.count).to eq(original_histories)
    expect(IsbfLearning::Courses.list).to be_empty
  end

  it "holds the shared catalog mutex until the native action transaction returns" do
    reviewable = request_course
    sequence = []
    allow(DistributedMutex).to receive(:synchronize).and_call_original
    allow(DistributedMutex).to receive(:synchronize).with(
      "isbf-learning-courses",
    ).and_wrap_original do |original, *args, &block|
      original.call(*args) do
        sequence << :locked
        result = block.call
        sequence << :unlocking
        result
      end
    end
    allow(Reviewable).to receive(:transaction).and_wrap_original do |original, *args, &block|
      result = original.call(*args, &block)
      sequence << :native_transaction_returned
      result
    end
    expect(reviewable.perform(admin, :approve_course).success?).to eq(true)
    expect(sequence).to eq(%i[locked native_transaction_returned unlocking])
  end
end
