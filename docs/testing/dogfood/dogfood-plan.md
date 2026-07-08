# Dogfood Plan

Goal: keep MenuBarDeclutter safe enough for private daily use on the developer's own Mac and for installed-app local release validation.

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
- Pro Second Bar: when a hands-on diagnostics JSON export exists, run dogfood preflight with `SECOND_BAR_DIAGNOSTICS_JSON=/path/to/diagnostics.json`; use `SECOND_BAR_AUDIT_REQUIRE_NOTCH=1` and `SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW=1` for strict notch and retry sign-off.

## Risk Areas Converted To Runs

- Real menu bar drag/use: Gate A and fixture runs.
- Accessibility grant/revoke: Gate B.
- Icon moving: Gate D.
- External display, notch, sleep/wake, Space behavior: Gate A and Gate C.
- Pro Second Bar completion evidence: Gate C plus `scripts/qa_second_bar_manual_gate_audit.sh` against a hands-on diagnostics JSON export.
- Profiles, triggers, Safe Mode: Gate C.
- Installed Launch at Login: Gate E.
- Interactive network watch: Gate E manual evidence only.
- Archive/install verification: Gate E.
- Developer ID signing, notarization, and stapling: record as out of scope unless explicitly requested.
