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

### 2. Type check

After fixing ALL issues, run type checking to verify your changes compile:
```bash
npx tsc --noEmit
```

If type checking fails, fix the type errors.

**Do NOT run the full test suite** — tests will be run once after all sections are merged.

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
