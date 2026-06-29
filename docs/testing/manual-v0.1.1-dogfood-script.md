# Manual v0.1.1 Dogfood Script

Goal: run one privacy-safe local work session and produce enough evidence to decide whether `v0.1.1` is release-candidate ready.

## Setup

1. Install the dry-run build or notarized release candidate:
   ```sh
   scripts/build_release.sh --dry-run --install --verify-installed
   ```
2. Record build metadata in `docs/testing/manual-v0.1.1-results-template.md`.
3. Start with Basic Mode, Pro Mode off, Labs off, automation paused, and no new macOS permission grants.

## Session

1. Use Basic Mode for at least one normal work session:
   - Collapse and expand from the status item.
   - Trigger reveal all.
   - Let auto-rehide run.
   - Test hover reveal if enabled.
2. Change display state where available:
   - Attach or detach an external display if available.
   - Switch main display if available.
   - Sleep and wake.
3. Test Pro gates:
   - Open Pro surfaces with Pro off.
   - Enable Pro without requesting permission.
   - Request Accessibility only from the explicit button if testing Pro.
   - Revoke permission and confirm Basic Mode still works.
4. Test Preview/Labs gates without mutating system state:
   - Confirm Import/Export is dry-run only.
   - Confirm Spacing Labs does not automatically apply global defaults.
   - Confirm App Intents or URL automation return blocked results when paused or gated.

## Evidence

1. Export diagnostics only when intentionally chosen.
2. Export a dogfood bundle if dogfood mode is in scope for the session.
3. Confirm exports exclude screenshots, screen contents, live search text, selected item identity, protected names/targets, active unlock sessions, and unexpected file paths.
4. Fill every applicable row in the results template.

## Stop Conditions

Stop the session and file a failure note if:

- Basic Mode becomes unreachable.
- A permission prompt appears without an explicit request.
- A Preview, Labs, or Experimental feature applies state while its gate is off.
- Diagnostics or dogfood export includes screen contents or protected identifiers by default.
