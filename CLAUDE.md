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

### Loop pattern

Every loop script follows the same structure:
1. Parse args, validate git repo and `claude` CLI
2. `cd` to git root
3. For each iteration: run `claude --dangerously-skip-permissions --print < prompts/<phase>.md` in background, show a spinner, capture output
4. Check output for completion signal tags (e.g., `<review>CLEAN</review>`, `<audit>COMPLETE</audit>`)
5. Log everything to `~/.operator/logs/`

### Prompts

`prompts/` contains the markdown prompt files piped to `claude --print` as stdin. These define what Claude does in each iteration:

- `review-phase.md` — reviews git diff, writes `review-report.md`
- `fix-phase.md` — reads `review-report.md`, fixes issues, commits
- `audit-phase.md` — maps codebase into sections, audits one per iteration using 3 parallel agents (DB auditor, bug hunter, consistency checker), appends to `audit-report.md`
- `audit-verify-phase.md` — verifies findings using 3 parallel agents (code verifier, duplicate checker, intent checker), writes `audit-report-verified.md`
- `audit-fix-phase.md` — fixes confirmed findings section by section, commits per section

### State files

Loops persist state in the target project's root as markdown files. Key convention: the bash scripts check for these files to determine progress and completion. The prompts instruct Claude to read/write them.

### Ralph integration

`ralph-start` converts a markdown PRD to `prd.json` via Claude, creates a git worktree on `ralph/<name>` branch, copies ralph.sh from `~/.operator/ralph/` (or `$RALPH_SRC`), and launches a tmux session running the ralph loop. Sessions are tracked in `~/.operator/sessions.json`.

### Claude Code command

`commands/fix-review.md` is installed to `~/.claude/commands/fix-review.md` by the installer, providing the `/fix-review` slash command inside Claude Code sessions. It parses a PR review summary and spawns 3 parallel agents (bugfix, test writer, simplifier).

## Key paths

- `~/.operator/` — operator home (logs, sessions.json, ralph clone)
- `~/.operator/logs/` — per-run log files
- `~/.operator/sessions.json` — ralph session registry
- `~/.operator/ralph/` — auto-cloned ralph repo (overridable via `$RALPH_SRC`)

## Development notes

- All scripts use `set -e` and `#!/bin/bash`
- The `spin()` function (shared across scripts but copy-pasted, not sourced) shows elapsed time with a braille spinner while Claude runs
- The `log()` function writes to both stdout and the log file
- Scripts accept `--max N` or a bare number as iteration limit
- Completion signals are XML-style tags in Claude's output (e.g., `<audit>COMPLETE</audit>`)
- `audit-loop` counts `.ts/.tsx` files for context display, though operator itself is language-agnostic
