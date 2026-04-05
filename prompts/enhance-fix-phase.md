# Enhance Fix — Single Section

You are implementing the enhancement suggestions for one section of a codebase. The section and its suggestions are provided below.

Your job is to make the code SIMPLER, FASTER, or MORE MODERN — while keeping behavior identical. Every change you make must be safe to ship without behavioral tests catching a difference.

## Instructions

### 1. Implement suggestions by priority

Work through suggestions in order: **high-impact first**, then **medium**, then **low**.

For EACH suggestion:
1. Read the affected file(s) and understand the full context (callers, tests, imports)
2. Implement the change — prefer deletion and inlining over restructuring
3. If the change would affect callers in other sections, skip it and note why
4. After each change, verify no callers are broken: `grep -rn "functionName" . --include="*.ts" --include="*.tsx"`

If the suggestions have verdicts (from verification):
- Only implement **CONFIRMED** and **WRONG_IMPACT** suggestions
- Skip NOT_WORTH_IT, FALSE_POSITIVE, DUPLICATE, and RISKY suggestions

### 2. Check against verification contract

If a **Verification Contract** section is provided below the suggestions, verify each change against its contract:
- For each suggestion, check every **DONE when** condition is satisfied
- Run each **VERIFY by** command and confirm the expected result
- Check each **REGRESSION check** still passes
- If a condition is NOT met, adjust the code until it is

If no contract is provided, skip this step.

### 3. Measure improvement

After implementing all suggestions, collect before/after metrics:

```bash
# Count lines in changed files (compare with original)
wc -l <changed files>

# Verify no type errors introduced
npx tsc --noEmit

# Check for broken imports
grep -rn "from.*<removed-module>" . --include="*.ts" --include="*.tsx" | grep -v node_modules
```

### 4. Verify changes

After implementing ALL suggestions, run these checks **on the files you changed** and fix any errors they surface. Repeat until all pass.

**a) Type check:**
```bash
npx tsc --noEmit
```

**b) Lint (only changed files):**
```bash
npx eslint --no-warn-ignored <changed files>
```
If the project uses `biome` instead of `eslint`, use `npx biome check <changed files>`.
If neither tool is configured, skip this step.

**c) Format (only changed files):**
```bash
npx prettier --check <changed files>
```
If formatting fails, run `npx prettier --write <changed files>` to fix.
If the project uses `biome` for formatting, use `npx biome format <changed files>`.
If no formatter is configured, skip this step.

**d) Tests (only related tests):**
If there are test files directly related to the files you changed (co-located `*.test.*` or `*.spec.*` files), run them:
```bash
npx vitest run <test files> --reporter=verbose
```
Use the project's test runner (`vitest`, `jest`, etc.). If no related tests exist, skip this step.

Fix any errors from these checks before committing. **Do NOT run the full test suite** — the full suite will run once after all sections are merged.

### 5. Commit

Stage all changed source files and commit:
```
enhance: [section name] — N simplifications, N optimizations, N modernizations

- ~N lines removed
- Key changes: brief list
```

Do NOT commit progress files, changelog files, or enhance reports — only commit code changes.

### 6. Output

Output a brief summary:
- Section name
- Suggestions implemented (count by category: simplify/optimize/modernize)
- Suggestions skipped (count and reasons)
- Contract status (if contract was provided): N/N conditions met
- Lines of code: before → after (net change)
- Files modified
- tsc status

Output ONLY the summary. Do not write to progress or changelog files.
