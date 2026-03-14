# Audit Verification Phase

You are an audit verifier. A team of agents has produced an audit report (`./audit-report.md`). Your job is to verify the findings are real, consistent, and not duplicated — before anyone spends time fixing them.

## Steps

### 1. Read the audit report and verification progress

Read `./audit-report.md` to get all findings.

Read `./audit-verify-progress.md` if it exists. This tracks which sections have been verified.

If `audit-verify-progress.md` does NOT exist, create it:
1. List every section from the audit report
2. Mark all as `[ ] Not verified`

Format:
```markdown
# Audit Verification Progress

## Stats
- Sections: 0/N verified
- Confirmed: 0 | False positive: 0 | Duplicate: 0 | By design: 0
- Last updated: YYYY-MM-DD HH:MM

## Sections
- [ ] 1. Auth & Middleware
- [ ] 2. DB Schema & Core Helpers
...
```

If all sections are marked `[x]`, output `<verify>COMPLETE</verify>` and stop.

### 2. Pick the next unverified section

Select the first `[ ]` section.

### 3. Verify each finding

For EVERY finding in this section (critical, important, and minor), spawn agents to verify. Launch **three agents in parallel**:

#### Agent A: Code Verifier

```
You are a code verification agent. For each finding listed below, go read the ACTUAL code at the specified file and line number, and determine if the finding is real.

Section: [SECTION NAME]

For EACH finding, check:
1. Does the file and line number exist? Has the code changed since the audit?
2. Is the described issue actually present in the code?
3. Is the severity rating accurate (critical/important/minor)?
4. Is the suggested fix correct and safe?

Output for each finding:
- Finding: [original description]
- File: [file:line]
- Verdict: CONFIRMED | FALSE_POSITIVE | OUTDATED | WRONG_SEVERITY
- Reason: [why you reached this verdict]
- If WRONG_SEVERITY: what it should be

Findings to verify:
[PASTE ALL FINDINGS FOR THIS SECTION]
```

#### Agent B: Duplicate & Contradiction Checker

```
You are a cross-reference agent. Check the findings in this section against ALL other sections in the audit report for duplicates and contradictions.

Read the FULL audit report at ./audit-report.md.

Section being verified: [SECTION NAME]

For each finding in this section:
1. Is this finding a DUPLICATE of a finding in another section? (same root cause, same file, or same fix)
2. Does this finding CONTRADICT another finding? (e.g., one says "add validation" and another says "remove validation" on the same code)
3. Would fixing this finding break a fix suggested in another section?

Output:
- Finding: [description]
- Duplicate of: [other section's finding] or "none"
- Contradicts: [other section's finding] or "none"
- Conflict risk: HIGH / LOW / NONE
```

#### Agent C: Intent Checker

```
You are an intent verification agent. Check if findings are actually "by design" rather than bugs.

Read CLAUDE.md, AGENTS.md, and any relevant documentation in the project.

Section being verified: [SECTION NAME]

For each finding:
1. Is this behavior intentional based on project docs, comments, or conventions?
2. Is there a comment like "// intentional", "// by design", "// TODO", or similar near the code?
3. Does the project's CLAUDE.md or AGENTS.md explicitly call out this pattern as expected?
4. Is this a known trade-off documented anywhere?

Output:
- Finding: [description]
- By design: YES / NO / UNCLEAR
- Evidence: [quote from docs/comments if YES, or "none found"]
```

### 4. Compile verification results

After all agents complete, merge their results. For each finding, assign a final verdict:

- **CONFIRMED** — code verifier says real, not a duplicate, not by design
- **FALSE_POSITIVE** — code verifier says the issue doesn't exist or code has changed
- **DUPLICATE** — same root cause as another finding (note which one)
- **BY_DESIGN** — intent checker found evidence this is intentional
- **WRONG_SEVERITY** — real issue but severity should change (note new severity)

### 5. Write verified report

Write `./audit-report-verified.md`. Copy the FULL original report structure but add a verdict tag to each finding:

```markdown
## [Section Name] — Verified YYYY-MM-DD

### Critical Issues (N confirmed / M original)

1. **[file:line]** [CONFIRMED] Description...
   - Fix: ...

2. **[file:line]** [FALSE_POSITIVE] Description...
   - Reason: Code was refactored, this no longer applies

### Important Issues (N confirmed / M original)
...
```

### 6. Update progress

Update `./audit-verify-progress.md`:
1. Mark this section as `[x] Verified — YYYY-MM-DD — N confirmed, N false positive, N duplicate, N by design`
2. Update running stats

### 7. Output

Summary:
- Section verified
- Findings: N confirmed, N false positive, N duplicate, N by design, N wrong severity
- Sections remaining

Then output:
- `<verify>COMPLETE</verify>` if all sections are verified
- `<verify>CONTINUE</verify>` if sections remain
