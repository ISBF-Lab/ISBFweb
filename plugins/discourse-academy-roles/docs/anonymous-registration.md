# Anonymous alumni registration

Login-required forums use the reduced `Site.json_for` payload for anonymous
visitors. It deliberately omits full SiteSerializer plugin metadata, and
`/site.json` remains protected. The registration page therefore uses the two
client-visible Alumni settings only when the full capability is absent on a
login-required site. An explicit server capability always takes precedence.

The existing selector and optional native outlet are reused. The Alumni public
configuration, email verification and application endpoints keep all server
authorization and feature checks; showing the entry grants no account or review
permission. Disabling either Alumni setting hides the entry on a fresh page.

Regression coverage is in `test/javascripts/acceptance/auth-page-test.js` under
“Academy alumni registration on login-required sites”. Production acceptance
uses an isolated Edge InPrivate context: welcome → register → Alumni, plus the
direct Alumni URL at desktop and mobile widths. It must stop before sending an
email or submitting an application. Previously checking a developer's full Site
payload did not establish anonymous registration visibility.
