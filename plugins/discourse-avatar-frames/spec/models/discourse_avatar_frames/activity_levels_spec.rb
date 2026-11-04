# frozen_string_literal: true

RSpec.describe DiscourseAvatarFrames::Frame do
  include ActivityLevelsSpecHelpers

  fab!(:member, :user)
  fab!(:admin)
  fab!(:official_group, :group)
  fab!(:official_category, :category)
  let(:document) do
    activity_rules(
      levels: [
        activity_tier(identifier: "reader", conditions: [activity_condition("posts_read", 1)]),
        activity_tier(identifier: "regular", conditions: [activity_condition("posts_read", 10)]),
      ],
    ).merge("cosmetics" => activity_cosmetics(avatar_minimum: "reader"))
  end

  before do
    reset_activity_appearance_caches
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.avatar_frames_enabled = true
    persist_activity_rules(document)
  end

  after { reset_activity_appearance_caches }

  describe ".available_for" do
    let(:public_frame) do
      Fabricate(:avatar_frame, access_mode: "public", minimum_activity_level_id: "regular")
    end
    let(:awarded_frame) { Fabricate(:avatar_frame, minimum_activity_level_id: "reader") }
    let(:unawarded_frame) { Fabricate(:avatar_frame, minimum_activity_level_id: "reader") }

    before { Fabricate(:avatar_frame_grant, frame: awarded_frame, user: member) }

    it "applies global and per-frame thresholds without replacing award ownership" do
      frames = [public_frame, awarded_frame, unawarded_frame]
      assign_activity_level(member, identifier: "legacy-0", number: 0)
      expect(described_class.available_for(member).where(id: frames.map(&:id))).to be_empty

      assign_activity_level(member, identifier: "reader", number: 1)
      expect(described_class.available_for(member).where(id: frames.map(&:id))).to contain_exactly(
        awarded_frame,
      )

      assign_activity_level(member, identifier: "regular", number: 2)
      expect(described_class.available_for(member).where(id: frames.map(&:id))).to contain_exactly(
        public_frame,
        awarded_frame,
      )
    end

    it "retains staff level exceptions while still requiring a private frame grant" do
      frames = [public_frame, awarded_frame, unawarded_frame]
      assign_activity_level(admin, identifier: "legacy-0", number: 0)
      expect(described_class.available_for(admin).where(id: frames.map(&:id))).to contain_exactly(
        public_frame,
      )

      Fabricate(:avatar_frame_grant, frame: awarded_frame, user: admin)

      expect(described_class.available_for(admin).where(id: frames.map(&:id))).to contain_exactly(
        public_frame,
        awarded_frame,
      )
    end
  end

  describe "#save!" do
    it "preserves explicit validation skipping for unrelated stale errors" do
      frame = Fabricate(:avatar_frame, minimum_activity_level_id: "reader")
      frame.errors.add(:name, "An earlier name validation failed")
      frame.description = "Saved without repeating unrelated validation"

      expect(frame.save(validate: false)).to eq(true)
      expect(frame.reload.description).to eq("Saved without repeating unrelated validation")
    end

    it "rechecks a previously validated binding after its level is removed" do
      frame = Fabricate(:avatar_frame)
      frame.minimum_activity_level_id = "regular"
      expect(frame).to be_valid
      validated_configuration = DiscourseAcademyRoles::ActivityLevels::Cosmetics.configuration
      changed = DiscourseAcademyRoles::ActivityLevels::Configuration.current.document.deep_dup
      changed["levels"].pop
      persist_activity_rules(changed)
      DiscourseAcademyRoles::ActivityLevels::Current.configuration = validated_configuration

      expect(frame.save(validate: false)).to be_falsey
      expect(frame.errors[:minimum_activity_level_id]).to include(
        I18n.t("avatar_frames.levels.invalid"),
      )
      expect(frame.reload.minimum_activity_level_id).to be_nil
    end

    it "rejects a removed level through the public save operation" do
      frame = Fabricate(:avatar_frame)

      expect(frame.update(minimum_activity_level_id: "removed")).to eq(false)
      expect(frame.errors[:minimum_activity_level_id]).to include(
        I18n.t("avatar_frames.levels.invalid"),
      )
      expect(frame.reload.minimum_activity_level_id).to be_nil
    end

    it "protects a frame requirement when deleting its referenced level" do
      frame = Fabricate(:avatar_frame, minimum_activity_level_id: "regular")
      configuration = DiscourseAcademyRoles::ActivityLevels::Configuration.current
      changed = configuration.document.deep_dup
      changed["levels"].pop

      expect { persist_activity_rules(changed) }.to raise_error(
        DiscourseAcademyRoles::ActivityLevels::ReferencedLevel,
        /#{Regexp.escape(frame.name)}/,
      )
      expect(DiscourseAcademyRoles::ActivityLevels::Configuration.current.revision).to eq(
        configuration.revision,
      )

      frame.update!(minimum_activity_level_id: "reader")
      expect(persist_activity_rules(changed).levels.map { |level| level["id"] }).to eq(
        %w[legacy-0 reader],
      )
    end
  end
end
