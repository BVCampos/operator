# Enhance Verification — Single Section

You are verifying the enhancement suggestions from one section of a codebase analysis. Your job is to confirm each suggestion is worth the churn — that it actually simplifies, speeds up, or modernizes the code without introducing risk.

The bar for enhancement is HIGHER than for bug fixes. A bug must be fixed regardless of churn. An enhancement must justify its diff size.

## Instructions

For EVERY suggestion in the section below (high, medium, and low impact), perform these checks:

### Correctness check

1. Read the ACTUAL code at the specified file and line number
2. Confirm the described opportunity exists in the current code
3. Verify the suggested change is a drop-in replacement (no behavior change)
4. Check the impact estimate is realistic (not inflated)

### Churn check

5. Estimate the diff size of implementing this suggestion
6. Compare the diff size to the stated benefit
7. A 50-line diff to save 3 lines is NOT worth it
8. A 5-line diff to remove an entire dependency IS worth it
9. Deleting code is almost always worth it regardless of diff size

### Duplicate check

10. Scan the full enhance report (provided below) for suggestions in OTHER sections that overlap with this one
11. If two suggestions would touch the same code, keep the higher-impact one

### Safety check

12. Would this change break any callers? Check imports and usages.
13. Could this change subtly alter behavior under edge cases?
14. Is there a test that would catch a regression?

## Verdicts

Assign exactly one verdict per suggestion:

- **CONFIRMED** — opportunity exists, improvement justifies the churn, safe to implement
- **NOT_WORTH_IT** — opportunity exists but the improvement doesn't justify the diff size
- **FALSE_POSITIVE** — opportunity doesn't exist, code has changed, or description is wrong
- **DUPLICATE** — overlaps with a suggestion in another section (note which one)
- **RISKY** — real opportunity but implementing it could change behavior in ways that need careful testing
- **WRONG_IMPACT** — real opportunity but impact rating should change (note correct rating)

## Output format

Only include **CONFIRMED**, **WRONG_IMPACT**, and **RISKY** suggestions in full detail. RISKY findings are real opportunities that need human judgment — keep the full analysis so a developer can decide whether to proceed. Dismissed suggestions (NOT_WORTH_IT, FALSE_POSITIVE, DUPLICATE) go in a compact summary — one line each, no change suggestions or analysis.

Output the verified section in this format:

    ## [Section Name] — Verified YYYY-MM-DD

    ### High-Impact Suggestions (N confirmed / M original)

    1. **[file:line]** [CONFIRMED] Description
       - Change: original suggestion
       - Verdict reason: confirmed by reading code, ~40 lines removable

    ### Medium-Impact Suggestions (N confirmed / M original)
    ...

    ### Low-Impact Suggestions (N confirmed / M original)
    ...

    ### Dismissed (N suggestions)
    - [NOT_WORTH_IT] file:line — saves 2 lines but requires touching 5 files
    - [FALSE_POSITIVE] file:line — one-line reason
    - [DUPLICATE] file:line — overlaps with [other suggestion ID]

    ### Verification Summary
    - Confirmed: N
    - Not worth it: N
    - False positives: N
    - Duplicates: N
    - Risky: N
    - Wrong impact: N
    - Estimated total LOC reduction (confirmed only): ~N lines

Output ONLY the verified section in this format. Do not include conversational text, preamble, or explanation.
Do NOT write any files — output everything to stdout.
Be skeptical. Enhancement suggestions are often over-optimistic about impact and under-estimate churn. Only CONFIRM suggestions where the value clearly outweighs the cost.
