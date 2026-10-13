# frozen_string_literal: true

RSpec.describe InviteRedeemer do
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  fab!(:registration, :academy_student_registration)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
  end

  describe "#redeem" do
    it "allows a staged email identity to become the bound account" do
      staged_user = Fabricate(:staged, email: "stagedstudent@example.com")

      user =
        described_class.new(
          invite: registration.invite,
          email: staged_user.email,
          password: "verystrongpassword"
        ).redeem

      expect(user.id).to eq(staged_user.id)
      expect(user).not_to be_staged
      expect(registration.reload.user).to eq(user)
    end

    it "allows at most one account to redeem the same student number concurrently" do
      user_count = User.count
      outcomes = Queue.new
      invite_id = registration.invite_id

      threads =
        2.times.map do |number|
          Thread.new do
            user =
              described_class.new(
                invite: Invite.find(invite_id),
                email: "concurrentstudent#{number}@example.com",
                password: "verystrongpassword"
              ).redeem
            outcomes << user
          rescue ActiveRecord::RecordNotSaved,
                 ActiveRecord::LockWaitTimeout => error
            outcomes << error
          end
        end
      threads.each(&:join)
      results = 2.times.map { outcomes.pop }

      expect(results.grep(User).length).to eq(1)
      expect(User.count).to eq(user_count + 1)
      expect(registration.reload).to be_registered
      expect(registration.invite.redemption_count).to eq(1)
      expect(
        registration.invite.invited_users.pluck(:user_id)
      ).to contain_exactly(registration.user_id)
    end
  end
end
