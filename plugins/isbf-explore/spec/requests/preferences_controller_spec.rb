# frozen_string_literal: true

RSpec.describe IsbfExplore::PreferencesController do
  fab!(:user)
  fab!(:other_user, :user)
  fab!(:category)
  fab!(:tag)

  before do
    SiteSetting.isbf_explore_enabled = true
    SiteSetting.tagging_enabled = true
    sign_in(user)
  end

  def read_preferences(**params)
    get "/isbf/explore/preferences.json", params: params
    response.parsed_body
  end

  def write_preferences(**overrides)
    put "/isbf/explore/preferences.json",
        params: { category_ids: [category.id], tag_ids: [tag.id], order: "hot" }.merge(overrides),
        as: :json
    response.parsed_body
  end

  def stored_preferences(account = user)
    PluginStore.get("isbf-explore", account.id.to_s)
  end

  it "requires login for both endpoints" do
    sign_out
    reset!

    read_preferences
    expect(response).not_to have_http_status(:ok)
    write_preferences
    expect(response).not_to have_http_status(:ok)
    expect(stored_preferences).to be_nil
  end

  it "requires an enabled plugin for both endpoints" do
    SiteSetting.isbf_explore_enabled = false

    read_preferences
    expect(response).not_to have_http_status(:ok)
    write_preferences
    expect(response).not_to have_http_status(:ok)
    expect(stored_preferences).to be_nil
  end

  it "returns empty selections and activity order without creating a record" do
    expect(read_preferences).to eq(
      "preferences" => {
        "category_ids" => [],
        "tag_ids" => [],
        "order" => "activity",
      },
      "tags" => [],
    )
    expect(response).to have_http_status(:ok)
    expect(stored_preferences).to be_nil
  end

  it "persists a complete selection and returns selected tag metadata" do
    body = write_preferences

    expect(response).to have_http_status(:ok)
    expect(body["preferences"]).to eq(
      "category_ids" => [category.id],
      "tag_ids" => [tag.id],
      "order" => "hot",
    )
    expect(body["tags"]).to eq(
      [{ "id" => tag.id, "name" => tag.name, "slug" => tag.slug.presence || tag.name }],
    )
    expect(read_preferences).to eq(body)
    expect(stored_preferences.deep_stringify_keys).to eq(body["preferences"])
  end

  it "deduplicates IDs while preserving the requested order" do
    second_category = Fabricate(:category)
    second_tag = Fabricate(:tag)

    body =
      write_preferences(
        category_ids: [second_category.id, category.id, second_category.id],
        tag_ids: [second_tag.id, tag.id, second_tag.id],
      )

    expect(response).to have_http_status(:ok)
    expect(body.dig("preferences", "category_ids")).to eq([second_category.id, category.id])
    expect(body.dig("preferences", "tag_ids")).to eq([second_tag.id, tag.id])
    expect(body["tags"].map { |selected_tag| selected_tag["id"] }).to eq([second_tag.id, tag.id])
  end

  it "uses the latest successful complete replacement, including empty selections" do
    write_preferences
    latest = write_preferences(category_ids: [], tag_ids: [], order: "activity")

    expect(response).to have_http_status(:ok)
    expect(read_preferences).to eq(latest)
    expect(latest["preferences"]).to eq(
      "category_ids" => [],
      "tag_ids" => [],
      "order" => "activity",
    )
  end

  it "restores the same account's preferences in a new session" do
    saved = write_preferences
    sign_out
    reset!
    sign_in(user)

    expect(read_preferences).to eq(saved)
    expect(response).to have_http_status(:ok)
  end

  it "isolates accounts and rejects a forged user ID on writes" do
    original = write_preferences
    sign_in(other_user)

    expect(read_preferences(user_id: user.id)["preferences"]).to eq(
      "category_ids" => [],
      "tag_ids" => [],
      "order" => "activity",
    )
    write_preferences(user_id: user.id)
    expect(response).to have_http_status(:bad_request)
    expect(stored_preferences(other_user)).to be_nil
    expect(stored_preferences.deep_stringify_keys).to eq(original["preferences"])

    own = write_preferences(category_ids: [], tag_ids: [], order: "activity")
    expect(response).to have_http_status(:ok)
    sign_in(user)
    expect(read_preferences).to eq(original)
    sign_in(other_user)
    expect(read_preferences).to eq(own)
  end

  it "filters inaccessible categories and tags before persisting a valid write" do
    private_category = Fabricate(:private_category, group: Fabricate(:group))
    hidden_tag = Fabricate(:tag)
    Fabricate(:tag_group, permissions: { "staff" => 1 }, tags: [hidden_tag])

    body =
      write_preferences(
        category_ids: [private_category.id, category.id],
        tag_ids: [hidden_tag.id, tag.id],
      )

    expect(response).to have_http_status(:ok)
    expect(body.dig("preferences", "category_ids")).to eq([category.id])
    expect(body.dig("preferences", "tag_ids")).to eq([tag.id])
    expect(body["tags"].map { |selected_tag| selected_tag["id"] }).to eq([tag.id])
    expect(stored_preferences.deep_stringify_keys).to eq(body["preferences"])
  end

  it "filters missing IDs on writes and deleted records on subsequent reads" do
    body =
      write_preferences(
        category_ids: [category.id, 2_147_483_647],
        tag_ids: [tag.id, 2_147_483_647],
      )
    expect(response).to have_http_status(:ok)
    expect(body.dig("preferences", "category_ids")).to eq([category.id])
    expect(body.dig("preferences", "tag_ids")).to eq([tag.id])
    category.destroy!
    tag.destroy!

    expect(read_preferences).to eq(
      "preferences" => {
        "category_ids" => [],
        "tag_ids" => [],
        "order" => "hot",
      },
      "tags" => [],
    )
    expect(response).to have_http_status(:ok)
  end

  it "rechecks permissions on reads and restores saved IDs when membership returns" do
    group = Fabricate(:group)
    private_category = Fabricate(:private_category, group: group)
    hidden_tag = Fabricate(:tag)
    Fabricate(:tag_group, permissions: { group.name => 1 }, tags: [hidden_tag])
    group.users << user
    sign_in(user.reload)
    original = write_preferences(category_ids: [private_category.id], tag_ids: [hidden_tag.id])
    expect(response).to have_http_status(:ok)
    expect(original.dig("preferences", "category_ids")).to eq([private_category.id])
    expect(original.dig("preferences", "tag_ids")).to eq([hidden_tag.id])

    GroupUser.where(group_id: group.id, user_id: user.id).destroy_all
    sign_in(user.reload)
    expect(read_preferences).to eq(
      "preferences" => {
        "category_ids" => [],
        "tag_ids" => [],
        "order" => "hot",
      },
      "tags" => [],
    )
    expect(stored_preferences.deep_stringify_keys).to eq(original["preferences"])

    group.users << user
    sign_in(user.reload)
    expect(read_preferences).to eq(original)
  end

  it "preserves saved preferences when orders or fields are invalid" do
    original = write_preferences
    ["latest", "", nil, 1, true].each do |invalid_order|
      write_preferences(order: invalid_order)
      expect(response).to have_http_status(:bad_request)
      expect(stored_preferences.deep_stringify_keys).to eq(original["preferences"])
    end

    write_preferences(watching: true)
    expect(response).to have_http_status(:bad_request)
    put "/isbf/explore/preferences.json", params: { order: "activity" }, as: :json
    expect(response).to have_http_status(:bad_request)
    expect(read_preferences).to eq(original)
  end

  it "rejects non-integer, non-positive and malformed ID selections" do
    original = write_preferences
    invalid_selections = [nil, "1", {}, ["1"], [1.5], [true], [0], [-1], [2_147_483_648]]

    %i[category_ids tag_ids].each do |field|
      invalid_selections.each do |selection|
        write_preferences(**{ field => selection })
        expect(response).to have_http_status(:bad_request)
        expect(stored_preferences.deep_stringify_keys).to eq(original["preferences"])
      end
    end
  end

  it "accepts up to fifty IDs per field and rejects longer arrays before deduplication" do
    write_preferences(category_ids: [category.id] * 50, tag_ids: [tag.id] * 50)
    expect(response).to have_http_status(:ok)
    original = read_preferences

    write_preferences(category_ids: [category.id] * 51)
    expect(response).to have_http_status(:bad_request)
    write_preferences(tag_ids: [tag.id] * 51)
    expect(response).to have_http_status(:bad_request)
    expect(read_preferences).to eq(original)
  end

  it "preserves the previous preferences if storage fails" do
    original = write_preferences
    allow(PluginStore).to receive(:set).and_raise(
      ActiveRecord::StatementInvalid,
      "storage unavailable",
    )

    write_preferences(category_ids: [], tag_ids: [], order: "activity")
    expect(response).to have_http_status(:internal_server_error)
    expect(read_preferences).to eq(original)
  end

  it "does not modify native category or tag notification settings" do
    category_state =
      CategoryUser.where(user_id: user.id).order(:id).pluck(:category_id, :notification_level)
    tag_state = TagUser.where(user_id: user.id).order(:id).pluck(:tag_id, :notification_level)

    write_preferences
    read_preferences

    expect(
      CategoryUser.where(user_id: user.id).order(:id).pluck(:category_id, :notification_level),
    ).to eq(category_state)
    expect(TagUser.where(user_id: user.id).order(:id).pluck(:tag_id, :notification_level)).to eq(
      tag_state,
    )
  end
end
