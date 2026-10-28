# Resuming saved drafts

Draft titles, resume buttons and the latest-drafts menu use
`composer.resumeDraft(item)`. Existing-topic drafts navigate to the original
topic or post before opening the composer. New topics and personal messages
continue to open on the current page.

The draft's `postId` is a database identifier. It must never be assigned to
`post_number` or used as a topic URL's post-number segment. Resume loads the
post to obtain its real `topic_id` and `post_number`.

Resume reads the current draft and sequence from the draft endpoint. The topic
route suppresses automatic draft opening only for the explicit resume's
destination, so cached or missing topic draft data cannot replace the requested
draft. Other topics can restore their own drafts while a request is pending.
Switching away during loading cancels the restore; repeated clicks are
ignored. Reopening the active draft retains newer in-memory edits. Switching to
another draft uses the existing unsaved-content confirmation.

Loading an edit's published post supplies its context and permissions. The saved
draft then restores its pending body, title, category and tags, and retains its
original-text/title/tag conflict baselines. Explicit false and null values,
including a cleared reply target, survive restoration. Unreadable or inaccessible
drafts are retained; a deleted draft refreshes the list instead of restoring a
stale list copy.

Regression coverage is in the composer draft-resume service tests, the user-draft
stream tests, user-drafts acceptance tests and the nested resume system specs.
Development browser checks exercised actual updates and reply creation at desktop and mobile widths: 10 complete flows passed 85 checks, with no client exceptions. The expanded draft and user-route QUnit suites passed 48 tests and 151 assertions, including independent topic restoration during a pending resume; the shared post-list suite passed 20 tests and 39 assertions. File lint and five menu-policy tests passed. The native system specs were added and linted, but could not run locally because the isolated development project has no separate test database. See the [validation evidence](draft-resume-20261028/verification.json).

Production publication waits for exact-head CI and review. It applies only the scoped source and compiled frontend assets, preserving the current runtime, plugins, theme and settings. The actual release and recovery reference are recorded separately after publication.
