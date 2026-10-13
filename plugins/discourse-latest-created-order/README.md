# Latest by creation date

An optional Discourse plugin that makes all default Latest lists show newly created
topics first. Replies still update `bumped_at`, activity indicators, unread state,
and notifications, but do not move old topics above newer topics in these lists.

## Behavior

- Covers `/latest`, category Latest lists, tag Latest lists, and category/tag combinations.
- Overrides a category's implicit default sort for its Latest list.
- Preserves core global/category pin priority, the user's cleared pins, and pagination.
- Orders unpinned topics by `created_at DESC, id DESC` for stable pagination.
- Preserves explicit sort requests, such as `?order=activity`, `?order=likes`, and
  `?order=created&ascending=true`.
- Leaves Hot, Top, New, Unread, Unseen, search, and personal-message lists unchanged.
- Keeps creation order when clicking the live new/updated topics banner. A small
  client extension merges incoming topics using creation dates and server-provided
  effective pin timestamps; initial loads and pagination use the server query.

The setting defaults to **off**. There are no database migrations or timestamp rewrites.

The client wrapper resolves the original method descriptor on the current topic list.
This preserves core's action binding when loading more topics. Capturing a decorated
method's function from the prototype would bind it to the wrong object.

## Installation and rollback

1. Copy this directory to `plugins/discourse-latest-created-order` in the Discourse
   checkout used to build the site. With a separate plugin repository, clone it into
   that directory through the usual `app.yml` plugin installation hook.
2. Rebuild the application container for production, or restart the development
   Rails server and rebuild frontend assets.
3. Open `/admin/site_settings?filter=latest_topics_order_by_created`, enable
   **latest topics order by created**, and refresh the topic list.

Disable the same setting and refresh to restore native activity sorting. To uninstall,
remove the plugin from the build configuration and rebuild the application. Do not
enable the community plugin below alongside this one because their ordering hooks overlap.

The [Chinese manual deployment guide](docs/manual-deployment.zh_CN.md) covers the
current isbf-one.com production container and persistent plugin installation hook.

## Existing plugin assessment

The community [discourse-plugin-order-created](https://github.com/dsims/discourse-plugin-order-created)
was tested first, following its [Meta discussion](https://meta.discourse.org/t/created-as-default-sort-order/370920).
Its version 0.0.1 source was retrieved on 2026-10-08 and tested against this checkout
(`2026.10.0-latest`) in an isolated PostgreSQL test database.

The tested `plugin.rb` SHA-256 was
`b9bd486b099bfde731e2eac8ce1ecc65338b61d07ed5e7eec22a9588fb959abb`.
Three acceptance examples produced two failures:

| Scenario | Result |
| --- | --- |
| Global Latest with a globally pinned topic | Passed |
| Category Latest with an existing Likes default sort | Kept Likes order instead of creation order |
| Hot list with different hot scores | Replaced score priority with creation order |

Its broad ordering modifier applies before Hot's score ordering and skips category
defaults that select another sort. This plugin instead modifies only the default
Latest result before core applies pin priority and pagination.

## Verification

Use a clean test database; this checkout's usual test database may contain development
fixtures. Set `RAILS_DB` to that database and prepare it through the normal test setup.

```sh
LOAD_PLUGINS=1 CAPYBARA_DEFAULT_MAX_WAIT_TIME=20 bin/rspec plugins/discourse-latest-created-order/spec
bin/qunit --standalone plugins/discourse-latest-created-order/test/javascripts
```

Verified on 2026-10-08 against `2026.10.0-latest` in the isolated database
`discourse_latest_created_order_test_20261008`:

| Check | Result |
| --- | --- |
| Topic queries and HTTP endpoints | 18 examples passed |
| Live updates, pins, manual sorting, and pagination | 6 QUnit tests passed |
| Current campus theme on desktop and mobile; admin toggle and English/Chinese descriptions | 3 system examples passed |
| Ruby, JavaScript, and YAML lint/format checks | Passed |

System examples import `themes/isbf-campus-feed` when it is present. Cold theme
compilation receives a longer asset-processing timeout. The managed container's
QUnit run used a warmed development Rails server with `--rails-port 3328` and
`DISCOURSE_DISABLE_BROWSER_SANDBOX=1` for Chromium. The temporary server was stopped
after verification; no production site was changed.

Requires Discourse 2026.8 or later for the frontend model extension API.
