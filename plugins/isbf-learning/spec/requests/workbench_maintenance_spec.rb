# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Independent workbench resource maintenance", type: :request do
  fab!(:learning_category, :category)
  fab!(:library_category, :category)
  fab!(:admin)
  fab!(:member) { Fabricate(:user, active: true, approved: true, refresh_auto_groups: true) }

  let(:paused_keys) { Set.new }

  around do |example|
    maintenance = Module.new
    paused = paused_keys
    maintenance.define_singleton_method(:ensure_available!) do |key|
      raise Discourse::NotFound if paused.include?(key.to_s)
    end
    stub_const(Object, :IsbfWorkbenchMaintenance, maintenance) { example.run }
  end

  before do
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = learning_category.id
    SiteSetting.isbf_library_enabled = true
    SiteSetting.isbf_library_category_id = library_category.id
    [learning_category, library_category].each do |category|
      category.set_permissions(trust_level_0: :full, staff: :full)
      category.save!
    end
  end

  let(:learning_payload) do
    course = IsbfLearning::Courses.create(admin, name: "Maintenance course", grade: 1)
    {
      title: "Course reference available before maintenance",
      raw: "Course reference: https://example.org/course",
      category: learning_category.id,
      isbf_learning_course_id: course.fetch("id"),
      isbf_learning_files: "[]",
    }
  end

  let(:library_payload) do
    directory = IsbfLibrary::Catalog.create(admin, kind: "category", name: "Maintenance library")
    group =
      IsbfLibrary::Catalog.create(
        admin,
        kind: "group",
        name: "Maintenance references",
        category_id: directory.fetch("id"),
      )
    {
      title: "Library reference available before maintenance",
      raw: "Library reference: https://example.org/library",
      category: library_category.id,
      isbf_library_group_id: group.fetch("id"),
      isbf_library_files: "[]",
      isbf_library_link: "https://example.org/library",
    }
  end

  %w[learning_resources library].each do |paused_key|
    it "blocks #{paused_key} entry points and business operations independently, then restores them" do
      learning = learning_payload
      library = library_payload
      selected = paused_key == "learning_resources" ? learning : library
      prefix = paused_key == "learning_resources" ? "/isbf/learning" : "/isbf/library"
      sibling =
        (
          if paused_key == "learning_resources"
            "/isbf/library/categories.json"
          else
            "/isbf/learning/courses.json"
          end
        )
      paused_keys << paused_key
      sign_in(admin)

      get prefix
      expect(response.status).to eq(404), response.body

      [
        [:get, "#{prefix}/resources.json"],
        [:post, "#{prefix}/resources.json"],
        [:put, "#{prefix}/resources/123.json"],
        [:delete, "#{prefix}/resources/123.json"],
        *(
          if paused_key == "learning_resources"
            [
              [:get, "/isbf/learning/files/123"],
              [:post, "/isbf/learning/uploads.json"],
              [:post, "/isbf/learning/courses.json"],
            ]
          else
            [[:post, "/isbf/library/categories.json"], [:post, "/isbf/library/groups.json"]]
          end
        ),
      ].each do |method, route|
        public_send(method, route)
        expect(response.status).to eq(404), "#{method} #{route}"
      end
      get(
        if paused_key == "learning_resources"
          "/isbf/learning/courses.json"
        else
          "/isbf/library/categories.json"
        end,
      )
      expect(response.status).to eq(404), response.body

      expect do
        post "/posts.json", params: selected
        expect(response.status).to eq(404), response.body
      end.not_to change(Topic, :count)

      get sibling
      expect(response.status).to eq(200), response.body
      expect(SiteSetting.isbf_learning_enabled).to eq(true)
      expect(SiteSetting.isbf_library_enabled).to eq(true)

      paused_keys.delete(paused_key)
      get prefix
      expect(response.status).to eq(200), response.body
      post "/posts.json", params: selected
      expect(response.status).to eq(200), response.body
    end
  end

  it "keeps a queued course pending during maintenance and permits approval after recovery" do
    request = IsbfLearning::Courses.request(member, name: "Queued maintenance course", grade: 1)
    paused_keys << "learning_resources"

    expect do
      IsbfLearning::Courses.approve_locked(admin, name: "Queued maintenance course", grade: 1)
    end.to raise_error(Discourse::NotFound)
    expect(request.reload).to be_pending
    expect(IsbfLearning::Courses.list).to be_empty

    paused_keys.clear
    result = request.perform(admin, :approve_course)
    expect(result.success?).to eq(true)
    expect(request.reload).to be_approved
  end

  it "suspends a previously accessible private course download and restores its original bytes" do
    id = SecureRandom.uuid
    destination = IsbfLearning::Files.path(id)
    contents = "Private course reference preserved during maintenance"
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, contents)
    PluginStore.set(
      IsbfLearning::STORE,
      "file:#{id}",
      { name: "course-reference.txt", size: contents.bytesize, owner_id: admin.id, bound: false },
    )
    payload =
      learning_payload.merge(
        raw: "Private course attachment [reference](/isbf/learning/files/#{id})",
        isbf_learning_files: [id].to_json,
      )
    result = NewPostManager.new(admin, payload).perform
    expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
    sign_in(admin)

    get "/isbf/learning/files/#{id}"
    expect(response.status).to eq(200)
    expect(response.body).to eq(contents)

    paused_keys << "learning_resources"
    get "/isbf/learning/files/#{id}"
    expect(response.status).to eq(404)
    get "/isbf/library/categories.json"
    expect(response.status).to eq(200)

    paused_keys.clear
    get "/isbf/learning/files/#{id}"
    expect(response.status).to eq(200)
    expect(response.body).to eq(contents)
  ensure
    FileUtils.rm_f(destination) if destination
  end

  it "keeps published topics and ordinary forum replies available while both workspaces are paused" do
    resource_posts =
      [learning_payload, library_payload].map do |payload|
        result = NewPostManager.new(admin, payload).perform
        expect(result.success?).to eq(true), result.errors.full_messages.join(", ")
        result.post
      end
    paused_keys.merge(%w[learning_resources library])
    sign_in(member)

    resource_posts.each do |post|
      get "/t/#{post.topic_id}.json"
      expect(response.status).to eq(200), response.body
      expect(response.parsed_body.fetch("id")).to eq(post.topic_id)
    end

    expect do
      post "/posts.json",
           params: {
             topic_id: resource_posts.first.topic_id,
             raw: "A normal forum reply remains available during workspace maintenance.",
           }
      expect(response.status).to eq(200), response.body
    end.to change(Post, :count).by(1)

    sign_in(admin)
    original = resource_posts.first.raw
    put "/posts/#{resource_posts.first.id}.json",
        params: {
          post: {
            raw: "A changed course reference during maintenance.",
          },
        }
    expect(response.status).to eq(404), response.body
    expect(resource_posts.first.reload.raw).to eq(original)
  end
end
