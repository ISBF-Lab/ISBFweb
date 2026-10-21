# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentInviteExtension do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:official_group, :group)
  fab!(:official_category, :category)

  before do
    SiteSetting.academy_official_group = official_group.id
    SiteSetting.academy_official_category = official_category.id
    SiteSetting.academy_roles_enabled = true
    registration_service =
      Class.new do
        def self.bound_invite?(_invite)
          false
        end

        def self.redeem(**_args, &block)
          block.call
        end
      end
    RSpec::Mocks::ExampleMethods.instance_method(:stub_const).bind_call(
      self,
      "IsbfAlumni::Registration",
      registration_service,
    )
    allow(IsbfAlumni::Registration).to receive(:bound_invite?).and_return(false)
  end

  it "keeps ordinary email and domain invitations forbidden" do
    [
      Fabricate.build(:invite, invited_by: admin, email: "alumni@example.com"),
      Fabricate.build(:invite, invited_by: admin, email: nil, domain: "example.com"),
    ].each do |invite|
      invite.valid?
      expect(invite.errors[:email]).to include(I18n.t("academy_roles.unbound_invite"))
    end
  end

  it "exempts only invitations verified by the alumni service and retains the single-use limit" do
    invite = Fabricate.build(:invite, invited_by: admin, email: "alumni@example.com")
    allow(IsbfAlumni::Registration).to receive(:bound_invite?).with(invite).and_return(true)
    invite.valid?
    expect(invite.errors[:email]).not_to include(I18n.t("academy_roles.unbound_invite"))
    invite.max_redemptions_allowed = 2
    invite.valid?
    expect(invite.errors[:max_redemptions_allowed]).to include(
      I18n.t("academy_roles.single_use_invite"),
    )
  end

  it "still requires native validity and rejects existing-account redemption" do
    invite = Fabricate(:invite, invited_by: admin, email: nil)
    allow(IsbfAlumni::Registration).to receive(:bound_invite?).with(invite).and_return(true)
    expect(invite.redeemable?).to eq(true)
    expect(invite.can_be_redeemed_by?(member)).to eq(false)
    invite.expires_at = 1.day.ago
    expect(invite.redeemable?).to eq(false)
  end

  it "retains student-only behavior when the alumni plugin is absent" do
    hide_const("IsbfAlumni::Registration")
    invite = Fabricate(:invite, invited_by: admin, email: nil)
    expect(invite.redeemable?).to eq(false)
    invite.email = "alumni@example.com"
    invite.valid?
    expect(invite.errors[:email]).to include(I18n.t("academy_roles.unbound_invite"))
  end

  it "routes native redemption through the alumni transaction wrapper" do
    invite = Fabricate(:invite, invited_by: admin, email: nil)
    allow(IsbfAlumni::Registration).to receive(:bound_invite?).with(invite).and_return(true)
    base =
      Class.new do
        attr_reader :invite, :email, :redeeming_user

        def initialize(invitation)
          @invite = invitation
          @email = "alumni@example.com"
          @redeeming_user = nil
        end

        def redeem
          :native_result
        end
      end
    base.prepend(DiscourseAcademyRoles::StudentInviteRedeemerExtension)
    allow(IsbfAlumni::Registration).to receive(:redeem) do |**_args, &block|
      block.call
    end
    expect(base.new(invite).redeem).to eq(:native_result)
    expect(IsbfAlumni::Registration).to have_received(:redeem).with(
      invite: invite,
      email: "alumni@example.com",
      redeeming_user: nil,
    )
  end

  it "preserves native redemption when academy roles are disabled" do
    SiteSetting.academy_roles_enabled = false
    invite = Fabricate(:invite, invited_by: admin, email: "alumni@example.com")
    expect(invite.redeemable?).to eq(true)
    expect(invite.redeemable?).to eq(true)
    expect(IsbfAlumni::Registration).not_to have_received(:bound_invite?)
  end
end
