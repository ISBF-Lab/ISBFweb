# frozen_string_literal: true

RSpec.describe IsbfAnonymous::AuthorsController do
  fab!(:developer, :admin)
  fab!(:moderator) { Fabricate(:moderator, approved: true, refresh_auto_groups: true) }
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:published, :post)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    published.custom_fields[IsbfAnonymous::POST_FIELD] = true
    published.custom_fields[IsbfAnonymous::OWNER_FIELD] = member.id
    published.save_custom_fields
  end

  it "allows lookup only while its independent switch is enabled in the same session" do
    sign_in(moderator)
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(403)
    SiteSetting.academy_moderators_trace_anonymous = true
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("author", "id")).to eq(member.id)
    expect(response.body).not_to include(member.email)
    SiteSetting.academy_moderators_trace_anonymous = false
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(403)
  end

  it "still requires visibility of internal and hidden content" do
    category = Fabricate(:category)
    category.set_permissions(staff: :full)
    category.save!
    published.topic.update!(category: category)
    SiteSetting.academy_moderators_trace_anonymous = true
    sign_in(moderator)
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(403)
    SiteSetting.academy_moderators_access_internal_boards = true
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(200)
    published.update!(hidden: true)
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(403)
    SiteSetting.academy_moderators_view_hidden_content = true
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(200)
  end

  it "requires both review and tracing permissions for queued anonymous content" do
    queued =
      Fabricate(
        :reviewable_queued_post,
        target_created_by: member,
        payload: {
          "raw" => "Pending anonymous discussion",
          "isbf_anonymous" => "true",
          IsbfAnonymous::OWNER_FIELD => member.id,
        },
      )
    sign_in(moderator)
    SiteSetting.academy_moderators_trace_anonymous = true
    get "/isbf-anonymous/api/queued-posts/#{queued.id}/author.json"
    expect(response.status).to eq(404)
    SiteSetting.academy_moderators_review_content = true
    get "/isbf-anonymous/api/queued-posts/#{queued.id}/author.json"
    expect(response.status).to eq(200)
    SiteSetting.academy_moderators_trace_anonymous = false
    get "/isbf-anonymous/api/queued-posts/#{queued.id}/author.json"
    expect(response.status).to eq(403)
  end

  it "requires hidden access when looking up an author of user-deleted content" do
    published.update!(user_deleted: true)
    SiteSetting.academy_moderators_trace_anonymous = true
    sign_in(moderator)

    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(403)
    SiteSetting.academy_moderators_view_hidden_content = true
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(200)
  end

  it "preserves developer access and denies ordinary members even with tracing enabled" do
    SiteSetting.academy_moderators_trace_anonymous = true
    sign_in(member)
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(403)
    sign_in(developer)
    get "/isbf-anonymous/api/posts/#{published.id}/author.json"
    expect(response.status).to eq(200)
  end
end
