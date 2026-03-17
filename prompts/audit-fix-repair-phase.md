# Audit Fix — Repair

The audit fix phase introduced code changes that broke one or more quality checks. Your job is to fix **only the breakages** listed below without reverting the audit fixes.

## Instructions

### 1. Read the errors

The failing checks and their output are provided below. Focus exclusively on making these checks pass.

### 2. Fix the errors

For each failing check:
1. Read the affected file(s) and understand the error
2. Apply the minimal fix — do NOT refactor or change unrelated code
3. Re-run the specific check to confirm it passes

### 3. Re-run all checks

After fixing everything, run the full verification to make sure nothing else broke:

```bash
npx tsc --noEmit
npx eslint . || npx biome check .
npx prettier --check . || npx biome format .
npm test
```

Skip any check that was not originally failing or is not configured in this project.

### 4. Commit

Stage and commit only the repair changes:
```
fix(audit): repair lint/test/format issues from audit fixes
```

### 5. Output

Output a brief summary:
- Checks that were failing
- What you fixed
- Final status of each check (pass/fail)

End your output with `<repair>DONE</repair>` if all checks pass, or `<repair>FAIL</repair>` if some checks still fail.
