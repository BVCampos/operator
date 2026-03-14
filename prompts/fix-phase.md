# Fix Review Phase

You are an autonomous code fixer. Read the PR review report at `./review-report.md` and fix all findings.

## Steps

### 1. Read the review report

Read `./review-report.md` to get the full list of issues. Parse out:
- **Critical + Important Issues** — bugs, correctness, security, missing error handling
- **Test Coverage Gaps** — missing tests, untested paths
- **Suggestions** — simplifications, style, duplication

If any category is empty, skip it.

### 2. Fix issues by category

Work through each category in order:

#### A. Bugfixes (Critical + Important)

For EACH issue:
1. Read the affected file and understand the current behavior
2. Implement the minimal fix — do not refactor surrounding code
3. Keep changes targeted

Rules:
- Fix in order of severity (critical first)
- Do NOT add tests here (step B handles that)
- Do NOT refactor or simplify (step C handles that)
- If two issues conflict, prefer the safer fix

#### B. Test Coverage

For EACH gap:
1. Read the source file to understand the code path
2. Find or create the appropriate test file
3. Write focused tests covering the identified gap
4. Follow project test conventions (check existing tests for patterns)

Rules:
- Only add tests — do NOT modify source code
- Each test should verify real behavior
- Cover the specific scenarios described in each gap

#### C. Simplifications

For EACH suggestion:
1. Read the affected file to understand current code
2. Apply the simplification while preserving ALL existing functionality
3. If a suggestion conflicts with a bugfix you already made, SKIP it

Rules:
- Only simplify — do NOT fix bugs or add tests
- Preserve all existing behavior
- Prefer smaller, safer changes

### 3. Verify

After ALL changes, run the project's quality checks. Look for scripts in `package.json`, `Makefile`, or project docs. Common patterns:

```bash
# TypeScript projects
npx tsc --noEmit && npm test

# Python projects
python -m pytest

# Go projects
go vet ./... && go test ./...
```

If tests fail, analyze and fix until all pass. If type checking fails, fix type errors.

### 4. Report

After everything passes, output a summary:
- Issues fixed (count and which ones)
- Tests added (count and which files)
- Simplifications applied (count and which ones)
- Any items skipped and why
- Final tsc + test status

### 5. Update the changelog

APPEND a fix entry to `./review-changelog.md`. Check the file to find the current iteration number (look at the last `## Iteration` heading).

Append this format:
```
## Iteration N — Fix — YYYY-MM-DD HH:MM

### Fixed
- **Bugfixes (X):** brief description of each fix with file path
- **Tests added (X):** count and file names
- **Simplifications (X):** brief description of each
- **Skipped (X):** items skipped and why

### Status
- tsc: clean / N errors
- tests: N passed, N failed (note if pre-existing)
- commit: `<commit hash prefix>` `<commit message>`

---
```

### 6. Commit

Stage all changes (including `review-changelog.md`) and commit with message:
```
fix: address PR review findings

- Fixed N critical/important issues
- Added N tests for coverage gaps
- Applied N simplifications
```

## Completion Signal

After committing, output: `<fix>DONE</fix>`
