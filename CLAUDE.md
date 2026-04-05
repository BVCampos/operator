# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Operator is a CLI tool that wraps `claude --print` in bash loops to run autonomous AI coding tasks unattended — PR reviews, codebase audits, and feature implementations from PRDs. It is a pure bash project with no build system, no package manager, and no tests.

## Architecture

### Entrypoint and command routing

`bin/operator` is the main CLI entrypoint. It routes subcommands to individual scripts in `bin/`:

- `operator review` → `bin/review-loop`
- `operator audit` → `bin/audit-loop`
- `operator audit verify` → `bin/audit-verify`
- `operator audit fix` → `bin/audit-fix`
- `operator audit full` → `bin/audit-loop-fix` (orchestrates audit → verify → fix)
- `operator enhance` → `bin/enhance-loop`
- `operator enhance verify` → `bin/enhance-verify`
- `operator enhance fix` → `bin/enhance-fix`
- `operator enhance full` → `bin/enhance-loop-fix` (orchestrates enhance → verify → fix)
- `operator vuln` → `bin/vuln-loop`
- `operator vuln triage` → `bin/vuln-triage`
- `operator vuln test` → `bin/vuln-test`
- `operator vuln full` → `bin/vuln-loop-test` (orchestrates hunt → triage → test)
- `operator ralph <start|status|logs|stop|clean>` → `bin/ralph-*`

### Shared library

`bin/lib.sh` contains shared functions sourced by all loop scripts:
- `log()` — writes to stdout and appends to `$LOG_FILE` (if set)
- `setup_log <name>` — initializes `$LOG_DIR` and `$LOG_FILE` for a named script
- `spin()` — braille spinner showing elapsed time while a background process runs
- `merge_parallel_branches <prefix> <label>` — two-pass merge for parallel worktree branches (see design principles)

### Loop pattern

Every loop script follows the same structure:
1. Source `lib.sh`, call `setup_log`
2. Parse args, validate git repo and `claude` CLI
3. `cd` to git root
4. For each iteration: run `claude --dangerously-skip-permissions --print < prompts/<phase>.md` in background, show a spinner, capture output
5. Check output for completion signal tags (e.g., `<review>CLEAN</review>`, `<audit>COMPLETE</audit>`)
6. Log everything to `~/.operator/logs/`

### Exit codes

- `0` — completed successfully (all sections/reviews done)
- `1` — actual error (not a git repo, missing dependencies, missing files)
- `2` — max iterations reached (did useful work, more remains)

`audit-loop-fix` uses `cmd && EXIT=0 || EXIT=$?` to capture exit codes without `set -e` killing the pipeline. Exit 2 is treated as success (continue to next phase).

### Prompts

`prompts/` contains the markdown prompt files piped to `claude --print` as stdin:

**Review loop (generator → evaluator pattern):**
- `review-phase.md` — (generator) reviews git diff, writes `review-report.md`
- `fix-phase.md` — (generator) reads `review-report.md`, fixes issues, commits
- `review-verify-phase.md` — (evaluator) independent skeptical evaluator that scores fixes on 4 dimensions (Correctness, Minimality, Safety, Completeness — each 0-10). Writes `review-verify.md`. Outputs `<verify>PASS</verify>` if overall score >= 7.

**Audit loop (planner → generator → evaluator pattern):**
- `audit-plan-phase.md` — (planner) maps codebase into logical sections, creates `audit-progress.md`. Runs once before the audit loop if no progress file exists. Keeps planning separate from auditing.
- `audit-phase.md` — (generator) audits one section per iteration using 3 parallel agents (DB auditor, bug hunter, consistency checker), appends to `audit-report.md`. Falls back to creating sections inline if plan phase was skipped.
- `audit-verify-phase.md` — (evaluator) verification instructions for a single section (the bash script launches one Claude instance per section in parallel, prepending section findings to this template)

**Audit fix (contract → generator → evaluator pattern):**
- `audit-fix-contract-phase.md` — (contract) generates sprint contracts defining DONE-when, VERIFY-by, and REGRESSION-check conditions per finding before any fixes start. Writes `audit-fix-contracts.md`.
- `audit-fix-phase.md` — (generator) single-section fix instructions with contract verification. By default runs sequentially (one section at a time on the current branch). With `--parallel`, launches one Claude instance per section in parallel worktrees. Each section runs tsc, lint, prettier, and related tests on changed files before committing.
- `audit-fix-repair-phase.md` — (evaluator) post-merge repair instructions. If tsc/lint/prettier/tests fail after all sections are fixed, Claude is launched to fix the breakages (up to `--max-repairs` iterations, default 3).

**Enhance loop (planner → generator → evaluator pattern):**
- `enhance-plan-phase.md` — (planner) maps codebase into sections ordered by improvement density, collects baseline metrics (LOC, type safety issues, TODO counts). Creates `enhance-progress.md`.
- `enhance-phase.md` — (generator) analyzes one section per iteration using 3 parallel agents (simplifier, optimizer, modernizer), appends to `enhance-report.md`. Each agent has strict rules: simplifier must verify dead code with grep, optimizer must cite measurable impact, modernizer must verify feature availability.
- `enhance-verify-phase.md` — (evaluator) higher bar than audit verify — must confirm the improvement justifies the churn (diff size vs value). Uses verdicts: CONFIRMED, NOT_WORTH_IT, FALSE_POSITIVE, DUPLICATE, RISKY, WRONG_IMPACT.

**Enhance fix (contract → generator → evaluator pattern):**
- `enhance-fix-contract-phase.md` — (contract) generates verification contracts with quantitative criteria (LOC reduction, function elimination, dependency removal). Every contract must include a measurable condition.
- `enhance-fix-phase.md` — (generator) implements enhancements. By default runs sequentially (one section at a time). With `--parallel`, uses parallel worktrees. Measures before/after LOC. Commit messages use `enhance:` prefix instead of `fix(audit):`.
- `enhance-fix-repair-phase.md` — (evaluator) post-merge repair. May revert individual enhancements if repair would require workaround code.

**Vulnerability hunt (planner → generator → evaluator → test pattern):**
- `vuln-plan-phase.md` — (planner) maps codebase into sections ordered by attack surface (auth/input first, then data/crypto, then supporting code). Creates `vuln-progress.md`.
- `vuln-phase.md` — (generator) scans one section per iteration using 3 parallel security agents (injection hunter, auth/access hunter, data/crypto hunter). Writes per-section reports to `vulns/YYYY-MM-DD/[section].vuln.md` and appends to `vuln-report.md`. Each agent requires concrete attack vectors, not theoretical concerns.
- `vuln-triage-phase.md` — (evaluator) verifies exploitability for a single section (the bash script launches one Claude instance per section in parallel). Uses verdicts: EXPLOITABLE, THEORETICAL, FALSE_POSITIVE, DUPLICATE, ACCEPTED_RISK. Writes reproduction steps for exploitable findings to `vulns/YYYY-MM-DD/[section].triage.md`.
- `vuln-test-phase.md` — (test writer) generates security regression tests for confirmed vulnerabilities. Writes two test types per finding: vulnerability proof (passes now, fails after fix) and fix validation (fails now, passes after fix). Outputs to `vulns/YYYY-MM-DD/[section].test.*`.

### State files

Loops persist state in the target project's root as markdown files. The bash scripts check for these files to determine progress and completion. The prompts instruct Claude to read/write them.

### Ralph integration

`ralph-start` converts a markdown PRD to `prd.json` via Claude, creates a git worktree on `ralph/<name>` branch, copies ralph.sh from `~/.operator/ralph/` (or `$RALPH_SRC`), and launches a tmux session running the ralph loop. Sessions are tracked in `~/.operator/sessions.json`. Note: `ralph-start` uses `SESSION_LOG` (not `LOG_FILE`) for the tmux log path to avoid conflicts with the shared `log()` function.

### Claude Code command

`commands/fix-review.md` is installed to `~/.claude/commands/fix-review.md` by the installer, providing the `/fix-review` slash command inside Claude Code sessions.

## Key paths

- `~/.operator/` — operator home (logs, sessions.json, ralph clone)
- `~/.operator/logs/` — per-run log files
- `~/.operator/sessions.json` — ralph session registry
- `~/.operator/ralph/` — auto-cloned ralph repo (overridable via `$RALPH_SRC`)

## Design principles

Inspired by [Anthropic's harness design guide](https://www.anthropic.com/engineering/harness-design-long-running-apps):

- **Generator-Evaluator separation**: Generators (review, fix, audit) are always paired with independent evaluators. The evaluator is a separate Claude instance with a skeptical prompt — never the same instance self-evaluating.
- **Context resets**: Each `run_claude()` call starts a fresh `claude --print` invocation. State passes through files (reports, progress, contracts), not accumulated context.
- **Sprint contracts**: Before fixing audit findings, a contract phase defines precise DONE-when/VERIFY-by conditions per finding. Fixers work against contracts, not vague goals.
- **Gradable criteria**: The review verify phase uses a 0-10 scoring rubric (Correctness, Minimality, Safety, Completeness) instead of binary pass/fail. Threshold-based decisions (default: >= 7/10).
- **Planner separation**: The audit plan phase maps the codebase into sections separately from auditing. Planning and execution are different cognitive tasks.
- **Metrics tracking**: Changelogs include quantitative metrics (false positive rates, repair iterations, score distributions) to enable data-driven decisions about which phases are still load-bearing.
- **Sequential by default**: Fix phases (`audit-fix`, `enhance-fix`) run sections sequentially on the current branch. Each section builds on the previous one's changes — no worktrees, no merge conflicts. Parallel mode (`--parallel`) is opt-in for speed but uses a two-pass merge strategy (cherry-pick with commit + re-run conflicting sections) to handle overlapping changes.

## Development notes

- All scripts use `set -e` and `#!/bin/bash`
- Scripts accept `--max N` or a bare number as iteration limit (except `audit-verify` which always runs one parallel pass)
- `audit-fix` runs sections sequentially by default (one at a time on the current branch). Pass `--parallel [N]` to use worktrees with N concurrent Claude instances (default 5). `audit-verify` always runs one parallel pass
- `audit-fix` and `audit-loop-fix` accept `--model MODEL` to use a faster Claude model (e.g., `sonnet`) for the fix phase
- `audit-fix` accepts `--skip-contracts` to bypass sprint contract generation
- `review-loop` accepts `--skip-verify` to bypass independent verification and `--verify-threshold N` to adjust the pass score (default: 7)
- `enhance-fix` runs sections sequentially by default, same as audit-fix. Pass `--parallel [N]` for parallel mode. `enhance-verify` always runs one parallel pass
- `enhance-fix` and `enhance-loop-fix` accept `--model MODEL` and `--skip-contracts`
- `vuln-triage` and `vuln-test` always run one parallel pass (one agent per section)
- `vuln-loop-test` accepts `--skip-triage` to go straight from hunt to test generation
- Completion signals are XML-style tags in Claude's output (e.g., `<audit>COMPLETE</audit>`, `<enhance>COMPLETE</enhance>`, `<vuln>COMPLETE</vuln>`, `<verify>PASS</verify>`)
