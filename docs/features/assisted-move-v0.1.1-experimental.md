# Assisted Move v0.1.1

Status: Experimental.

Assisted Move is the automated icon-placement subflow. It is visible from Arrange as an option, but the stable recommendation remains normal macOS Command-drag.

## Contract

Assisted Move must be:

- single-item only
- explicitly enabled
- Pro and Accessibility gated
- blocked in Safe Mode
- first-use confirmed
- confirmed per move
- dry-run capable
- verification based
- recoverable on failure

It must never run as a silent bulk move from startup, profile apply, trigger automation, URL automation, or background discovery.

## Gate Model

The shared gate model checks:

- Pro Mode
- Accessibility Discovery
- Accessibility permission
- Icon Moving enablement
- Safe Mode
- item frame availability
- target zone availability
- own-app item blocking
- likely system item blocking unless advanced override is enabled
- first-use confirmation
- per-move confirmation

The Command Center exposes dry-run and try-assisted-move actions through the same Pro, Accessibility, feature, target, and Private Access gates used by other advanced item actions.

## Current Scope

The current implementation includes:

- shared gate model and command vocabulary for dry-run, try, cancel, and guide actions
- a dedicated Arrange subflow with item selection, target-zone selection, dry-run, first-use confirmation, per-move confirmation, result display, and recovery actions
- an external-confirmation execution path that reuses the existing icon moving service without showing a second confirmation dialog
- dry-run facts for source zone, target zone, planned direction, and experimental risk before any move attempt
- privacy-safe dogfood result logs with aggregate source zone, target zone, result, failure reason, duration bucket, and redaction marker
- focused tests for gate availability, confirmation blocking, dry-run redaction, dogfood redaction, and dry-run non-execution

Execution still depends on the existing experimental moving service and live macOS menu bar behavior. The flow is not available as a bulk action and must remain Experimental.

## Recovery Expectations

When a real move fails, user-facing recovery should offer:

- reveal all
- reset layout
- retry dry-run
- open Arrange
- export diagnostics

Diagnostics must avoid raw item identity by default.

Dogfood logs must avoid raw item titles, app names, bundle identifiers, selected item IDs, frame coordinates, screen captures, or query text by default.
