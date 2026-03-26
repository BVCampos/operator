# PR Review Phase

You are an expert code reviewer. Review all uncommitted changes in this repository and produce a structured review report.

## Steps

1. Run `git diff` to see all unstaged changes. Also run `git diff --cached` for staged changes. If both are empty, run `git diff main...HEAD` to review the branch diff.

2. Analyze all changed files for:
   - **Critical issues** (confidence >= 90): Bugs, security vulnerabilities, data loss risks, explicit CLAUDE.md violations
   - **Important issues** (confidence >= 80): Missing error handling, logic errors, race conditions, inconsistencies
   - **Test coverage gaps**: Untested code paths, missing edge case tests, new functions without tests
   - **Suggestions**: Simplification opportunities, code duplication, style improvements

3. For each issue, include:
   - Clear description
   - File path and line number
   - Confidence score (0-100)
   - Concrete fix suggestion

4. Save the full report to `./review-report.md` using the Write tool.

5. **Append to the changelog.** After writing `review-report.md`, APPEND a review entry to `./review-changelog.md`. If the file doesn't exist, create it with a `# Review Changelog` header first. Use the Edit tool to append (or Write if creating).

   Append this format:
   ```
   ## Iteration N — Review — YYYY-MM-DD HH:MM

   ### Found
   - **Critical (X):** brief list of issues or "none"
   - **Important (X):** brief list of issues or "none"
   - **Test gaps (X):** brief list or "none"
   - **Suggestions (X):** brief list or "none"

   ### Metrics
   - Total findings: N
   - Avg confidence: N%
   - Files with issues: N

   ---
   ```

   Replace N with the current iteration number. Check `review-changelog.md` to determine which iteration you're on — count the existing `## Iteration` headings and add 1.

## Output Format

Write the report to `./review-report.md` in EXACTLY this format:

```markdown
# PR Review Report

## Critical Issues (N found)
- **[file:line]** Description of issue (confidence: X)
  - Fix: How to fix it

## Important Issues (N found)
- **[file:line]** Description of issue (confidence: X)
  - Fix: How to fix it

## Test Coverage Gaps (N found)
- **[file:line]** Description of gap
  - Suggestion: What test to write

## Suggestions (N found)
- **[file:line]** Description of suggestion
  - How: How to apply it

## Summary
- Critical: N
- Important: N
- Test gaps: N
- Suggestions: N
```

## Completion Signal

After writing the report:
- If Critical + Important = 0, output: `<review>CLEAN</review>`
- If any Critical or Important issues found, output: `<review>ISSUES_FOUND</review>`

Be thorough but filter aggressively — only report issues with confidence >= 80. Quality over quantity.
