# frozen_string_literal: true

class IsbfAnonymousPoolSizeValidator
  def initialize(_options = {})
  end

  def valid_value?(value)
    @within_range = (2..4096).cover?(value.to_i)
    return false unless @within_range

    return false if value.to_i <= IsbfAnonymous::PoolAccount.maximum(:slot).to_i
    return true unless IsbfAnonymous::PoolAccount.exists?

    value.to_i >= SiteSetting.isbf_anonymous_pool_size
  end

  def error_message
    I18n.t(
      (
        if @within_range
          "site_settings.errors.isbf_anonymous_pool_cannot_shrink"
        else
          "site_settings.errors.isbf_anonymous_pool_size_invalid"
        end
      ),
    )
  end
end
