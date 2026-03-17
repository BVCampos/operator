# Audit Fix — Single Section

You are fixing the findings from one section of a codebase audit. The section and its findings are provided below.

## Instructions

### 1. Fix findings by priority

Work through findings in order: **critical first**, then **important**, then **minor**.

For EACH finding:
1. Read the affected file(s) and understand the context
2. Implement the minimal, targeted fix — do NOT refactor surrounding code
3. If the fix conflicts with another fix you already made, skip it and note why

If the findings have verdicts (from verification):
- Only fix **CONFIRMED** and **WRONG_SEVERITY** findings
- Skip FALSE_POSITIVE, DUPLICATE, and BY_DESIGN findings

### 2. Verify changes

After fixing ALL issues, run these checks **on the files you changed** and fix any errors they surface. Repeat until all pass.

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

### 3. Commit

Stage all changed source files and commit:
```
fix(audit): [section name] — fix N issues

- N critical, N important, N minor fixed
- N skipped (with reasons)
```

Do NOT commit progress files, changelog files, or audit reports — only commit code changes.

### 4. Output

Output a brief summary:
- Section name
- Issues fixed (count by severity)
- Issues skipped (count and reasons)
- Files modified
- tsc status

Output ONLY the summary. Do not write to progress or changelog files.
