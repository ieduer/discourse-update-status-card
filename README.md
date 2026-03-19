# Discourse Update Status Card

This plugin adds a read-only update readiness card to the admin dashboard
general tab.

The card is intentionally display-only:

- it does not rebuild Discourse
- it does not call `/admin/update`
- it does not decide targets on its own

It reads a JSON payload from the shared container volume and renders:

- live core/version state
- official target state
- commit gap
- review decision (`follow`, `watch`, `hold`)
- front/origin/IP/Sidekiq/R2 health checks
- latest report path
- operator notes

## Data source

Default container path:

- `/shared/discourse-update-status/status.json`

Default host path for the standard standalone install:

- `/var/discourse/shared/standalone/discourse-update-status/status.json`

The plugin only reads files under `/shared/discourse-update-status`.

## Sample payload

See `sample-status.json`.

## Deployment notes

1. Add this plugin to the forum `after_code` plugin list and pin it to a
   specific Git commit.
2. Rebuild only when you are already in an approved maintenance window.
3. Publish a world-readable status payload to:
   - `/var/discourse/shared/standalone/discourse-update-status/status.json`
4. Open `Admin -> Dashboard -> General` and confirm the card renders.

Example `after_code` block:

```yaml
- '[ ! -e discourse-update-status-card ] || [ -d discourse-update-status-card/.git ]'
- 'if [ -d discourse-update-status-card/.git ]; then git -C discourse-update-status-card fetch --tags --prune origin; else git clone https://github.com/ieduer/discourse-update-status-card.git discourse-update-status-card; fi'
- 'git -C discourse-update-status-card checkout --detach <PLUGIN_SHA>'
- 'test "$(git -C discourse-update-status-card rev-parse HEAD)" = "<PLUGIN_SHA>"'
```

## Operator policy

- The card is an operational surface, not an updater.
- The authoritative workflow stays in SSH/runbook/report form.
- The payload should be refreshed after every review window and every real
  update window.
