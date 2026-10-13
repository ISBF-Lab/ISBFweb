# Discourse avatar frames

Administrator-managed avatar frames with PNG/APNG upload, individual and CSV awards.
Manage them at `/admin/plugins/discourse-avatar-frames/frames`. New frames require a
grant by default. Existing catalog settings are retained. Grants do not auto-equip.

UTF-8 CSV supports optional username/email headers, up to 50,000 rows, and resumable
batches of 200. Images are square transparent PNG/APNG, recommended 288×288
with a centered 240px avatar circle. Fully opaque uploads are rejected. Uploads
preserve the original PNG/APNG bytes and generate a static fallback.

After uploading, check the 144px and 48px overlay previews, adjust the size and
position if needed, and confirm alignment before enabling the frame. A reliable
ring may provide an optional suggestion; open or irregular artwork uses manual
calibration. Replacing an image or changing its geometry requires confirmation
again. Disabled drafts may be saved without confirmation.

`scale` (50–300, default 120) and `offset_x`/`offset_y` (−100–100, default 0)
are percentages of the avatar image content size. Borders and layout margins
are excluded. Every overlay mount uses the same geometry, including profiles,
preferences, posts and theme outlets. Reduced motion uses the static image with
the same calibration.

Run the plugin migrations when upgrading; existing frames, grants and selections
are retained. SeedFu is only needed when initially installing the catalog.
