# frozen_string_literal: true

module DiscourseAcademyRoles::StudentInviteExtension
  def redeemable?
    return false unless super
    return true unless SiteSetting.academy_roles_enabled?

    DiscourseAcademyRoles::StudentRegistration.exists?(
      invite_id: id,
      user_id: nil,
      registered_at: nil
    )
  end

  def can_be_redeemed_by?(user)
    return false if SiteSetting.academy_roles_enabled?

    super
  end
end

module DiscourseAcademyRoles::StudentInviteRedeemerExtension
  def redeem
    return super unless SiteSetting.academy_roles_enabled?

    Invite.transaction do
      registration =
        DiscourseAcademyRoles::StudentRegistration.lock.find_by(invite:)
      if registration.nil? || registration.registered? || !invite.redeemable?
        raise ActiveRecord::RecordNotSaved, I18n.t("invite.not_found_json")
      end

      if redeeming_user.present? ||
           User.real.where(staged: false).find_by_email(email).present?
        raise ActiveRecord::RecordNotSaved,
              I18n.t("academy_roles.student_invites.new_account_required")
      end

      user = super
      registration.update!(user:, registered_at: Time.current) if user
      user
    end
  end
end

module DiscourseAcademyRoles::StudentInvitesControllerExtension
  private

  def show_irredeemable_invite(invite)
    if SiteSetting.academy_roles_enabled? && invite && !invite.expired? &&
         !invite.redeemed?
      super(nil)
    else
      super
    end
  end
end

module DiscourseAcademyRoles::StudentUserMergerExtension
  def merge!
    if SiteSetting.academy_roles_enabled? &&
         DiscourseAcademyRoles::StudentRegistration.exists?(
           user_id: [@source_user.id, @target_user.id]
         )
      raise Discourse::InvalidParameters,
            I18n.t("academy_roles.student_invites.merge_not_allowed")
    end

    super
  end
end
