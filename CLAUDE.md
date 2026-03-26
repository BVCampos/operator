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
- `operator ralph <start|status|logs|stop|clean>` → `bin/ralph-*`

### Shared library

`bin/lib.sh` contains shared functions sourced by all loop scripts:
- `log()` — writes to stdout and appends to `$LOG_FILE` (if set)
- `setup_log <name>` — initializes `$LOG_DIR` and `$LOG_FILE` for a named script
- `spin()` — braille spinner showing elapsed time while a background process runs

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
- `audit-fix-phase.md` — (generator) single-section fix instructions with contract verification. The bash script launches one Claude instance per section in parallel worktrees, each fixing and committing independently. Each section runs tsc, lint, prettier, and related tests on changed files before committing.
- `audit-fix-repair-phase.md` — (evaluator) post-merge repair instructions. If tsc/lint/prettier/tests fail after merging all sections, Claude is launched to fix the breakages (up to `--max-repairs` iterations, default 3).

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

## Development notes

- All scripts use `set -e` and `#!/bin/bash`
- Scripts accept `--max N` or a bare number as iteration limit (except `audit-verify` which always runs one parallel pass)
- `audit-fix` and `audit-verify` run all sections in parallel (one Claude instance per section). `audit-fix` uses git worktrees for isolation, cherry-picks commits back, runs tsc + lint + prettier + tests on the combined result, and auto-repairs any failures (disable with `--no-repair`)
- `audit-fix` and `audit-loop-fix` accept `--model MODEL` to use a faster Claude model (e.g., `sonnet`) for the fix phase
- `audit-fix` accepts `--skip-contracts` to bypass sprint contract generation
- `review-loop` accepts `--skip-verify` to bypass independent verification and `--verify-threshold N` to adjust the pass score (default: 7)
- Completion signals are XML-style tags in Claude's output (e.g., `<audit>COMPLETE</audit>`, `<verify>PASS</verify>`)
