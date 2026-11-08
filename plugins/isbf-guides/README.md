# ISBF guides

Member-only tutorials with administrator drafts, publication snapshots and private
images. The active ISBF theme supplies the reader's appearance and site navigation.

## Pages and permissions

- `/guides` lists published guides; `/guides/:slug` reads the published snapshot.
- Anonymous HTML requests use the native login redirect and destination cookie.
  JSON requests require login. Chapter fragments survive the login handoff.
- `/guides/:slug?preview=1` is an administrator-only saved-draft preview.
- `/guides/:slug/images/:filename` requires login. Members can read only images
  referenced by that guide's current published snapshot; administrators can also
  read draft images. Responses use `private, no-store`.
- Management is at `/admin/plugins/isbf-guides/guides`. Its JSON API is under
  `/isbf/guides/admin/guides`; only Discourse administrators can use it.

## Editing and publishing

Enter a title, URL identifier and summary, then upload a UTF-8 HTML document or a
ZIP containing HTML and local images. Download the standard template from the
editor to start a tutorial. To update the body, edit the local file and reupload
it. A saved draft can be downloaded as a portable ZIP with its referenced images.
Metadata remains separately editable. Existing Markdown guides keep the forum
editor until an HTML/ZIP file is imported.

The editor uses native FormKit and file selection. Saving imports only a draft;
save before previewing or publishing. Publishing atomically replaces the visible
snapshot and creates a separate editable draft. Unpublishing retains the draft.
Reuploading leaves the current publication and its image bytes intact until
publication. Identical images are reused within the same guide.

FormKit owns the unsaved-navigation confirmation. The editor commits its dirty
state only after a successful server response, so failed saves keep the entered
content and continue to block publication. Avoid registering a second route-leave
confirmation alongside FormKit's guard.
Keep the form keyed by its route's guide identity across saves/publications;
recreating the native editor while asynchronous editor plugins load can leave a
pending plugin attached to a destroyed view.

Published snapshots are immutable. URL identifiers remain fixed after the first
publication, including while unpublished. Version checks prevent an outdated
browser session from overwriting or publishing newer edits. The collapsed
directory sits above the document at all viewport sizes. H2 and non-step H3
headings form the HTML directory; imported chapter and step anchors remain
available.

HTML imports preserve semantic markup and the standard tutorial content classes,
including information cards, steps, badges, callouts, figures and captions. The
active theme owns their fonts, colors, light/dark mode and responsive layout.
Scripts, embedded frames, event handlers and global styles are removed. Content
is selected from `[data-guide-content]`, `main`, or `body`; the first H1 is supplied
by the metadata title. Local images must be packaged in a ZIP, embedded in the
HTML or already belong to this guide. Remote images are never fetched.

File uploads are limited to 10 MiB; ZIP contents to 50 MiB and 500 entries. Unsafe
paths, symbolic links, duplicate paths and missing images reject the import.
ZIPs may use a wrapping directory and a unique HTML document instead of
`index.html`. The server sanitizes HTML again when rendering and continues to
cook existing Markdown. Images are validated by file contents, dimensions and the
site's image-size limit (at most 10 MiB). Supported formats are JPEG, PNG, WebP and
GIF. Binary image data lives in the plugin's database table, so native
database backups and restores include it without exposing public upload URLs or
requiring a separate media-volume backup. Metadata reads avoid selecting blobs.

## Installation and import

Enable `isbf_guides_enabled`, run the plugin migration and include the active-theme
Guides integration. Do not replace the pinned application or unrelated theme
fields. For the migration workspace, the plugin is linked from
`source/plugins/isbf-guides` to `external/isbf-guides`.

Import a captured, verified copy of the current Android tutorial:

```sh
bin/rake 'isbf_guides:import_android[/path/to/android,ADMIN_USER_ID]'
```

The directory must contain `index.html` and `images/step-01.jpg` through
`step-29.jpg`. The task checks administrator permissions and source structure,
imports the images and text transactionally, preserves legacy anchors, and
publishes the imported snapshot. If the `android` guide already exists, the task
returns it without overwriting subsequent administrator edits.

## Existing production static route

The previous Nginx `location ^~ /guides/` serves public static files before Rails.
It must be replaced by the application-forwarding configuration in
`config/nginx/40-isbf-guides.conf` when deploying this module. Update the durable
configuration and its runtime copy together, validate Nginx, then reload. The
admin Guides prefix also needs the template's 12 MiB request limit to accommodate
a 10 MiB file with multipart metadata. Confirm
the native upstream and forwarded-header variables still match the running site
before applying the template. Retain the old static release as recovery evidence.

Deploy and verify application resources, schema, imported content and theme before
switching that route. Verify both direct and in-app navigation and private images
after the switch. On rollback, retain authenticated routing or make Guides
temporarily unavailable; restoring the old static rule would make it public.

## Verification

Run `LOAD_PLUGINS=1 bin/rspec plugins/isbf-guides/spec` and scoped native lint.
The Guides CI workflow runs the full plugin suite, and frontend consistency CI
includes the shared editor lifecycle regression and existing theme checks.
Development verification passed 162 backend examples, complete file import and
publication flows, original image-byte checks, desktop/mobile/light/dark reading
and private member/admin access. Production checks use real content and read-only
requests after the guarded rollout.
