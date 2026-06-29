# Basic Mode v0.1.1 Contract

Basic Mode is the stable `v0.1.1` product core.

## Guaranteed Without Sensitive Permissions

Basic Mode must work with Pro Mode off, Accessibility denied or revoked, Screen Recording absent, Apple Events absent, Input Monitoring absent, and no network access.

Stable Basic Mode behavior:

- Install app-owned control item.
- Install the required primary separator.
- Expand, collapse, toggle, and reveal all.
- Reveal always-hidden items when configured.
- Option-click reveal all.
- Auto-rehide when enabled.
- Hover reveal when enabled.
- Start expanded in Safe Mode.
- Recompute geometry after display changes.
- Recover after wake and crash marker conditions.
- Reset app layout without Pro Mode.

## Primary Separator

The primary separator is required for recovery and Basic Mode hiding. It is not a user-facing optional feature in `v0.1.1`.

Any persisted `showPrimarySeparator` value should be treated as legacy state. Runtime behavior must keep the primary separator installed.

## Safe Mode

Safe Mode must:

- Start expanded.
- Preserve the visible Basic control.
- Suppress optional/risky services.
- Keep Settings, Diagnostics, reset, and recovery reachable.
- Avoid Pro, Accessibility, Screen Recording, Apple Events, Input Monitoring, and network requirements.
