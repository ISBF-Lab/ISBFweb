# frozen_string_literal: true

module IsbfAnonymous
  def self.pool_user?(user)
    user.is_a?(User) && user.isbf_anonymous_pool_account.present?
  end

  def self.pool_user_ids
    PoolAccount.select(:user_id)
  end

  module PoolPermissions
    %i[
      can_see_user?
      can_see_profile?
      can_edit_user?
      can_edit_username?
      can_edit_email?
      can_edit_name?
      can_silence_user?
      can_unsilence_user?
      can_suspend?
      can_deactivate?
      can_unsuspend?
      can_delete_user?
      can_delete_all_posts?
      can_anonymize_user?
      can_merge_user?
      can_administer_user?
    ].each do |permission|
      define_method(permission) do |user|
        return false if IsbfAnonymous.pool_user?(user)

        super(user)
      end
    end

    def can_see_user_actions?(user, action_types = [])
      return false if IsbfAnonymous.pool_user?(user)

      super
    end

    def can_send_private_message?(target, **options)
      return false if IsbfAnonymous.pool_user?(target)

      super
    end
  end

  module RealUsers
    def real(**options)
      super(**options).where.not(id: IsbfAnonymous.pool_user_ids)
    end
  end

  module SearchUsers
    def scoped_users
      super.where.not(id: IsbfAnonymous.pool_user_ids)
    end
  end

  module AdminUsers
    def initialize_query_with_order(klass)
      super.where.not(id: IsbfAnonymous.pool_user_ids)
    end
  end

  module DirectoryUsers
    def add_missing_users(period_type)
      super
      where(user_id: IsbfAnonymous.pool_user_ids).delete_all
    end
  end

  module PoolSessions
    def current_user
      user = super
      raise Discourse::InvalidAccess if IsbfAnonymous.pool_user?(user)

      user
    end

    def log_on_user(user, session, cookie_jar, opts = {})
      raise Discourse::InvalidAccess if IsbfAnonymous.pool_user?(user)

      super
    end
  end

  module PoolSilencer
    def initialize(user, by_user = nil, opts = {})
      reviewable = Reviewable.find_by(id: opts[:reviewable_id]) if opts[:reviewable_id]
      if reviewable && IsbfAnonymous.requested?(reviewable.payload)
        opts = opts.except(:reviewable_id)
      end

      super(user, by_user, opts)
    end

    def silence
      return false if IsbfAnonymous.pool_user?(@user)

      super
    end
  end
end
