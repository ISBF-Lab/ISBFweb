# frozen_string_literal: true

RSpec.describe "Nested view resuming a draft from the user activity page" do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  fab!(:op) { Fabricate(:post, topic: topic, user: user, post_number: 1) }

  let(:drafts_page) { PageObjects::Pages::UserActivityDrafts.new }
  let(:nested_view) { PageObjects::Pages::NestedView.new }
  let(:composer) { PageObjects::Components::Composer.new }

  before do
    SiteSetting.nested_replies_enabled = true
    Fabricate(:nested_topic, topic: topic)
    sign_in(user)
  end

  it "lets the user continue an unsent reply from their drafts" do
    Draft.set(
      user,
      "#{Draft::EXISTING_TOPIC}#{topic.id}",
      0,
      { reply: "Resumed nested draft body", action: "reply" }.to_json,
    )

    drafts_page.visit(user)
    drafts_page.resume_draft

    expect(page).to have_current_path(topic.url)
    expect(nested_view).to have_nested_view
    expect(composer).to be_opened
    expect(composer).to have_content("Resumed nested draft body")
  end

  it "lets the user resume a published topic edit by its draft title" do
    draft_body = "Pending changes to the published topic body"
    Draft.set(
      user,
      topic.draft_key,
      0,
      { action: "edit", postId: op.id, reply: draft_body, original_text: op.raw }.to_json,
    )

    drafts_page.visit(user)
    drafts_page.resume_draft_by_title

    expect(page).to have_current_path(topic.url)
    expect(composer).to be_opened
    expect(composer).to have_content(draft_body)

    composer.create

    expect(composer).to be_closed
    expect(page).to have_content(draft_body)
  end

  it "lets the user resume an edit to their reply on another user's post" do
    other_post = Fabricate(:post, topic: topic, post_number: 2)
    reply =
      Fabricate(
        :post,
        topic: topic,
        user: user,
        post_number: 3,
        reply_to_post_number: other_post.post_number,
      )
    draft_body = "Pending changes to my published reply"
    Draft.set(
      user,
      topic.draft_key,
      0,
      {
        action: "edit",
        postId: reply.id,
        reply: draft_body,
        original_text: reply.raw,
        reply_to_post_number: other_post.post_number,
      }.to_json,
    )

    drafts_page.visit(user)
    drafts_page.resume_draft

    expect(page).to have_current_path("#{topic.url}/#{reply.post_number}")
    expect(composer).to be_opened
    expect(composer).to have_content(draft_body)

    composer.create

    expect(composer).to be_closed
    expect(nested_view).to have_post_text(draft_body)
  end
end
