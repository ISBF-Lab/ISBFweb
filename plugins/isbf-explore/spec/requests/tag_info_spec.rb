# frozen_string_literal: true

RSpec.describe TagsController do
  fab!(:user)
  fab!(:tag)
  fab!(:hidden_tag, :tag)

  before do
    SiteSetting.login_required = false
    SiteSetting.isbf_explore_enabled = true
    SiteSetting.tagging_enabled = true
    Fabricate(:tag_group, permissions: { "staff" => 1 }, tags: [hidden_tag])
  end

  def tag_info(selected_tag)
    get "/tag/#{selected_tag.id}/info.json"
    response.parsed_body["tag_info"]
  end

  it "includes the canonical name for a visible tag as a guest" do
    info = tag_info(tag)

    expect(response).to have_http_status(:ok)
    expect(info["isbf_explore_filter_name"]).to eq(tag.name)
  end

  it "includes the canonical name for a visible tag as a signed-in user" do
    sign_in(user)
    info = tag_info(tag)

    expect(response).to have_http_status(:ok)
    expect(info["isbf_explore_filter_name"]).to eq(tag.name)
  end

  it "preserves native restrictions for hidden tags for guests and regular users" do
    tag_info(hidden_tag)
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.to_s).not_to include("isbf_explore_filter_name")

    sign_in(user)
    tag_info(hidden_tag)
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.to_s).not_to include("isbf_explore_filter_name")
  end

  it "includes a hidden tag's canonical name when native permissions allow it" do
    sign_in(Fabricate(:admin))
    info = tag_info(hidden_tag)

    expect(response).to have_http_status(:ok)
    expect(info["isbf_explore_filter_name"]).to eq(hidden_tag.name)
  end

  it "omits the extension when the plugin is disabled" do
    SiteSetting.isbf_explore_enabled = false
    info = tag_info(tag)

    expect(response).to have_http_status(:ok)
    expect(info).not_to have_key("isbf_explore_filter_name")
  end
end
