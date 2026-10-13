# frozen_string_literal: true

Fabricator(:isbf_account_link, class_name: "IsbfAccountSwitch::AccountLink") do
  user_a { Fabricate(:user) }
  user_b { Fabricate(:user) }
  requester { |attributes| attributes[:user_a] }

  after_build { |link| link.user_a, link.user_b = [link.user_a, link.user_b].sort_by(&:id) }
end
