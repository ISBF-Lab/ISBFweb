# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentGroups::CreatePreview do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_inclusion_of(:mode).in_array(%w[graduation groups]) }
    it { is_expected.to validate_inclusion_of(:input_kind).in_array(%w[list csv prefix]) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:official_group, :group)
    fab!(:official_category, :category)
    fab!(:developer, :admin)
    fab!(:group)
    fab!(:registration, :registered_academy_student)
    let(:params) do
      {
        mode: "groups",
        input_kind: "list",
        student_numbers: registration.student_number,
        add_group_ids: [group.id],
      }
    end
    let(:dependencies) { { guardian: developer.guardian } }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    context "with valid registered student bindings" do
      it "stores an executable preview without changing memberships" do
        expect(result).to run_successfully
        expect(result[:batch].items.sole).to be_selectable
        expect(GroupUser.exists?(group:, user_id: registration.user_id)).to eq(false)
      end
    end

    context "with an invalid input mode" do
      let(:params) { super().merge(input_kind: "unsupported") }

      it { is_expected.to fail_a_contract }
    end

    context "without a native developer account" do
      fab!(:developer, :moderator)
      it { is_expected.to fail_a_policy(:developer) }
    end
  end
end
