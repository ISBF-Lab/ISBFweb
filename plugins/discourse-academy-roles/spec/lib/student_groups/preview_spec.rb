# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentGroups::Preview do
  fab!(:admin)
  fab!(:target, :group)
  fab!(:source, :group)

  before { SiteSetting.academy_roles_enabled = true }

  describe ".create" do
    it "matches registered accounts by exact student number without altering invites or bindings" do
      registered = Fabricate(:registered_academy_student, student_number: "000123")
      pending = Fabricate(:academy_student_registration, student_number: "000124")
      original_invites = Invite.order(:id).map(&:attributes)
      original_bindings = DiscourseAcademyRoles::StudentRegistration.order(:id).map(&:attributes)

      batch =
        described_class.create(
          actor: admin,
          mode: "groups",
          input_kind: "list",
          student_numbers: "000123\n123\n000124\n#{"0" * 65}\n000123",
          add_group_ids: [target.id],
        )

      expect(
        batch.items.order(:position).pluck(:student_number, :status, :user_id, :selected),
      ).to eq(
        [
          [registered.student_number, "ready", registered.user_id, true],
          ["123", "unmatched", nil, false],
          [pending.student_number, "unregistered", nil, false],
          ["0" * 64, "invalid", nil, false],
        ],
      )
      expect(batch.duplicate_count).to eq(1)
      expect(Invite.order(:id).map(&:attributes)).to eq(original_invites)
      expect(DiscourseAcademyRoles::StudentRegistration.order(:id).map(&:attributes)).to eq(
        original_bindings,
      )
      expect(GroupUser.exists?(group: target, user_id: registered.user_id)).to eq(false)
    end

    it "reports invalid control characters without sending null bytes to PostgreSQL" do
      batch =
        described_class.create(
          actor: admin,
          mode: "groups",
          input_kind: "list",
          student_numbers: "000\u0000123",
          add_group_ids: [target.id],
        )

      expect(batch.items.sole.status).to eq("invalid")
      expect(batch.items.sole.student_number).to eq("000�123")
      expect(batch.items.sole.selected).to eq(false)
    end

    it "distinguishes unchanged membership from owner-removal conflicts" do
      unchanged = Fabricate(:registered_academy_student)
      owner = Fabricate(:registered_academy_student)
      target.add(unchanged.user)
      target.add(owner.user)
      source.add(owner.user)
      GroupUser.find_by!(group: source, user: owner.user).update!(owner: true)

      batch =
        described_class.create(
          actor: admin,
          mode: "groups",
          input_kind: "list",
          student_numbers: [unchanged.student_number, owner.student_number].join("\n"),
          add_group_ids: [target.id],
          remove_group_ids: [source.id],
        )

      expect(batch.items.order(:position).pluck(:status, :selected)).to eq(
        [["no_change", false], ["conflict", false]],
      )
      expect(GroupUser.find_by!(group: source, user: owner.user)).to be_owner
    end

    it "rejects moderators and ordinary members even when moderator group management is enabled" do
      SiteSetting.moderators_manage_groups = true

      [Fabricate(:moderator), Fabricate(:user), nil].each do |actor|
        expect do
          described_class.create(
            actor:,
            mode: "groups",
            input_kind: "list",
            student_numbers: "000123",
            add_group_ids: [target.id],
          )
        end.to raise_error(Discourse::InvalidAccess)
      end
      expect(DiscourseAcademyRoles::StudentGroupBatch.count).to eq(0)
    end
  end
end
