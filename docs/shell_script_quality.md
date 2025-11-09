# Shell Script Idempotence & Observability Procedure

This runbook explains how to evaluate and harden shell automation so that every entrypoint is idempotent and reports failures explicitly. Follow it whenever you touch a script under `scripts/` or the top-level `bootstrap.sh` orchestrator.

## 1. Establish a Safe Test Harness

1. **Work inside a disposable environment.** Use the Vagrant VM (`vagrant up`) or a container so repeated runs do not modify your host state.
2. **Reset state between runs.** If the script manages files or services, snapshot the environment or clean its artifacts (e.g., delete the staging directory under `artifacts/`).
3. **Enable debug logging.** Export `TRACE=1` before invoking the script to surface every command being executed.

## 2. Exercise Idempotent Paths

1. **Run the script once** and capture the generated logs in `logs/`.
2. **Run it again without changes.** Idempotent scripts should exit with status `0`, emit only informational logs (no new warnings), and avoid recreating resources that already exist.
3. **Inject partial state.** Comment out or skip non-critical sections, re-run, and confirm the script gracefully detects existing artifacts (e.g., `tar` archives or systemd units) without failing.
4. **Validate helpers.** When you add new commands, rely on `require_command`, `safe_export`, and `create_tarball` from `utils/common.sh` so repeated runs reuse cached work instead of duplicating it.

## 3. Guard Against Silent Failures

1. **Ban unguarded `command || true` patterns.** Wrap risky calls with `ensure_success "step description" command` to emit actionable errors.
2. **Use `set -euo pipefail`.** All repository scripts should source `utils/common.sh`, which already enables strict mode and structured logging.
3. **Surface fallback paths.** If you intentionally ignore an error, log the reason with `log_warn` and explain the trade-off inline.
4. **Run the regression tests.** Execute `python -m pytest tests/test_shell_script_quality.py` to detect silent-failure anti-patterns automatically.

## 4. Document Observability Signals

1. **Log every external interaction.** HTTP requests, package installations, and system service changes should be annotated with `log_info` or `log_action`.
2. **Record state transitions.** When scripts create archives, update checkpoints, or rotate backups, log the destination paths.
3. **Standardize error messages.** Stick to `log_error "Context" "Failure details"` so alerts in `logs/` stay consistent.

## 5. Submit With Confidence

1. **Update docs when behavior changes.** Add sections like this one to capture new expectations.
2. **Keep the MkDocs configuration under `docs/mkdocs.yml`.** Use `mkdocs serve --config-file docs/mkdocs.yml` so local previews match CI pipelines.
3. **Record follow-up work.** If true idempotence requires future orchestration changes, open an issue outlining the observed gap and proposed mitigation.

By following this checklist, every script change preserves deterministic behavior, emits actionable logs, and passes the automated regression suite.
