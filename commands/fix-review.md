---
description: "Fix all issues from a PR review summary — spawns parallel agents for bugfixes, test gaps, and simplifications"
user-invocable: true
---

# Fix Review

Take a PR review summary and spawn parallel agents to fix all findings: bugfix for critical/important issues, test-check for coverage gaps, and simplify for suggestions.

## Instructions

You have just received (or the user is pointing you to) a PR Review Summary produced by `/pr-review-toolkit:review-pr`. The summary contains sections like "Critical Issues", "Important Issues", "Test Coverage Gaps", and "Suggestions".

Your job is to parse the review report and launch **three agents in parallel**, each handling one category of findings. All three agents run in the background so you can report progress.

### 1. Parse the review report

From the most recent PR Review Summary in the conversation, extract:

- **Critical + Important Issues** — these are bugs, correctness problems, security issues, missing error handling, and inconsistencies that must be fixed. Collect all items from the "Critical Issues" and "Important Issues" sections.
- **Test Coverage Gaps** — these are missing tests, untested code paths, and untested edge cases. Collect all items from the "Test Coverage Gaps" section (may also be labeled "Test Gaps" or similar).
- **Suggestions** — these are simplification opportunities, code style improvements, duplicated logic, and polish items. Collect all items from the "Suggestions" section.

If any section is empty or not present, skip launching that agent.

### 2. Launch agents in parallel

Launch all applicable agents in a **single message** (parallel tool calls). Each agent gets:
- The full list of issues for its category, with file paths and line numbers
- Clear instructions on what workflow to follow
- Instructions to NOT touch files outside its scope

#### Agent A: Bugfix (Critical + Important Issues)

Use `subagent_type` = `general-purpose`. Provide this prompt structure:

```
You are an autonomous bug fixer. Fix the following issues found during a PR review.

For EACH issue below:
1. Read the affected file(s) and understand the current behavior
2. Implement the minimal fix — do not refactor surrounding code
3. After fixing ALL issues, run `npx tsc --noEmit` to verify compilation
4. Run `npm test` to verify no regressions
5. If tests fail, analyze and fix until all pass

## Issues to fix

[PASTE THE FULL LIST OF CRITICAL + IMPORTANT ISSUES HERE, with file:line references]

## Rules
- Fix issues in order of severity (critical first)
- Keep changes minimal and targeted
- Do NOT add tests (the test agent handles that)
- Do NOT refactor or simplify (the simplify agent handles that)
- If two issues conflict, prefer the safer fix
- Run tsc and tests at the end, not after each individual fix
```

#### Agent B: Test Writer (Test Coverage Gaps)

Use `subagent_type` = `general-purpose`. Provide this prompt structure:

```
You are an autonomous test writer. Add missing test coverage for the gaps identified during a PR review.

For EACH gap below:
1. Read the source file to understand the code path that needs testing
2. Find or create the appropriate test file
3. Write focused tests that cover the identified gap
4. Follow project test conventions

After writing ALL tests:
1. Run `npx vitest run <modified-test-files>` to verify they pass
2. If any test fails, fix it and re-run
3. Run `npx tsc --noEmit` to verify compilation

## Test Coverage Gaps

[PASTE THE FULL LIST OF TEST GAPS HERE, with file:line references]

## Rules
- Only add tests — do NOT modify source code
- Each test should verify real behavior, not just mock wiring
- Cover the specific scenarios described in each gap
- Use existing test files as patterns
```

#### Agent C: Simplify (Suggestions)

Use `subagent_type` = `general-purpose`. Provide this prompt structure:

```
You are an autonomous code simplifier. Apply the simplification suggestions from a PR review.

For EACH suggestion below:
1. Read the affected file(s) to understand current code
2. Apply the simplification while preserving ALL existing functionality
3. Verify the change is actually simpler, not just different

After applying ALL suggestions:
1. Run `npx tsc --noEmit` to verify compilation
2. Run `npm test` to verify no regressions
3. If anything breaks, revert that specific change and move on

## Suggestions to apply

[PASTE THE FULL LIST OF SUGGESTIONS HERE, with file:line references]

## Rules
- Only simplify — do NOT fix bugs or add tests
- Preserve all existing behavior
- If a suggestion would require touching code another agent is fixing, SKIP it
- Prefer smaller, safer changes over ambitious refactors
```

### 3. Monitor and report

After launching all agents, tell the user:
- How many agents were launched and what each one handles
- The count of issues per category

When agents complete, summarize each agent's results concisely:
- Files modified
- Issues fixed / tests added / simplifications applied
- Any issues that were skipped and why
- Final tsc + test status

### 4. Final verification

After ALL agents complete, run:
```bash
npx tsc --noEmit && npm test
```

If there are conflicts between agent changes (e.g., both modified the same file), resolve them manually preferring the bugfix agent's changes.

Report the final status.

## Usage

```
/fix-review
```

Run this immediately after `/pr-review-toolkit:review-pr` produces its summary. The skill reads the review report from the conversation context.
