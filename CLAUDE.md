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

- `review-phase.md` — reviews git diff, writes `review-report.md`
- `fix-phase.md` — reads `review-report.md`, fixes issues, commits
- `audit-phase.md` — maps codebase into sections, audits one per iteration using 3 parallel agents (DB auditor, bug hunter, consistency checker), appends to `audit-report.md`
- `audit-verify-phase.md` — verification instructions for a single section (the bash script launches one Claude instance per section in parallel, prepending section findings to this template)
- `audit-fix-phase.md` — fixes confirmed findings section by section, commits per section

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

## Development notes

- All scripts use `set -e` and `#!/bin/bash`
- Scripts accept `--max N` or a bare number as iteration limit (except `audit-verify` which always runs one parallel pass)
- Completion signals are XML-style tags in Claude's output (e.g., `<audit>COMPLETE</audit>`)
