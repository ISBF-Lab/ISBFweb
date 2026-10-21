# frozen_string_literal: true

module DiscourseAcademyRoles::StudentInviteExtension
  def redeemable?
    return false unless super
    return true unless SiteSetting.academy_roles_enabled?

    if defined?(IsbfAlumni::Registration) &&
         IsbfAlumni::Registration.bound_invite?(self)
      return true
    end

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
    if defined?(IsbfAlumni::Registration) &&
         IsbfAlumni::Registration.bound_invite?(invite)
      return (
        IsbfAlumni::Registration.redeem(
          invite: invite,
          email: email,
          redeeming_user: redeeming_user
        ) { super }
      )
    end

    return super unless SiteSetting.academy_roles_enabled?

    Invite.transaction do
      registration =
        DiscourseAcademyRoles::StudentRegistration.lock.find_by(invite:)
      if registration.nil? || registration.registered? || !invite.redeemable?
        raise ActiveRecord::RecordNotSaved, I18n.t("invite.not_found_json")
      end

      if redeeming_user.present? ||
           User.real.where(staged: false).find_by_email(email).present?
        raise Invite::UserExists,
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
    if SiteSetting.academy_roles_enabled? &&
         SiteSetting.academy_auth_page_enabled? && request.format.json?
      status =
        if invite&.expired?
          "expired"
        elsif invite&.redeemed?
          "used"
        else
          "invalid"
        end
      render json: {
               errors: [I18n.t("academy_roles.auth.invite_#{status}")],
               invite_status: status
             },
             status: :not_found
      return
    end

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
    if defined?(IsbfAlumni::Application) &&
         IsbfAlumni::Application.exists?(user_id: [@source_user.id, @target_user.id])
      raise Discourse::InvalidParameters,
            I18n.t("isbf_alumni.errors.merge_not_allowed")
    end
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
