# frozen_string_literal: true

require_relative "../support/fixtures"

RSpec.describe IsbfModeration::ReviewQueue, type: :model do
  fab!(:moderator) { isbf_fabricate(:moderator) }
  fab!(:reporter) { isbf_fabricate(:user) }

  before { SiteSetting.isbf_severe_reports_enabled = true }

  def severe(post, at: Time.zone.now)
    freeze_time(at) do
      IsbfModeration::SevereReport.new(reporter).submit(
        post_id: post.id,
        reason: "This content requires an immediate serious review.",
        confirmed: true,
      )
    end
    post.reviewable_flag
  end

  it "forces a TL0 score into the pending queue without changing the score" do
    reporter.update!(trust_level: 0)
    reviewable = severe(isbf_fabricate(:post))
    reviewable.update!(score: 0.0)
    expect(Reviewable.list_for(moderator, priority: :high).map(&:id)).to include(reviewable.id)
    expect(reviewable.reload.score).to eq(0.0)
  end

  it "prioritizes severe reports before pagination, newest severe first, retaining ordinary sort" do
    ordinary =
      4.times.map { |index| isbf_fabricate(:reviewable_flagged_post, score: 100.0 + index) }
    earlier = severe(isbf_fabricate(:post), at: 2.hours.ago)
    recent = severe(isbf_fabricate(:post), at: 1.hour.ago)

    first_page = Reviewable.list_for(moderator, limit: 2, offset: 0).map(&:id)
    second_page = Reviewable.list_for(moderator, limit: 2, offset: 2).map(&:id)
    expect(first_page).to eq([recent.id, earlier.id])
    expect(second_page).to eq(ordinary.reverse.first(2).map(&:id))
    expect(
      Reviewable.list_for(moderator, limit: 2, offset: 2, sort_order: "score_asc").map(&:id),
    ).to eq(ordinary.first(2).map(&:id))
  end

  it "retains category, target, reporter, score type and status filters" do
    category = isbf_fabricate(:category)
    target = isbf_fabricate(:post, topic: isbf_fabricate(:topic, category: category))
    selected = severe(target)
    excluded = severe(isbf_fabricate(:post))
    expect(Reviewable.list_for(moderator, category_id: category.id).map(&:id)).to eq([selected.id])
    expect(Reviewable.list_for(moderator, topic_id: target.topic_id).map(&:id)).to eq([selected.id])
    expect(Reviewable.list_for(moderator, ids: [excluded.id]).map(&:id)).to eq([excluded.id])
    expect(Reviewable.list_for(moderator, flagged_by: reporter.username).map(&:id)).to include(
      selected.id,
    )
    expect(
      Reviewable.list_for(moderator, score_type: PostActionType.types[:spam]).map(&:id),
    ).not_to include(selected.id)
    expect(Reviewable.list_for(moderator, status: :approved).map(&:id)).not_to include(selected.id)
  end

  it "never grants review queue access to an ordinary user or restricted category outsider" do
    group = isbf_fabricate(:group)
    category = isbf_fabricate(:private_category, group: group)
    author = isbf_fabricate(:user)
    group.users << author
    group.users << reporter
    selected =
      severe(isbf_fabricate(:post, user: author, topic: isbf_fabricate(:topic, category: category)))
    expect(Reviewable.list_for(author).map(&:id)).not_to include(selected.id)
    expect(Reviewable.list_for(moderator).map(&:id)).not_to include(selected.id)
    group.users << moderator
    expect(Reviewable.list_for(moderator.reload).map(&:id)).to include(selected.id)
  end
end
