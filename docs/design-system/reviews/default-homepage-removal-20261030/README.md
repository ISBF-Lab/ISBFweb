# Remove personal homepage selection

The user approved removal of the default-homepage field from profile interface preferences on 2026-10-30 and subsequently authorized a pull request and production publication.

The interface no longer offers or submits `homepage_id`. Root routing, controller state and homepage metadata consistently use the site-wide homepage resolver, so a previously saved personal choice cannot send the root URL or logo to a different list from the site's home navigation. Existing stored values and compatibility APIs remain intact; no data migration or bulk user update is needed. Administrator defaults, registered homepages and availability checks continue through the existing resolver.

This is a field deletion within C15/D01. A01 navigation, other preference controls and save feedback keep their existing appearance. No theme source, design token, dialog frame or menu variant is added. The approval does not expand to the complete preferences form.

The isolated development runtime passed 23 RSpec examples, seven QUnit tests with 60 assertions, and 14 real-browser checks across 1440px/light and 390px/dark. The checks cover saved legacy preferences, homepage metadata, root and logo navigation, selector absence and real preference saving without a homepage value. Five menu-policy tests and the complete development policy scan passed. The native system cases were updated for the new behavior; the complete system suite was not run locally. See [verification](verification.json) and the separately recorded hashes in [source manifest](source-manifest.json).

Only this session's delta is merged into the current repository main. The captured production runtime and independent development changes are preserved separately. Publication must apply the reviewed increment to the actual running source, preserve complete plugin/symlink/release-marker and database-theme inventories, and record read-only production acceptance and verified recovery evidence separately. This record does not claim a production deployment.

## CI follow-up

The first PR head had one failing core acceptance test out of 1229: it still expected the removed personal-homepage selector. The case now seeds a legacy bookmarks preference using the standard editable-user fixture and checks that saving omits the value, root and logo use the site homepage, and the independent bookmarks route remains available.

The plugin job stopped before running tests because the floating `discourse/discourse_test:release` image moved to Ruby 4.0.9, while this repository requires Ruby 3.4. That job now pins the same immutable test image already used successfully by the frontend workflow. The Ruby requirement, dependency locks and test coverage are unchanged. The corrected test, workflow formatting, shared image equality and focused seven-test suite pass locally; complete CI is queued again. No production source or data was changed by this follow-up.
