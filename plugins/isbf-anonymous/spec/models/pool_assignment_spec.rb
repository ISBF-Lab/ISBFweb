# frozen_string_literal: true

RSpec.describe IsbfAnonymous::PoolAssignment do
  fab!(:user)

  describe ".author_for!" do
    it "keeps the author for seven days from first use and then selects a different author" do
      freeze_time
      started_at = Time.current
      author = described_class.author_for!(user)
      assignment = described_class.find_by!(master_user_id: user.id)

      expect(SiteSetting.isbf_anonymous_pool_size).to eq(256)
      expect(assignment.started_at).to eq_time(started_at)
      expect(assignment.expires_at).to eq_time(started_at + 7.days)

      freeze_time(started_at + 7.days - 1.second)
      expect(described_class.author_for!(user)).to eq(author)
      expect(assignment.reload.expires_at).to eq_time(started_at + 7.days)

      freeze_time(started_at + 7.days)
      expect(described_class.author_for!(user)).not_to eq(author)
      expect(assignment.reload.started_at).to eq_time(Time.current)
      expect(assignment.expires_at).to eq_time(7.days.from_now)
      expect(described_class.where(master_user_id: user.id).count).to eq(1)
    end

    it "bounds account growth over repeated rotations" do
      SiteSetting.isbf_anonymous_pool_size = 2
      freeze_time

      expect do
        6.times do
          described_class.author_for!(user)
          freeze_time(7.days.from_now)
        end
      end.to change { User.count }.by(2)

      expect(IsbfAnonymous::PoolAccount.pluck(:slot)).to contain_exactly(0, 1)
    end

    it "reuses the configured duration and allows expansion without changing an active assignment" do
      SiteSetting.anonymous_account_duration_minutes = 60
      freeze_time
      author = described_class.author_for!(user)

      SiteSetting.isbf_anonymous_pool_size = 512

      expect(described_class.author_for!(user)).to eq(author)
      expect(described_class.find_by!(master_user_id: user.id).expires_at).to eq_time(
        1.hour.from_now,
      )
      expect { SiteSetting.isbf_anonymous_pool_size = 256 }.to raise_error(
        Discourse::InvalidParameters,
      )
    end
  end

  describe "pool size validation" do
    it "enforces limits and keeps every allocated slot available" do
      expect { SiteSetting.isbf_anonymous_pool_size = 1 }.to raise_error(
        Discourse::InvalidParameters,
      )
      expect { SiteSetting.isbf_anonymous_pool_size = 4097 }.to raise_error(
        Discourse::InvalidParameters,
      )
      SiteSetting.isbf_anonymous_pool_size = 4
      IsbfAnonymous::PoolAccount.for_slot!(3)

      expect { SiteSetting.isbf_anonymous_pool_size = 3 }.to raise_error(
        Discourse::InvalidParameters,
      )
      expect(SiteSetting.isbf_anonymous_pool_size).to eq(4)
    end
  end
end
