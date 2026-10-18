# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ISBF library directory catalog", type: :request do
  fab!(:category)
  fab!(:learning_category, :category)
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
    SiteSetting.isbf_learning_category_id = learning_category.id
    SiteSetting.isbf_library_enabled = true
    SiteSetting.isbf_library_category_id = category.id
    [category, learning_category].each do |item|
      item.set_permissions(trust_level_0: :full, staff: :full)
      item.save!
    end
  end

  let(:directory) { IsbfLibrary::Catalog.create(admin, kind: "category", name: "校园资料") }

  def submit_directory(actor = member, kind: "category", name: "校园资料", category_id: nil)
    sign_in(actor)
    post "/isbf/library/#{kind == "category" ? "categories" : "groups"}.json",
         params: {
           name: name,
           category_id: category_id,
         }
  end

  def request_directory(actor = member, **attributes)
    IsbfLibrary::Catalog.request(actor, **{ kind: "category", name: "校园资料" }.merge(attributes))
  end

  it "starts empty without generating demonstration entries" do
    sign_in(member)
    get "/isbf/library/categories.json"
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("categories")).to be_empty
    get "/isbf/library/groups.json"
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("groups")).to be_empty
    expect(IsbfLibrary::Catalog.categories).to be_empty
    expect(IsbfLibrary::Catalog.groups).to be_empty
  end

  it "requires login for directory reads and applications" do
    %w[categories groups].each do |path|
      get "/isbf/library/#{path}.json"
      expect(response.status).to eq(403), response.body
      expect do
        post "/isbf/library/#{path}.json", params: { name: "校园资料" }
        expect(response.status).to eq(403), response.body
      end.not_to change(ReviewableIsbfLibraryDirectory, :count)
    end
  end

  %w[admin moderator].each do |role|
    it "creates #{role} categories and groups directly with independent UUIDs" do
      actor = public_send(role)
      expect do
        submit_directory(actor)
        expect(response.status).to eq(200), response.body
      end.not_to change(ReviewableIsbfLibraryDirectory, :count)
      data = response.parsed_body
      expect(data.slice("success", "pending")).to eq("success" => true, "pending" => false)
      parent = data.fetch("category")
      expect(parent.fetch("id")).to match(/\A[0-9a-f-]{36}\z/)
      submit_directory(actor, kind: "group", name: "新生指南", category_id: parent.fetch("id"))
      expect(response.status).to eq(200), response.body
      group = response.parsed_body.fetch("group")
      expect(group.fetch("id")).to match(/\A[0-9a-f-]{36}\z/)
      expect(group.fetch("category_id")).to eq(parent.fetch("id"))
      sign_in(member)
      get "/isbf/library/groups.json", params: { category_id: parent.fetch("id") }
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.fetch("groups")).to eq([group])
      expect(IsbfLearning::Courses.list).to be_empty
    end
  end

  %w[member new_member].each do |role|
    it "queues #{role} directory applications without publishing them" do
      actor = public_send(role)
      expect do
        submit_directory(actor)
        expect(response.status).to eq(200), response.body
      end.to change(ReviewableIsbfLibraryDirectory, :count).by(1)
      data = response.parsed_body
      expect(data.slice("success", "pending")).to eq("success" => true, "pending" => true)
      reviewable = ReviewableIsbfLibraryDirectory.find(data.fetch("reviewable_id"))
      expect(reviewable).to be_pending
      expect(reviewable.created_by_id).to eq(actor.id)
      expect(reviewable.target_created_by_id).to eq(actor.id)
      expect(reviewable.category_id).to eq(category.id)
      expect(reviewable.payload).to include("kind" => "category", "name" => "校园资料")
      expect(reviewable.force_review).to eq(true)
      expect(IsbfLibrary::Catalog.categories).to be_empty
    end
  end

  it "deduplicates normalized pending requests per applicant and parent" do
    first = request_directory(name: " Ｃａｍｐｕｓ ")
    expect do
      repeat = request_directory(name: "campus")
      expect(repeat.id).to eq(first.id)
    end.not_to change(ReviewableIsbfLibraryDirectory, :count)
    expect(request_directory(new_member, name: "CAMPUS").id).not_to eq(first.id)
    parent = directory
    group_request =
      request_directory(kind: "group", name: " Ｇｕｉｄｅ ", category_id: parent.fetch("id"))
    expect(
      request_directory(kind: "group", name: "guide", category_id: parent.fetch("id")).id,
    ).to eq(group_request.id)
  end

  it "rejects normalized duplicates but permits group names in different parents" do
    submit_directory(admin, name: " Ｃａｍｐｕｓ ")
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("category").fetch("name")).to eq("Campus")
    submit_directory(admin, name: "campus")
    expect(response.status).to eq(422), response.body
    submit_directory(member, name: "CAMPUS")
    expect(response.status).to eq(422), response.body
    other = IsbfLibrary::Catalog.create(admin, kind: "category", name: "学习资料")
    [directory, other].each do |parent|
      submit_directory(admin, kind: "group", name: "指南", category_id: parent.fetch("id"))
      expect(response.status).to eq(200), response.body
    end
    expect(IsbfLibrary::Catalog.groups.length).to eq(2)
  end

  it "rejects missing, unknown and course UUID parents before queuing a group" do
    course = IsbfLearning::Courses.create(admin, name: "高等数学", grade: 1)
    [nil, "", "invalid", SecureRandom.uuid, course.fetch("id")].each do |parent_id|
      expect do
        submit_directory(member, kind: "group", name: "指南", category_id: parent_id)
        expect(response.status).to eq(422), response.body
      end.not_to change(ReviewableIsbfLibraryDirectory, :count)
    end
    expect(IsbfLibrary::Catalog.groups).to be_empty
  end

  [nil, "", "字" * 81, "text\u0000", { invalid: "name" }].each_with_index do |name, index|
    it "rejects invalid Unicode directory name #{index + 1}" do
      expect do
        submit_directory(member, name: name)
        expect(response.status).to eq(422), response.body
      end.not_to change(ReviewableIsbfLibraryDirectory, :count)
      expect(IsbfLibrary::Catalog.categories).to be_empty
    end
  end

  it "accepts eighty Unicode codepoints after compatibility normalization" do
    submit_directory(admin, name: "字" * 80)
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("category").fetch("name")).to eq("字" * 80)
  end

  it "approves separate native requests once and reuses a directory added by staff" do
    first = request_directory(name: "Campus")
    second = request_directory(new_member, name: "CAMPUS")
    existing = IsbfLibrary::Catalog.create(admin, kind: "category", name: "campus")
    sign_in(moderator)
    [first, second].each do |reviewable|
      put "/review/#{reviewable.id}/perform/approve_directory.json",
          params: {
            version: reviewable.version,
          }
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.dig("reviewable_perform_result", "success")).to eq(true)
      expect(reviewable.reload).to be_approved
    end
    expect(IsbfLibrary::Catalog.categories.map { |item| item.fetch("id") }).to eq(
      [existing.fetch("id")],
    )
  end

  it "publishes groups only after native staff approval" do
    reviewable = request_directory(kind: "group", name: "新生指南", category_id: directory.fetch("id"))
    expect(reviewable.payload).to include("kind" => "group", "category_id" => directory.fetch("id"))
    expect(IsbfLibrary::Catalog.groups).to be_empty
    expect(reviewable.perform(moderator, :approve_directory).success?).to eq(true)
    expect(
      IsbfLibrary::Catalog.groups(directory.fetch("id")).map { |item| item.fetch("name") },
    ).to eq(["新生指南"])
  end

  it "allows a new application after native rejection" do
    reviewable = request_directory
    sign_in(moderator)
    put "/review/#{reviewable.id}/perform/reject_directory.json",
        params: {
          version: reviewable.version,
        }
    expect(response.status).to eq(200), response.body
    expect(reviewable.reload).to be_rejected
    expect(request_directory.id).not_to eq(reviewable.id)
    expect(IsbfLibrary::Catalog.categories).to be_empty
  end

  it "shows forced requests in the staff review queue and denies ordinary review actions" do
    reviewable = request_directory
    sign_in(moderator)
    get "/review.json", params: { type: "ReviewableIsbfLibraryDirectory", status: "pending" }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("reviewables").map { |item| item["id"] }).to include(
      reviewable.id,
    )
    sign_in(member)
    get "/review/#{reviewable.id}.json"
    expect(response.status).to eq(403), response.body
    %w[approve_directory reject_directory].each do |action|
      put "/review/#{reviewable.id}/perform/#{action}.json", params: { version: reviewable.version }
      expect(response.status).to eq(403), response.body
    end
    expect(reviewable.reload).to be_pending
  end

  it "rolls back review state when catalog persistence fails" do
    reviewable = request_directory
    version = reviewable.version
    allow(PluginStore).to receive(:set).and_wrap_original do |original, store, key, value|
      store == IsbfLibrary::STORE && key == "categories" ? false : original.call(store, key, value)
    end
    expect(reviewable.perform(admin, :approve_directory).success?).to eq(false)
    expect(reviewable.reload).to be_pending
    expect(reviewable.version).to eq(version)
    expect(IsbfLibrary::Catalog.categories).to be_empty
  end

  it "rolls back directory persistence when the native review transition fails" do
    reviewable = request_directory
    version = reviewable.version
    histories = reviewable.reviewable_histories.count
    allow(reviewable).to receive(:transition_to).and_wrap_original do |original, *args|
      original.call(*args)
      raise ActiveRecord::RecordInvalid.new(reviewable)
    end
    expect { reviewable.perform(admin, :approve_directory) }.to raise_error(
      ActiveRecord::RecordInvalid,
    )
    expect(reviewable.reload).to be_pending
    expect(reviewable.version).to eq(version)
    expect(reviewable.reviewable_histories.count).to eq(histories)
    expect(IsbfLibrary::Catalog.categories).to be_empty
  end

  it "denies approval after the reviewable is moved outside the configured category" do
    reviewable = request_directory
    reviewable.update!(category_id: learning_category.id)
    expect { reviewable.perform(admin, :approve_directory) }.to raise_error(
      Reviewable::InvalidAction,
    )
    expect(reviewable.reload).to be_pending
    expect(IsbfLibrary::Catalog.categories).to be_empty
  end

  it "respects native category permissions for reading and requesting directories" do
    category.set_permissions(trust_level_0: :readonly, staff: :full)
    category.save!
    submit_directory
    expect(response.status).to eq(403), response.body
    category.set_permissions(staff: :full)
    category.save!
    get "/isbf/library/categories.json"
    expect(response.status).to eq(403), response.body
    submit_directory
    expect(response.status).to eq(403), response.body
    expect(ReviewableIsbfLibraryDirectory.count).to eq(0)
  end

  it "fails closed for invalid library configuration without changing course catalogs" do
    sign_in(member)
    [0, learning_category.id].each do |id|
      SiteSetting.isbf_library_category_id = id
      get "/isbf/library/categories.json"
      expect(response.status).to be_in([403, 404]), response.body
    end
    expect(IsbfLibrary.category_id).to be_blank
    expect(IsbfLibrary::Catalog.categories).to be_empty
    expect(IsbfLearning.category_id).to eq(learning_category.id)
  end
end
