# Academy roles

This plugin configures a private academy Discourse site. Site admins are the developers with full site access; moderators are the academy administrators who manage content, suspensions, and silences. Verified official members use their own accounts to publish marked official content.

Run `bin/rake academy_roles:setup` once, then restart the web and job processes. The task creates the **普通** and **官方** categories and the `academy_official` group, enables login-only access and invitation registration, fixes current and future members' internal trust level at 0, and removes trust-level editing privileges and badges. Posting, flagging, and messaging permissions are granted separately. It may be run again after configuration changes, but it resets these site settings and category permissions.

For a local checkout where plugins are not loaded by default, run `LOAD_PLUGINS=1 bin/rake academy_roles:setup`.

Site admins create an invitation link in Discourse's invitation UI with one redemption and no email address. The UI shows the link's key as an invitation code. A visitor enters that code on the login page; Discourse's existing invitation flow handles expiry, single redemption, and revocation. The first person to redeem an unbound code receives the account. Moderators and members cannot issue registration invitations.

Only site admins add or remove members of `academy_official`. An official topic must be created in **官方** by a verified member using official identity. Any member can reply there. Verified members can mark their replies official; all posts in **普通** use ordinary identity. The badge on an existing official post remains after certification is revoked, while its former author can no longer edit it.

The post badge connector uses `post-meta-data-poster-name__after`. The base `post-meta-data-poster-name` outlet replaces Core's author label, so putting the badge there hides every post author's name.

The separate activity label appears on member profiles and admin user details. It uses Discourse's LV1–LV3 engagement requirements. LV4 requires 90 consecutive daily checks meeting LV3 requirements; a missed check longer than 36 hours resets the streak. The daily job updates this label without changing permissions. Daily topic, personal-message, and flag counts have no cap; short-interval rate limits remain enabled.
