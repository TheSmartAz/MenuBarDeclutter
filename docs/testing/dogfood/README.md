# Dogfood QA

Phase 9.2 turns MenuBarDeclutter validation into repeatable private dogfood runs.

Dogfood is conditional QA. Use the lane policy in `docs/testing/qa-process.md` to decide when these gates are required; do not run every gate for unrelated patches.

Start here:

1. Read `dogfood-plan.md`.
2. Run `scripts/qa_dogfood_preflight.sh`.
3. Build and launch the fixture with `scripts/qa_build_fixture.sh` and `scripts/qa_run_fixture.sh`.
4. Copy `run-template.md` into a dated run file.
5. Record findings with `bug-report-template.md` or `daily-use-template.md`.

Privacy boundary:

- No screenshots are collected automatically.
- No screen contents are collected.
- No telemetry is uploaded.
- No network logs are collected unless a tester manually attaches a text file.
- Basic Mode must remain usable without Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Gate order:

1. Gate A: Basic Mode Daily Use. Blocks Basic stability claims.
2. Gate B: Pro Read-only. Blocks Accessibility discovery and read-only Pro claims.
3. Gate C: Pro Assisted. Blocks Second Bar, profiles, triggers, and assisted Pro claims.
4. Gate D: Icon Moving Experimental. Blocks only Labs/Icon Moving claims.
5. Gate E: Installed Release. Blocks installed-app release claims.

Phase 9.4 triage:

- `docs/dogfood/phase-9.4-triage.md`
- `docs/dogfood/phase-9.4-bug-index.md`
- `docs/dogfood/phase-9.4-risk-board.md`
