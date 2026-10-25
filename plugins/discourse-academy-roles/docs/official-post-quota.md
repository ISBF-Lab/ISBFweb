# Official topic quotas

Native Admin user details expose an independent weekly official-topic limit to developers (`User#admin?`). Zero/unset is unlimited; developers are exempt. Accounts without official publishing permission may be preconfigured without granting permission.

Week boundaries use Asia/Shanghai Monday midnight. Only successful official first posts consume quota. Replies, edits, failed writes, pending review and unpublished shared drafts do not. Approval and shared-draft publication enforce the author's quota. Deletion/recovery never refunds/double-charges recorded usage.

State uses the existing PluginStore namespace `discourse-academy-roles`, key `official_post_quota:<user_id>`, with limit and week usage in one row. Ordinary UserUpdater custom-field saves cannot overwrite it. First configuration seeds surviving marked official first posts, including soft-deleted posts and excluding SharedDraft. Previously purged records cannot be reconstructed.

The plugin extends PostCreator's transaction yield and TopicTimestampChanger's publication yield; fresh user SELECT FOR UPDATE serializes quota/configuration writes. Do not replace this with nested User#with_lock around native creation: a joined transaction can swallow ActiveRecord::Rollback and commit partial native writes. Native after-transaction notifications/jobs remain outside the plugin's transaction yield.

GET/PUT `/academy-roles/admin/users/:user_id/official-post-quota` require a real developer session. PUT accepts only a numeric integer `limit` in 0..2147483647 and returns current usage/reset state; caller-supplied usage is ignored. Updates use CSRF, a write rate limit and StaffActionLogger auditing. No quota state is added to public user serializers or editable user fields.

This is a native Admin form extension, approved for this task; it does not change frontend design references or permissions. Run the focused quota Rails/QUnit workflow before merging. Production acceptance is read-only and must not mutate actual quotas or post test announcements. Back up database/plugin/config/assets, preserve peer source patches, publish assets before one controlled reload, and retain rollback/source hashes.
