# frozen_string_literal: true

RSpec.describe Admin::UsersController do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  it "returns the activity level separately from the internal trust level" do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    DiscourseAcademyRoles.lock_member_trust_level(member)
    member.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD] = 3
    member.save_custom_fields
    sign_in(admin)

    get "/admin/users/#{member.id}.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["trust_level"]).to eq(0)
    expect(response.parsed_body["academy_activity_level"]).to eq(3)
  end
end
