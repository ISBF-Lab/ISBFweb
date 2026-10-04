# frozen_string_literal: true

RSpec.describe TopicsController do
  fab!(:user)

  let(:category) { Fabricate(:category, name: "general") }

  before do
    SiteSetting.login_required = false
    SiteSetting.isbf_explore_enabled = true
    SiteSetting.slug_generation_method = "none"
    SiteSetting.tagging_enabled = true
  end

  def filtered_topic_ids(query, page: 0)
    get "/filter.json", params: { q: query, page: page }
    expect(response).to have_http_status(:ok)
    response.parsed_body.fetch("topic_list").fetch("topics").map { |topic| topic.fetch("id") }
  end

  it "filters by category ID when category slugs are empty" do
    selected = Fabricate(:topic, category: category)
    Fabricate(:topic, category: Fabricate(:category))

    expect(Slug.for("general", "")).to eq("")
    expect(category.slug).to be_blank
    expect(filtered_topic_ids("isbf-category:#{category.id}")).to contain_exactly(selected.id)

    sign_in(user)
    expect(filtered_topic_ids("isbf-category:#{category.id}")).to contain_exactly(selected.id)
  end

  it "matches only the selected category, excluding its children and parent" do
    child = Fabricate(:category, parent_category: category)
    parent_topic = Fabricate(:topic, category: category)
    child_topic = Fabricate(:topic, category: child)

    expect(filtered_topic_ids("isbf-category:#{category.id}")).to contain_exactly(parent_topic.id)
    expect(filtered_topic_ids("isbf-category:#{child.id}")).to contain_exactly(child_topic.id)
  end

  it "returns no restricted category topics to guests or ordinary users" do
    restricted = Fabricate(:private_category, group: Fabricate(:group))
    Fabricate(:topic, category: restricted)
    Fabricate(:topic, category: category)

    expect(filtered_topic_ids("isbf-category:#{restricted.id}")).to be_empty
    sign_in(user)
    expect(filtered_topic_ids("isbf-category:#{restricted.id}")).to be_empty
  end

  it "allows staff to filter a restricted category" do
    restricted = Fabricate(:private_category, group: Fabricate(:group))
    selected = Fabricate(:topic, category: restricted)
    Fabricate(:topic, category: category)
    sign_in(Fabricate(:admin))

    expect(filtered_topic_ids("isbf-category:#{restricted.id}")).to contain_exactly(selected.id)
  end

  it "returns no topics for malformed IDs or multiple values and tokens" do
    Fabricate(:topic, category: category)
    invalid_queries = [
      'isbf-category:""',
      "isbf-category:0",
      "isbf-category:-1",
      "isbf-category:01",
      "isbf-category:+1",
      "isbf-category:1.0",
      "isbf-category:general",
      "isbf-category:2147483648",
      "isbf-category:999999999999999999999",
      "isbf-category:#{category.id},#{category.id}",
      "isbf-category:#{category.id} isbf-category:#{category.id}",
      "isbf-category:#{category.id} isbf-category:2147483647",
    ]

    invalid_queries.each { |query| expect(filtered_topic_ids(query)).to be_empty }
  end

  it "returns no topics for deleted or missing category IDs" do
    deleted = Fabricate(:category)
    deleted_id = deleted.id
    deleted.destroy!
    Fabricate(:topic, category: category)

    expect(filtered_topic_ids("isbf-category:#{deleted_id}")).to be_empty
    expect(filtered_topic_ids("isbf-category:2147483647")).to be_empty
  end

  it "intersects the category with native tag OR filtering" do
    first_tag = Fabricate(:tag)
    second_tag = Fabricate(:tag)
    first = Fabricate(:topic, category: category, tags: [first_tag])
    second = Fabricate(:topic, category: category, tags: [second_tag])
    Fabricate(:topic, category: category)
    Fabricate(:topic, category: Fabricate(:category), tags: [first_tag, second_tag])

    expect(
      filtered_topic_ids("isbf-category:#{category.id} tag:#{first_tag.name},#{second_tag.name}"),
    ).to contain_exactly(first.id, second.id)
  end

  it "retains native pagination within the selected category" do
    page_size = TopicQuery::DEFAULT_PER_PAGE_COUNT
    selected = Fabricate.times(page_size + 1, :topic, category: category)
    Fabricate(:topic, category: Fabricate(:category))
    query = "isbf-category:#{category.id} order:activity"

    first_page = filtered_topic_ids(query)
    second_page = filtered_topic_ids(query, page: 1)

    expect(first_page.size).to eq(page_size)
    expect(second_page.size).to eq(1)
    expect(first_page & second_page).to be_empty
    expect(first_page + second_page).to match_array(selected.map(&:id))
  end

  it "retains native hot ordering within the selected category" do
    first = Fabricate(:topic, category: category)
    second = Fabricate(:topic, category: category)
    Fabricate(:topic, category: Fabricate(:category))

    expect(filtered_topic_ids("isbf-category:#{category.id} order:hot")).to contain_exactly(
      first.id,
      second.id,
    )
  end

  it "advertises the category ID filter only when enabled" do
    get "/site.json"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["isbf_explore_category_id_filter"]).to eq(true)

    SiteSetting.isbf_explore_enabled = false
    get "/site.json"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).not_to have_key("isbf_explore_category_id_filter")
  end
end
