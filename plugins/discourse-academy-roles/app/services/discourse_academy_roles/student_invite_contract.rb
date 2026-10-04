# frozen_string_literal: true

class DiscourseAcademyRoles::StudentInviteContract < Service::ContractBase
  MAX_EXPIRY_DAYS = 36_500

  attribute :expires_at, :string

  validate :future_expiry

  def expiration
    if expires_at.present?
      Time.iso8601(expires_at)
    else
      SiteSetting.invite_expiry_days.days.from_now
    end
  end

  private

  def future_expiry
    if expiration <= Time.current || expiration > MAX_EXPIRY_DAYS.days.from_now
      errors.add(:expires_at, :invalid)
    end
  rescue ArgumentError
    errors.add(:expires_at, :invalid)
  end
end
