# frozen_string_literal: true

RSpec.describe "Moderator business permissions" do
  fab!(:developer, :admin)
  fab!(:moderator) do
    Fabricate(:moderator, active: true, approved: true, refresh_auto_groups: true)
  end
  fab!(:member) { Fabricate(:user, active: true, approved: true, refresh_auto_groups: true) }
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:resource_category, :category)
  fab!(:activity_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_activity_category = activity_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.isbf_learning_enabled = true
    SiteSetting.isbf_learning_category_id = resource_category.id
    SiteSetting.auto_silence_fast_typers_on_first_post = false
    [official_category, resource_category, activity_category].each do |category|
      category.set_permissions(trust_level_0: :create_post, staff: :full)
      category.save!
    end
    sign_in(moderator)
  end

  it "publishes an official topic only with its own switch without adding a certification membership" do
    params = {
      title: "Campus announcement from a delegated publisher",
      raw: "An official announcement for the academy community.",
      category: official_category.id,
      academy_official: true,
      isbf_official_campuses: '["zhuhai"]',
      isbf_official_types: '["academic"]',
    }
    post "/posts.json", params: params
    expect(response.status).to eq(403)
    SiteSetting.academy_moderators_publish_official = true
    post "/posts.json", params: params
    expect(response.status).to eq(200), response.body
    topic = Topic.find(response.parsed_body.fetch("topic_id"))
    expect(topic.first_post.custom_fields[DiscourseAcademyRoles::OFFICIAL_POST_FIELD]).to eq(true)
    expect(official_group.group_users.where(user_id: moderator.id)).not_to exist
    SiteSetting.academy_moderators_publish_official = false
    post "/posts.json", params: params.merge(title: "A second delegated announcement")
    expect(response.status).to eq(403)
  end

  it "gates activity category creation and event editing independently of official publishing" do
    guardian = moderator.guardian
    expect(guardian.can_create_discourse_post_event?).to eq(false)
    SiteSetting.academy_moderators_publish_activities = true
    expect(guardian.can_create_discourse_post_event?).to eq(true)
    post "/posts.json",
         params: {
           title: "Student campus activity from a delegated publisher",
           raw: "Join this campus activity and meet other students.",
           category: activity_category.id,
         }
    expect(response.status).to eq(200), response.body
    expect(guardian.can_create_topic_on_category?(official_category)).to eq(false)
    SiteSetting.academy_moderators_publish_activities = false
    expect(guardian.can_create_discourse_post_event?).to eq(false)
    expect(guardian.can_create_topic_on_category?(activity_category)).to eq(false)
  end

  it "allows whisper viewing without granting explicit or inherited whisper creation" do
    SiteSetting.whispers_allowed_groups = Group::AUTO_GROUPS[:staff].to_s
    discussion = Fabricate(:topic_with_op)
    whisper = Fabricate(:post, user: developer, topic: discussion, post_type: Post.types[:whisper])
    SiteSetting.academy_moderators_view_hidden_content = true
    expect(moderator.guardian.can_see_whispers?(discussion)).to eq(true)
    expect(moderator.guardian.can_create_whisper?).to eq(false)
    post "/posts.json",
         params: {
           topic_id: discussion.id,
           raw: "A whisper created with viewing permission",
           whisper: true,
         }
    expect(response.status).to eq(403)
    post "/posts.json",
         params: {
           topic_id: discussion.id,
           raw: "A reply that would inherit the whisper type",
           reply_to_post_number: whisper.post_number,
         }
    expect(response.status).to eq(422), response.body
    expect(discussion.posts.count).to eq(2)
  end

  it "retains event creation granted by a nonmanagement group with the switches disabled" do
    publishers = Fabricate(:group)
    publishers.add(moderator)
    SiteSetting.discourse_post_event_allowed_on_groups = publishers.id.to_s
    expect(moderator.reload.guardian.can_create_discourse_post_event?).to eq(true)
    expect(moderator.guardian.academy_can?(:publish_activities)).to eq(false)
  end

  it "creates courses directly only with resource management and revokes it in the same session" do
    post "/isbf/learning/courses.json", params: { name: "Linear algebra", grade: 1 }
    expect(response.status).to eq(403)
    SiteSetting.academy_moderators_manage_resources = true
    post "/isbf/learning/courses.json", params: { name: "Linear algebra", grade: 1 }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("pending")).to eq(false)
    expect(ReviewableIsbfLearningCourse.count).to eq(0)
    SiteSetting.academy_moderators_manage_resources = false
    post "/isbf/learning/courses.json", params: { name: "Calculus", grade: 1 }
    expect(response.status).to eq(403)
  end

  it "deletes and recovers a learning resource with resource management alone" do
    resource =
      Fabricate(
        :post,
        user: member,
        topic: Fabricate(:topic, user: member, category: resource_category),
      )
    SiteSetting.academy_moderators_manage_resources = true

    delete "/t/#{resource.topic_id}.json"
    expect(response.status).to eq(200), response.body
    expect(resource.reload.trashed?).to eq(true)
    put "/t/#{resource.topic_id}/recover.json"
    expect(response.status).to eq(200), response.body
    expect(resource.reload.trashed?).to eq(false)
    expect(resource.topic.reload.trashed?).to eq(false)

    SiteSetting.academy_moderators_manage_resources = false
    delete "/t/#{resource.topic_id}.json"
    expect(response.status).to eq(422)
    expect(resource.reload.trashed?).to eq(false)
  end

  it "preserves the original resource restrictions when the academy role feature is disabled" do
    SiteSetting.academy_roles_enabled = false
    expect(moderator.staff?).to eq(true)
    expect(IsbfLearning.can_manage?(moderator.guardian)).to eq(false)
    expect(IsbfLearning.can_review?(moderator.guardian)).to eq(false)
    post "/isbf/learning/courses.json", params: { name: "Native moderator course", grade: 2 }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("pending")).to eq(false)

    SiteSetting.academy_roles_enabled = true
    expect(IsbfLearning.can_manage?(moderator.guardian)).to eq(false)
    expect(IsbfLearning.can_review?(moderator.guardian)).to eq(false)
    post "/isbf/learning/courses.json", params: { name: "Restricted moderator course", grade: 2 }
    expect(response.status).to eq(403)
  end

  it "approves a requested course without granting direct publication or ordinary content review" do
    resource_category.set_permissions(trust_level_0: :full, staff: :full)
    resource_category.save!
    queued = IsbfLearning::Courses.request(member, name: "Calculus", grade: 1)
    SiteSetting.academy_moderators_review_resources = true
    put "/review/#{queued.id}/perform/approve_course.json", params: { version: queued.version }
    expect(response.status).to eq(200), response.body
    expect(IsbfLearning::Courses.list.map { |course| course.fetch("name") }).to include("Calculus")
    post "/isbf/learning/courses.json", params: { name: "Physics", grade: 1 }
    expect(response.status).to eq(200), response.body
    expect(response.parsed_body.fetch("pending")).to eq(true)
    ordinary = Fabricate(:reviewable_queued_post, target_created_by: member)
    expect(Reviewable.viewable_by(moderator)).not_to include(ordinary)
  end
end
