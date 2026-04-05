# Enhance Fix — Repair

The enhance fix phase introduced code changes that broke one or more quality checks. Your job is to fix **only the breakages** listed below without reverting the enhancements.

## Instructions

### 1. Read the errors

The failing checks and their output are provided below. Focus exclusively on making these checks pass.

### 2. Fix the errors

For each failing check:
1. Read the affected file(s) and understand the error
2. Apply the minimal fix — do NOT refactor or change unrelated code
3. Re-run the specific check to confirm it passes

Common issues after enhancement changes:
- Missing imports after inlining (the import was removed but a type from it is still needed)
- Broken callers after function removal (a caller in another section still references the deleted function)
- Type errors from tightened types (code that relied on `any` now needs proper typing)

If a repair would require reverting an enhancement, prefer reverting that single enhancement cleanly rather than adding workaround code.

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
enhance: repair lint/test/format issues from enhance fixes
```

### 5. Output

Output a brief summary:
- Checks that were failing
- What you fixed
- Whether any enhancements were reverted (and why)
- Final status of each check (pass/fail)

End your output with `<repair>DONE</repair>` if all checks pass, or `<repair>FAIL</repair>` if some checks still fail.
