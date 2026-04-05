# Audit Verification — Single Section

You are verifying the findings from one section of a codebase audit. Your job is to confirm each finding is real, not a false positive, not a duplicate, and not by-design — before anyone spends time fixing them.

## Instructions

For EVERY finding in the section below (critical, important, and minor), perform these checks:

### Code verification

1. Read the ACTUAL code at the specified file and line number
2. Confirm the described issue is present in the current code
3. Check if the severity rating is accurate (critical/important/minor)
4. Verify the suggested fix is correct and safe

### Duplicate check

5. Scan the full audit report (provided below) for findings in OTHER sections that describe the same root cause, same file, or same fix
6. If this is a duplicate, note which other finding it duplicates

### Intent check

7. Read CLAUDE.md, AGENTS.md, and any relevant project docs
8. Look for comments near the code like "// intentional", "// by design", "// TODO"
9. Check if the behavior is a documented trade-off or convention

## Verdicts

Assign exactly one verdict per finding:

- **CONFIRMED** — issue exists in the code, is not a duplicate, and is not by design
- **FALSE_POSITIVE** — issue doesn't exist, code has changed, or description is wrong
- **DUPLICATE** — same root cause as a finding in another section (note which one)
- **BY_DESIGN** — evidence that this behavior is intentional
- **WRONG_SEVERITY** — real issue but severity should change (note correct severity)

## Output format

Only include **CONFIRMED** and **WRONG_SEVERITY** findings in full detail. Dismissed findings (FALSE_POSITIVE, DUPLICATE, BY_DESIGN) go in a compact summary — one line each, no fix suggestions or analysis.

Output the verified section in this format:

    ## [Section Name] — Verified YYYY-MM-DD

    ### Critical Issues (N confirmed / M original)

    1. **[file:line]** [CONFIRMED] Description
       - Fix: original suggestion
       - Verdict reason: confirmed by reading the code

    ### Important Issues (N confirmed / M original)
    ...

    ### Minor Issues (N confirmed / M original)
    ...

    ### Dismissed (N findings)
    - [FALSE_POSITIVE] file:line — one-line reason
    - [DUPLICATE] file:line — duplicates [other finding ID]
    - [BY_DESIGN] file:line — one-line reason

    ### Verification Summary
    - Confirmed: N
    - False positives: N
    - Duplicates: N
    - By design: N
    - Wrong severity: N

Output ONLY the verified section in this format. Do not include conversational text, preamble, or explanation.
Do NOT write any files — output everything to stdout.
Be thorough but fair. Only mark as FALSE_POSITIVE if you have clear evidence the issue doesn't exist.
