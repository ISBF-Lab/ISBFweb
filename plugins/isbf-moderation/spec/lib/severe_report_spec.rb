# frozen_string_literal: true

require_relative "../support/fixtures"

RSpec.describe IsbfModeration::SevereReport, type: :model do
  fab!(:reporter) { isbf_fabricate(:user, refresh_auto_groups: true) }
  fab!(:author) { isbf_fabricate(:user) }
  fab!(:moderator) { isbf_fabricate(:moderator) }
  fab!(:forum_post) { isbf_fabricate(:post, user: author) }

  before do
    SiteSetting.isbf_severe_reports_enabled = true
    SiteSetting.flag_post_allowed_groups = Group::AUTO_GROUPS[:trust_level_0].to_s
  end

  def submit
    described_class.new(reporter).submit(
      post_id: forum_post.id,
      reason: "This content poses an immediate and serious concern.",
      confirmed: true,
    )
  end

  it "upgrades an existing ordinary flag without adding a score or changing its cause" do
    result = PostActionCreator.create(reporter, forum_post, :off_topic, context: "Original context")
    expect(result).to be_success
    score = result.reviewable_score
    score.update!(reason: "watched_word", context: "first,second")
    original_score = result.reviewable.score

    submit

    expect(PostAction.flags.where(post_id: forum_post.id, user_id: reporter.id).count).to eq(1)
    expect(result.reviewable.reviewable_scores.count).to eq(1)
    expect(result.reviewable.reload.score).to eq(original_score)
    expect(score.reload.reviewable_score_type).to eq(PostActionType.types[:off_topic])
    expect(score.reason).to eq("watched_word")
    expect(IsbfModeration::Audit.details(score)["original_context"]).to eq("first,second")
    expect(ReviewableScoreSerializer.new(score, scope: moderator.guardian).reason).to include(
      "Severe report",
      "immediate and serious",
    )
  end

  %i[agree_and_keep ignore_and_do_nothing disagree].each do |review_action|
    it "reopens an ordinary #{review_action} report without duplicating its score or losing its history" do
      ordinary =
        PostActionCreator.create(
          reporter,
          forum_post,
          :off_topic,
          context: "Original ordinary explanation",
        )
      reviewable = ordinary.reviewable
      score = ordinary.reviewable_score
      expect(reviewable.perform(moderator, review_action)).to be_success
      expect(forum_post.reload).not_to be_hidden
      original_history_ids = reviewable.history.pluck(:id)
      original_value = score.reload.score
      original_status = score.status
      historical_counts =
        reporter.user_stat.reload.attributes.slice(
          "flags_agreed",
          "flags_disagreed",
          "flags_ignored",
        )

      first = submit

      expect(first[:reviewable_id]).to eq(reviewable.id)
      expect(reviewable.reload).to be_pending
      expect(reviewable.reviewable_scores.count).to eq(1)
      expect(reviewable.reviewable_scores.first.id).to eq(score.id)
      expect(score.reload).to be_pending
      expect(score.score).to eq(original_value)
      expect(reviewable.score).to eq(original_value)
      expect(score.reviewable_score_type).to eq(PostActionType.types[:off_topic])
      details = IsbfModeration::Audit.details(score)
      expect(details["original_context"]).to eq("Original ordinary explanation")
      expect(details.dig("original_resolution", "score", "status")).to eq(original_status)
      expect(details.dig("original_resolution", "score", "reviewed_by_id")).to eq(moderator.id)
      expect(reviewable.history.pluck(:id)).to include(*original_history_ids)
      expect(reviewable.history.last).to be_pending
      expect(
        PostAction.active.flags.where(post_id: forum_post.id, user_id: reporter.id).pluck(:id),
      ).to eq([ordinary.post_action.id])
      expect(
        reporter.user_stat.reload.attributes.slice(
          "flags_agreed",
          "flags_disagreed",
          "flags_ignored",
        ),
      ).to eq(historical_counts)
      context = score.context

      expect(submit).to eq(first)
      expect(score.reload.context).to eq(context)
      expect(reviewable.reviewable_scores.count).to eq(1)
    end
  end

  it "rolls back a settled report reopening and its native history when hiding fails" do
    ordinary = PostActionCreator.off_topic(reporter, forum_post)
    reviewable = ordinary.reviewable
    expect(reviewable.perform(moderator, :ignore_and_do_nothing)).to be_success
    deferred_at = ordinary.post_action.reload.deferred_at
    original_context = ordinary.reviewable_score.reload.context
    history_ids = reviewable.history.pluck(:id)
    allow_any_instance_of(Post).to receive(:hide!).and_raise(
      ActiveRecord::StatementInvalid,
      "failed reopened hide",
    )

    expect { submit }.to raise_error(ActiveRecord::StatementInvalid)
    expect(reviewable.reload).to be_ignored
    expect(ordinary.reviewable_score.reload).to be_ignored
    expect(ordinary.reviewable_score.context).to eq(original_context)
    expect(ordinary.post_action.reload.deferred_at).to eq_time(deferred_at)
    expect(reviewable.history.pluck(:id)).to eq(history_ids)
    expect(forum_post.reload).not_to be_hidden
    expect(IsbfModeration::Hold.persisted?(forum_post)).to eq(false)
  end

  it "rolls back the native flag, reviewable, marker and topic visibility when hiding fails" do
    allow_any_instance_of(Post).to receive(:hide!).and_raise(
      ActiveRecord::StatementInvalid,
      "failed hide",
    )
    expect { submit }.to raise_error(ActiveRecord::StatementInvalid)

    expect(forum_post.reload).not_to be_hidden
    expect(forum_post.topic.reload).to be_visible
    expect(forum_post.reviewable_flag).to be_nil
    expect(PostAction.flags.where(post_id: forum_post.id)).to be_empty
    expect(IsbfModeration::Hold.persisted?(forum_post)).to eq(false)
  end

  it "rolls back an ordinary upgrade when the hold marker cannot be persisted" do
    result = PostActionCreator.off_topic(reporter, forum_post)
    original_context = result.reviewable_score.context
    allow(IsbfModeration::Hold).to receive(:set!).and_raise(
      ActiveRecord::StatementInvalid,
      "failed marker",
    )

    expect { submit }.to raise_error(ActiveRecord::StatementInvalid)
    expect(result.reviewable_score.reload.context).to eq(original_context)
    expect(result.reviewable.reload.payload[IsbfModeration::Hold::PENDING]).to be_nil
    expect(forum_post.reload).not_to be_hidden
  end

  it "uses native disagreement to restore both the content and topic with the marker cleared" do
    submit
    reviewable = forum_post.reviewable_flag
    result = reviewable.perform(moderator, :disagree_and_restore, version: reviewable.version)

    expect(result).to be_success
    expect(reviewable.reload).to be_rejected
    expect(forum_post.reload).not_to be_hidden
    expect(forum_post.topic.reload).to be_visible
    expect(IsbfModeration::Hold.persisted?(forum_post)).to eq(false)
    expect(reviewable.payload[IsbfModeration::Hold::PENDING]).to eq(false)
    expect(reviewable.reviewable_scores.first).to be_disagreed
  end

  it "retains the hold when staff agrees and keeps the content hidden" do
    submit
    reviewable = forum_post.reviewable_flag
    result = reviewable.perform(moderator, :agree_and_keep_hidden, version: reviewable.version)

    expect(result).to be_success
    expect(reviewable.reload).to be_approved
    expect(forum_post.reload).to be_hidden
    expect(IsbfModeration::Hold.persisted?(forum_post)).to eq(true)
    expect(forum_post.unhide!).to eq(false)
    expect(forum_post.reload).to be_hidden
  end

  it "retains the hold when staff agrees and deletes the content" do
    submit
    reviewable = forum_post.reviewable_flag
    result = reviewable.perform(moderator, :delete_and_agree, version: reviewable.version)
    expect(result).to be_success
    expect(forum_post.reload).to be_trashed
    expect(IsbfModeration::Hold.persisted?(forum_post)).to eq(true)
  end

  it "requires a valid native review action and rolls back failed restore attempts" do
    submit
    reviewable = forum_post.reviewable_flag
    expect { reviewable.perform_disagree(moderator, {}) }.to raise_error(Discourse::InvalidAccess)
    expect { reviewable.perform(moderator, :does_not_exist) }.to raise_error(
      Reviewable::InvalidAction,
    )
    allow(reviewable).to receive(:perform_disagree).and_wrap_original do |method, *arguments|
      method.call(*arguments)
      Reviewable::PerformResult.new(reviewable, :failure)
    end
    result = reviewable.perform(moderator, :disagree_and_restore, version: reviewable.version)
    expect(result).not_to be_success
    expect(forum_post.reload).to be_hidden
    expect(forum_post.topic.reload).not_to be_visible
    expect(IsbfModeration::Hold.persisted?(forum_post)).to eq(true)
    expect(reviewable.reload).to be_pending
  end

  it "does not let author edits discard flags or lift the hold" do
    submit
    SiteSetting.cooldown_minutes_after_hiding_posts = 0
    expect(
      PostRevisor.new(forum_post).revise!(author, raw: "Edited body still requires staff review."),
    ).to eq(true)
    expect(forum_post.reload).to be_hidden
    expect(forum_post.reviewable_flag.reviewable_scores.count).to eq(1)
    expect(PostAction.active.flags.where(post_id: forum_post.id).count).to eq(1)
  end

  it "does not let flag withdrawal discard severe audit evidence or unhide content" do
    submit
    result = PostActionDestroyer.destroy(reporter, forum_post, :notify_moderators)
    expect(result).not_to be_success
    expect(result.forbidden).to eq(true)
    expect(forum_post.reload).to be_hidden
    expect(forum_post.reviewable_flag.reviewable_scores.count).to eq(1)
  end

  it "uses a persisted hold check even with a stale model and keeps protection when disabled" do
    stale_post = Post.find(forum_post.id)
    stale_post.custom_fields
    submit
    SiteSetting.isbf_severe_reports_enabled = false
    expect(stale_post.unhide!).to eq(false)
    expect(forum_post.reload).to be_hidden
    expect(author.guardian.can_see_hidden_post?(forum_post)).to eq(false)
  end
end
