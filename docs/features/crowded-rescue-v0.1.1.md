# Crowded Rescue v0.1.1

Status: Preview.

Crowded Reveal Rescue estimates whether an inline reveal is likely to fit and can choose a safer fallback.

## Implemented

- A pure `CrowdedRevealDecisionEngine`.
- Reveal-path wiring for normal expand, reveal all, item reveal, group reveal, and selected status-menu paths.
- Fallback decisions for inline reveal, Second Bar, Full Menu Bar Mode, layout suggestions, blocked, and no-op.
- Safe Mode disables automatic rescue.
- Diagnostics record decision kind and blocked/fallback reason without item identities.

## Deferred

- Ask-every-time UI.
- Additional fallback preferences beyond the current Second Bar, Full Menu Bar Mode, layout suggestion, blocked, and no-op paths.
- Manual QA on real crowded menu bars, notch displays, external displays, Spaces, and sleep/wake.
