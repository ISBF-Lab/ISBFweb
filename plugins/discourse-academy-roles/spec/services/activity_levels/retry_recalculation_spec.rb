# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::ActivityLevels::RetryRecalculation do
  include ActivityLevelsSpecHelpers

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:acting_user, :admin)
    fab!(:official_group, :group)
    fab!(:official_category, :category)
    let(:params) { {} }
    let(:dependencies) { { guardian: acting_user.guardian } }

    before do
      DiscourseAcademyRoles::ActivityLevels::Current.reset
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    after { DiscourseAcademyRoles::ActivityLevels::Current.reset }

    context "when the actor is a moderator" do
      fab!(:acting_user, :moderator)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when the actor is an ordinary member" do
      fab!(:acting_user, :user)

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when the feature is disabled" do
      before { SiteSetting.academy_roles_enabled = false }

      it { is_expected.to fail_a_policy(:can_manage) }
    end

    context "when rules have not been initialized" do
      it { is_expected.to fail_a_policy(:rules_initialized) }
    end

    context "when the current run has failed" do
      before do
        persist_activity_rules(DiscourseAcademyRoles::ActivityLevels::Configuration.defaults)
        state = DiscourseAcademyRoles::ActivityLevels::Recalculation.current
        state["status"] = "failed"
        DiscourseAcademyRoles::ActivityLevels.write!(
          DiscourseAcademyRoles::ActivityLevels::RUN_KEY,
          state,
        )
      end

      it "creates a fresh queued run for the current rules" do
        previous = DiscourseAcademyRoles::ActivityLevels::Recalculation.current

        expect { result }.to change { Jobs::AcademyRecalculateActivityLevels.jobs.size }.by(1)
        expect(result).to run_successfully
        state = DiscourseAcademyRoles::ActivityLevels::Recalculation.current
        expect(state).to include("revision" => 1, "status" => "queued", "processed" => 0)
        expect(state["id"]).not_to eq(previous["id"])
      end
    end

    context "when a run is already queued" do
      before do
        persist_activity_rules(DiscourseAcademyRoles::ActivityLevels::Configuration.defaults)
      end

      it "keeps the same run identity while ensuring it is enqueued" do
        previous = DiscourseAcademyRoles::ActivityLevels::Recalculation.current

        expect(result).to run_successfully
        expect(DiscourseAcademyRoles::ActivityLevels::Recalculation.current["id"]).to eq(
          previous["id"],
        )
      end
    end
  end
end
