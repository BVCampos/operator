# Operator

Autonomous AI coding loops for Claude Code. Run reviews, audits, and full feature implementations unattended.

Operator wraps `claude --print` in bash loops that persist state between iterations, so AI agents can systematically work through large tasks — reviewing PRs, auditing codebases, implementing features from PRDs — without manual intervention.

> **Warning:** Operator runs multiple unattended Claude sessions, each consuming significant tokens. A single `operator audit full --max 10` run can use hundreds of thousands of tokens. This tool is intended for **Claude Max plan** subscribers. Usage on metered plans may result in unexpected costs.

## Install

One line:

```bash
curl -fsSL https://raw.githubusercontent.com/BVCampos/operator/main/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/BVCampos/operator.git ~/.operator/repo
~/.operator/repo/install.sh
```

The installer checks for required dependencies (`claude`, `jq`, `git`) and adds `operator` to your PATH.

## Quick start

```bash
cd ~/projects/myapp

operator review             # review + fix your current branch
operator audit              # audit the codebase section by section
operator audit full         # audit → verify → fix, all in one
```

Run `operator` with no args to see all commands.

## Commands

### `operator review` — PR review + auto-fix

Iteratively reviews your branch's changes, finds issues, and fixes them.

```bash
operator review              # default: up to 3 iterations
operator review --max 5      # more iterations
operator review --review-only  # just review, save report
operator review --fix-only     # fix from existing report
```

Each iteration:
1. **Review** — analyzes git diff, writes findings to `review-report.md`
2. **Fix** — fixes bugs, adds tests, applies simplifications, commits
3. **Repeat** — re-reviews to catch remaining issues
4. **Stop** — exits early if no critical/important issues remain

Files: `review-report.md`, `review-changelog.md`

### `operator audit` — systematic codebase audit

Crawls your entire codebase section by section, spawning specialist agents (DB auditor, bug hunter, consistency checker) in parallel.

```bash
operator audit               # up to 10 iterations
operator audit --max 5       # fewer iterations
```

Each iteration maps the codebase, picks the next uncovered section, audits it, and appends findings to the report. Resumable across runs.

Files: `audit-report.md`, `audit-progress.md`

### `operator audit verify` — validate findings

Spawns one verification agent per section, all running in parallel. Each agent reads the actual code, checks for duplicates across sections, and looks for intentional patterns in project docs.

```bash
operator audit verify         # verify all sections in parallel
```

Each finding gets a verdict: `CONFIRMED`, `FALSE_POSITIVE`, `DUPLICATE`, `BY_DESIGN`, or `WRONG_SEVERITY`.

Files: `audit-report-verified.md`

### `operator audit fix` — fix confirmed findings

Fixes all sections in parallel using git worktrees — one isolated worktree per section. Each section's fixes are cherry-picked back to the main branch, then tests run once on the combined result.

```bash
operator audit fix                              # fix all unfixed sections in parallel
operator audit fix --max 5                      # limit to 5 sections at a time
operator audit fix --model sonnet               # use a faster model
operator audit fix --model sonnet --effort low  # fast fixes
```

Uses the verified report if available (skipping false positives).

Files: `audit-fix-progress.md`, `audit-fix-changelog.md`, `.audit-fix-worktrees/` (temporary)

### `operator audit full` — complete pipeline

Runs audit → verify → fix in sequence:

```bash
operator audit full                                     # audit and fix: 20 iterations each
operator audit full --max 5                             # audit and fix: 5 iterations each
operator audit full --audit-max 5 --fix-max 10
operator audit full --model sonnet --effort low         # fast pipeline
operator audit full --skip-verify                       # skip verification
```

### `operator ralph` — autonomous PRD implementation

Runs [snarktank/ralph](https://github.com/snarktank/ralph) in isolated git worktrees. Give it a markdown PRD and it implements every user story autonomously, creating a PR when done.

```bash
# Start a loop
operator ralph start --prd ./tasks/feature.md --tool claude --max 20

# Multiple PRDs in parallel (separate worktrees)
operator ralph start --prd ./tasks/payments.md --max 10

# Manage sessions
operator ralph status
operator ralph logs auth-feature     # Ctrl+B D to detach
operator ralph stop auth-feature
operator ralph clean auth-feature    # after merge
```

What happens:
1. Converts markdown PRD to `prd.json` via Claude
2. Creates a git worktree on branch `ralph/<name>`
3. Runs `ralph.sh` in a detached tmux session (requires `tmux`)
4. When all stories pass — pushes branch and creates a PR (requires `gh`)

### `/fix-review` — interactive Claude Code command

Inside a Claude Code session after a PR review:

```
/pr-review-toolkit:review-pr
/fix-review
```

Spawns parallel agents for bugfixes, test coverage, and simplifications.

## How it works

Every loop follows the same pattern:

1. A **bash script** manages the loop — iterations, state files, logging, spinners
2. Each iteration calls `claude --dangerously-skip-permissions --print` with a **prompt file**
3. Claude reads state from previous iterations, does work, updates state
4. The bash script checks for completion signals and decides whether to continue

### Model and effort

All commands accept `--model` and `--effort` to control which Claude model runs and how much thinking it does:

```bash
operator review --model sonnet              # use a specific model
operator audit --effort high                # more thorough thinking
operator audit full --model sonnet --effort low   # fast audit pipeline
operator ralph start --prd tasks/feature.md --model opus --effort max
```

| Flag | Values | Default |
|------|--------|---------|
| `--model MODEL` | `sonnet`, `opus`, `haiku`, or full model ID | Claude's default |
| `--effort LEVEL` | `low`, `medium`, `high`, `max` | Claude's default |

For `audit full`, both flags are passed through to all three phases (audit, verify, fix).

### Customizing prompts

Edit files in `prompts/` to customize behavior for your stack:

- `review-phase.md` — what the reviewer looks for
- `fix-phase.md` — how fixes are applied
- `audit-phase.md` — audit scope and agent instructions
- `audit-verify-phase.md` — verification criteria
- `audit-fix-phase.md` — fix priorities and commit style

### State files

Tools create files in your **project root** to track progress:

| Tool | Files |
|------|-------|
| `review` | `review-report.md`, `review-changelog.md` |
| `audit` | `audit-report.md`, `audit-progress.md` |
| `audit verify` | `audit-report-verified.md` |
| `audit fix` | `audit-fix-progress.md`, `audit-fix-changelog.md`, `.audit-fix-worktrees/` |
| `ralph` | `.ralph-worktrees/`, `scripts/ralph/prd.json` |

Add to your `.gitignore`:
```
review-report.md
review-changelog.md
audit-report.md
audit-progress.md
audit-report-verified.md
audit-fix-progress.md
audit-fix-changelog.md
.audit-fix-worktrees/
.ralph-worktrees/
```

Logs: `~/.operator/logs/`

### Configuration

**Ralph source**: Override the ralph clone location:
```bash
export RALPH_SRC=~/my-ralph-fork
```

## Prerequisites

| Dependency | Required for | Install |
|-----------|-------------|---------|
| `claude` | all commands | `npm install -g @anthropic-ai/claude-code` |
| `jq` | ralph | `brew install jq` |
| `git` | all commands | comes with Xcode CLI tools |
| `tmux` | ralph (background sessions) | `brew install tmux` |
| `gh` | ralph (auto PR creation) | `brew install gh` |

## Credits

Built on top of [Ralph](https://github.com/snarktank/ralph) by [Geoffrey Huntley](https://github.com/ghuntley). Ralph pioneered the autonomous agent loop pattern — spawning fresh AI instances with clean context, persisting state through git commits and progress files, and iterating until all tasks are complete. Operator extends this pattern to PR reviews, codebase audits, and multi-loop orchestration.

## License

MIT
