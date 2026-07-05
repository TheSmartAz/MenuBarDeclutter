# Find & Rescue v0.1.1

Status: Preview.

Find & Rescue consolidates item-location workflows that answer:

> Where did my icon go, and how do I get it back?

## Included Workflows

- Find Icon
- Second Bar
- Menu Bar Item Inspector
- New Item Inbox
- Crowded Reveal Rescue
- lightweight collections and tags
- reveal, highlight, open owning app, and show-in-Second-Bar actions
- Arrange handoff for manual placement
- Experimental Assisted Move entry points where gates allow

## Gates

Find & Rescue item metadata depends on:

- Pro Mode
- Accessibility Discovery
- macOS Accessibility permission
- feature-specific toggles
- Safe Mode inactive

The page must clearly show missing gates and must not automatically prompt for Accessibility.

## Current Scope

The Settings page now presents Find Icon, Second Bar, New Items, Collections, Crowded Reveal Rescue, and item-action availability as one workflow. The deeper Search, Second Bar, Menu Bar Items, and Groups pages remain reachable from page actions and Advanced routes.

New Items has privacy-safe model/store coverage, live Pro Discovery scan persistence, page/count plumbing, a dedicated Find & Rescue review list with generic item labels, user-facing dismiss/reset controls, and a conditional status-menu "Open New Items..." row when Pro Discovery gates are satisfied. Richer per-item placement actions remain deferred to Placement Planner work.

## Privacy

Find & Rescue does not use screenshots, Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network access, telemetry, or private menu bar APIs.
