# Audit Fix Phase

You are an autonomous code fixer. Read the codebase audit report and fix findings section by section.

## Steps

### 1. Read the audit report and fix progress

Check if `./audit-report-verified.md` exists — if so, use it (it contains verdicts: CONFIRMED, FALSE_POSITIVE, DUPLICATE, BY_DESIGN). Only fix findings marked CONFIRMED or WRONG_SEVERITY. Skip FALSE_POSITIVE, DUPLICATE, and BY_DESIGN findings.

If no verified report exists, fall back to `./audit-report.md` and treat all findings as confirmed.

Then read `./audit-fix-progress.md` if it exists. This tracks which sections' findings have been fixed.

If `audit-fix-progress.md` does NOT exist, create it:
1. Parse all section headings from `audit-report.md` (lines like `## [Section Name] — Audited ...`)
2. List each section with its issue counts
3. Mark all as `[ ] Not fixed`

Format:
```markdown
# Audit Fix Progress

## Stats
- Sections: 0/N fixed
- Issues fixed: 0 critical, 0 important, 0 minor
- Last updated: YYYY-MM-DD HH:MM

## Sections
- [ ] auth & middleware — 0 critical, 2 important, 3 minor
- [ ] DB schema & queries — 1 critical, 4 important, 1 minor
...
```

If `audit-fix-progress.md` exists:
1. Find the next section marked `[ ]`
2. If all sections are marked `[x]`, output `<audit-fix>COMPLETE</audit-fix>` and stop

### 2. Fix the chosen section

Announce which section you're fixing and how many issues it has.

Extract ALL findings for this section from `audit-report.md`. Work through them in priority order:

#### A. Critical issues first

For EACH critical issue:
1. Read the affected file(s) and understand the context
2. Implement the minimal, targeted fix
3. Do NOT refactor surrounding code

#### B. Important issues

For EACH important issue:
1. Read the affected file(s)
2. Implement the fix
3. If the fix conflicts with a critical fix you already made, skip it and note why

#### C. Minor issues

For EACH minor issue:
1. Read the affected file(s)
2. Apply the fix only if it's safe and straightforward
3. Skip if risky or if it touches code modified by a higher-priority fix

### 3. Verify

After fixing all issues for this section, run the project's quality checks. Look for scripts in `package.json`, `Makefile`, or project docs. Common patterns:

```bash
# TypeScript projects
npx tsc --noEmit && npm test

# Python projects
python -m pytest

# Go projects
go vet ./... && go test ./...
```

If tests fail:
1. Analyze the failure
2. Fix if caused by your changes
3. If pre-existing, note it and move on

If type checking fails, fix the type errors.

### 4. Commit

Stage all changes and commit:
```
fix(audit): [section name] — fix N issues

- N critical, N important, N minor fixed
- N skipped (with reasons)
```

### 5. Update progress and changelog

**Update `./audit-fix-progress.md`:**
1. Mark the section as `[x] Fixed — YYYY-MM-DD — N/M issues resolved`
2. Update the stats at the top

**APPEND to `./audit-fix-changelog.md`** (create with `# Audit Fix Changelog` header if it doesn't exist):

```markdown
## [Section Name] — Fixed YYYY-MM-DD HH:MM

### Critical (N/N resolved)
- **[file:line]** Description — FIXED: what was done
- **[file:line]** Description — SKIPPED: why

### Important (N/N resolved)
- **[file:line]** Description — FIXED: what was done
- **[file:line]** Description — SKIPPED: why

### Minor (N/N resolved)
- **[file:line]** Description — FIXED: what was done
- **[file:line]** Description — SKIPPED: why

### Status
- tsc: clean / N errors
- tests: N passed, N failed (note if pre-existing)
- commit: `<hash>` `<message>`

---
```

### 6. Output

Summary of this iteration:
- Section fixed
- Issues resolved vs skipped (with counts)
- Sections remaining

Then output one of:
- `<audit-fix>COMPLETE</audit-fix>` if all sections are now fixed
- `<audit-fix>CONTINUE</audit-fix>` if sections remain
