# Archive record

Date: 2026-08-26 America/Los_Angeles

## Decision

This plugin is archived and must not be re-enabled as part of a routine
Discourse update.

Discourse `v2026.8.0` replaced the legacy admin dashboard with a new dashboard
surface. The plugin's only client integration point,
`admin-dashboard-general-bottom`, is no longer present in core. The server-side
plugin still loads and its endpoint remains read-only, but the card has no
rendering outlet.

The plugin has no scheduler, database migration, write path, updater, backup
job, or traffic-path responsibility. Its source of truth was always the
operator-maintained JSON file under `/shared/discourse-update-status`, while
the authoritative update workflow remains the runbook and live server
readback.

## Production disposition

- `discourse_update_status_card_enabled` was changed from `true` to `false`
  through the Discourse admin site on 2026-08-26.
- The current container still contains pinned commit
  `6847584ef7357b8c609355c0f26caae8ba0eb7a3`; no rebuild was performed solely
  to remove an already non-rendering component.
- The plugin stanza should be removed from `app.yml` during the next separately
  approved rebuild, after capturing the exact pre-change config and proving
  the post-rebuild dashboard, backups, Sidekiq, and public forum contracts.
- Historical payloads and reports are retained for audit. Do not publish new
  payloads and do not delete the archive without a separate retention review.

## Verification

- New `/admin` dashboard renders normally without the custom card.
- Core contains no `admin-dashboard-general-bottom` outlet.
- The plugin defines no background job and only reads its JSON payload.
- The last live payload was already stale at 2026-08-03 before archival.

## Rollback

There is no routine rollback. Re-enabling requires a new compatibility review,
a supported outlet or other official extension point, current payload evidence,
and explicit authorization. Toggling the old setting back on by itself is not a
valid rollback because the core outlet remains absent.
