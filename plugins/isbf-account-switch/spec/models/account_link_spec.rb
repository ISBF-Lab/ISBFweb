# frozen_string_literal: true

RSpec.describe IsbfAccountSwitch::AccountLink do
  fab!(:first_user, :user)
  fab!(:second_user, :user)

  it "stores every pair in canonical order" do
    user_a_id, user_b_id = described_class.ordered_ids(second_user.id, first_user.id)
    link =
      described_class.create!(
        user_a_id: user_a_id,
        user_b_id: user_b_id,
        requester_id: second_user.id,
      )

    expect(link.user_a_id).to be < link.user_b_id
  end

  it "does not create a transitive association" do
    third_user = Fabricate(:user)
    first_ids = described_class.ordered_ids(first_user.id, second_user.id)
    second_ids = described_class.ordered_ids(second_user.id, third_user.id)
    described_class.create!(
      user_a_id: first_ids[0],
      user_b_id: first_ids[1],
      requester_id: first_user.id,
    )
    described_class.create!(
      user_a_id: second_ids[0],
      user_b_id: second_ids[1],
      requester_id: second_user.id,
    )

    expect(described_class.for_user(first_user.id).count).to eq(1)
    expect(described_class.for_user(first_user.id).first.other_user(first_user)).to eq(second_user)
  end
end
