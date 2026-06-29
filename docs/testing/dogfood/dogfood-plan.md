# Phase 9.2 Dogfood Plan

Goal: make MenuBarDeclutter safe enough for private daily use on the developer's own Mac before installed-app alpha work.

## Run Cadence

- Run the preflight before each new dogfood cycle.
- Use the fixture app before testing third-party menu bar items.
- Treat Basic Mode as the first alpha gate.
- Do not spend time on Pro Mode validation if Basic Mode has blocking failures.

## Evidence

Each run should record:

- Environment: Mac model, chip, macOS version, display setup, notch, external display, appearance mode, Reduce Transparency, Increase Contrast.
- Build: commit hash, scheme, version/build, Debug or Release, installed path.
- Result: PASS, FAIL, BLOCKED, or NOT TESTED.
- Evidence: diagnostics export path, health report path, dogfood bundle path, manual notes, reproduction steps.

## Phase 9.1 Blockers Converted To Runs

- Real menu bar drag/use: Gate A and fixture runs.
- Accessibility grant/revoke: Gate B.
- Icon moving: Gate D.
- External display, notch, sleep/wake, Space behavior: Gate A and Gate C.
- Profiles, triggers, Safe Mode: Gate C.
- Installed Launch at Login: Gate E.
- Interactive network watch: Gate E manual evidence only.
- Archive and notarization: Gate E placeholder until credentials exist.
