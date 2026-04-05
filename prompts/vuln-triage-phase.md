# Vulnerability Triage — Single Section

You are triaging the vulnerability findings from one section of a security scan. Your job is to verify each finding is actually exploitable, not a false positive, and to write concrete reproduction steps — before anyone spends time writing fixes or tests.

## Instructions

For EVERY vulnerability in the section below, perform these checks:

### 1. Code verification

1. Read the ACTUAL code at the specified file and line number
2. Confirm the described vulnerable code path exists in the current code
3. Trace the data flow: can user input actually reach the vulnerable code?
4. Check if there are upstream mitigations (input validation, middleware, WAF rules) that the hunter missed

### 2. Exploitability verification

5. Determine if the vulnerability is reachable from an external attacker's perspective
6. Check if existing security controls (auth middleware, CSRF tokens, CSP headers) prevent exploitation
7. Verify the proof of concept would actually work — don't trust the hunter's PoC blindly
8. Check the severity rating matches the actual impact and exploitability

### 3. Duplicate & context check

9. Scan the full vulnerability report (provided below) for findings in OTHER sections that describe the same root cause
10. Read CLAUDE.md, AGENTS.md, and security-related documentation
11. Check if the behavior is a known limitation, documented trade-off, or has a compensating control

## Verdicts

Assign exactly one verdict per finding:

- **EXPLOITABLE** — vulnerability exists, is reachable, and the PoC works or a working PoC can be constructed
- **THEORETICAL** — code pattern is risky but exploitation is blocked by existing controls (note which controls)
- **FALSE_POSITIVE** — vulnerability doesn't exist, code has changed, or description is wrong
- **DUPLICATE** — same root cause as a finding in another section (note which one)
- **ACCEPTED_RISK** — evidence that this is a known/documented risk with compensating controls

## Output format

For each **EXPLOITABLE** finding, write detailed reproduction steps. For dismissed findings, write a compact one-liner.

Output the triaged section in this format:

    ## [Section Name] — Triaged YYYY-MM-DD

    ### Exploitable Vulnerabilities (N confirmed / M reported)

    #### VULN-001: [Title]
    - **Class:** [vulnerability class]
    - **File:** [file:line]
    - **Severity:** [confirmed severity]
    - **Verdict:** EXPLOITABLE
    - **Verdict reason:** [why this is confirmed exploitable]

    **Reproduction steps:**
    1. [Step-by-step instructions to trigger the vulnerability]
    2. [Include specific payloads, URLs, request bodies]
    3. [Describe what the attacker observes as proof of exploitation]

    **Expected vulnerable behavior:**
    [What happens when the exploit succeeds]

    **Expected fixed behavior:**
    [What should happen instead after remediation]

    ---

    ### Dismissed (N findings)
    - [FALSE_POSITIVE] VULN-003 file:line — one-line reason
    - [THEORETICAL] VULN-004 file:line — blocked by [control], would require [condition]
    - [DUPLICATE] VULN-005 file:line — same root cause as VULN-001
    - [ACCEPTED_RISK] VULN-006 file:line — documented in [location]

    ### Triage Summary
    - Exploitable: N
    - Theoretical: N
    - False positives: N
    - Duplicates: N
    - Accepted risk: N

Output ONLY the triaged section in this format. Do not include conversational text.
Do NOT write any files — output everything to stdout.
Be thorough but fair. Only mark as FALSE_POSITIVE if you have clear evidence the issue doesn't exist. Only mark as EXPLOITABLE if you can construct a viable attack path.
