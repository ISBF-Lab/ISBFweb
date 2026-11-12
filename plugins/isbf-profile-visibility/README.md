# isbf-profile-visibility

Lets members choose which parts of their public profile other people can see:
about me (bio, location, website, featured topic, cover), summary and activity.
The existing "Hide my public profile" option stays as the switch that hides everything.
The owner and staff always see the whole profile.

Choices are stored as self-editable user custom fields. The server enforces them for
profile and user card data, the summary endpoint, activity lists and feeds, the
voted-by and solved lists, local user previews and the MCP user tools. The client only
adjusts tabs, redirects a hidden section to a public one and shows a placeholder.

Disabled with `isbf_profile_visibility_enabled`, or when `allow_users_to_hide_profile` is off.
