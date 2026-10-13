# ISBF-Repost

Discourse plugin for quote repost relationships used by the ISBF campus feed.

The plugin validates source visibility before a repost is published, stores the source and destination topic relationship after publication, and exposes batched counts filtered by the current viewer's topic permissions. Soft-deleted repost topics are retained in the relationship table and excluded from counts until restored.
