# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentGroups::Groups do
  describe ".plan" do
    fab!(:target, :group)
    fab!(:source, :group)

    it "accepts manual groups and normalizes duplicate identifiers" do
      plan = described_class.plan(mode: "groups", add_group_ids: [target.id.to_s, target.id], remove_group_ids: [source.id])

      expect(plan.fetch("add_group_ids")).to eq([target.id])
      expect(plan.fetch("remove_group_ids")).to eq([source.id])
      expect(described_class.valid_plan?(plan, mode: "groups")).to eq(true)
    end

    it "rejects empty, overlapping, missing, automatic, and email-managed groups" do
      email_group = Fabricate(:group, automatic_membership_email_domains: "example.edu")
      [
        [[], []],
        [[target.id], [target.id]],
        [[Group.maximum(:id) + 1], []],
        [[Group::AUTO_GROUPS[:admins]], []],
        [[email_group.id], []],
        [["1 OR 1=1"], []],
      ].each do |add_ids, remove_ids|
        expect do
          described_class.plan(mode: "groups", add_group_ids: add_ids, remove_group_ids: remove_ids)
        end.to raise_error(DiscourseAcademyRoles::StudentGroups::Error)
      end
    end

    it "invalidates a preview when native group display settings change" do
      plan = described_class.plan(mode: "groups", add_group_ids: [target.id], remove_group_ids: [])
      target.update!(title: "Graduate")

      expect(described_class.valid_plan?(plan, mode: "groups")).to eq(false)
    end
    it "uses only the configured alumni group for graduation and keeps removals explicit" do
      configured = target
      integration = Module.new do
        define_singleton_method(:enabled?) { true }
        define_singleton_method(:group) { configured }
      end
      stub_const(Object, :IsbfAlumni, integration) do
        plan = described_class.plan(mode: "graduation", add_group_ids: [], remove_group_ids: [source.id])
        expect(plan.fetch("add_group_ids")).to eq([target.id])
        expect(plan.fetch("remove_group_ids")).to eq([source.id])
        expect(described_class.valid_plan?(plan, mode: "graduation")).to eq(true)
      end
    end

  end
end
