# Dogfood QA

Dogfood QA turns MenuBarDeclutter validation into repeatable private local runs.

Dogfood is conditional QA. Use the lane policy in `docs/testing/qa-process.md` to decide when these gates are required; do not run every gate for unrelated patches.

Start here:

1. Read `dogfood-plan.md`.
2. Run `scripts/qa_dogfood_preflight.sh`.
3. Build and launch the fixture with `scripts/qa_build_fixture.sh` and `scripts/qa_run_fixture.sh`.
4. Copy `run-template.md` into a dated run file.
5. Record findings with `bug-report-template.md` or `daily-use-template.md`.

For Pro Second Bar completion runs, export diagnostics as JSON after hands-on
testing and pass it into preflight:

```sh
SECOND_BAR_DIAGNOSTICS_JSON=/path/to/diagnostics.json \
SECOND_BAR_AUDIT_MATRIX_OUTPUT=docs/testing/pro-second-bar-direct-activation-matrix.generated.md \
scripts/qa_dogfood_preflight.sh
```

Use `SECOND_BAR_AUDIT_REQUIRE_NOTCH=1` after notch fallback testing and
`SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW=1` after stale/failure retry testing.
To validate only the Second Bar audit hook without running the full build/test
preflight, add `DOGFOOD_SECOND_BAR_AUDIT_ONLY=1`.

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
4. Gate D: Icon Moving Experimental. Blocks only Experimental Icon Moving claims.
5. Gate E: Installed Release. Blocks installed-app release claims.

Historical triage:

- `docs/archives/dogfood/phase-9.4-triage.md`
- `docs/archives/dogfood/phase-9.4-bug-index.md`
- `docs/archives/dogfood/phase-9.4-risk-board.md`
