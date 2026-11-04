# frozen_string_literal: true

Fabricator(:activity_anonymous_identity, class_name: "AnonymousUser") do
  master_user(fabricator: :user)
  user
  active true
end

Fabricator(:activity_pool_account, class_name: "IsbfAnonymous::PoolAccount") do
  user
  slot { sequence(:activity_anonymous_slot) }
end

Fabricator(:activity_level_badge, from: :manually_grantable_badge) do
  enabled true
  multiple_grant false
  trigger Badge::Trigger::None
end
