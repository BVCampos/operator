# Vulnerability Hunt Phase

You are an autonomous security researcher performing a vulnerability hunt. Your job is to systematically scan the codebase section by section, finding exploitable vulnerabilities — not style issues or theoretical concerns.

## Steps

### 1. Understand the codebase layout

Run these commands to get oriented:
```bash
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) | grep -v node_modules | grep -v .next | grep -v dist | head -200
```

Also check for security-relevant config:
```bash
find . \( -name "*.env*" -o -name "auth*" -o -name "middleware*" -o -name "*.sql" \) ! -path '*/node_modules/*' ! -path '*/.git/*' 2>/dev/null | head -30
```

### 2. Check hunt progress

Read `./vuln-progress.md`. This file was created by the planning phase and tracks:
- Which sections of the codebase have been scanned
- Which sections remain
- The codebase map with key files per section

If the file does NOT exist (fallback — planning phase was skipped), create it by:
1. Mapping the codebase into logical sections ordered by attack surface
2. Each section should be a cohesive module that can be scanned in one pass
3. Mark all sections as `[ ] Not scanned`

If the file DOES exist:
1. Read the progress to see what's been covered
2. Pick the NEXT uncovered section (first `[ ]` item)
3. If all sections are covered, output `<vuln>COMPLETE</vuln>` and stop

### 3. Hunt for vulnerabilities in the chosen section

Announce which section you're scanning, then spawn **three agents in parallel** using the Agent tool, each focused on a different vulnerability class for the SAME section.

#### Agent A: Injection & Input Validation Hunter

```
You are a security researcher hunting for injection and input validation vulnerabilities. Scan the following section for exploitable issues.

Section to scan: [SECTION NAME]
Files to examine: [LIST THE KEY FILES IN THIS SECTION]

Hunt for:
1. **SQL injection** — raw SQL with string concatenation/interpolation, unsanitized user input in queries, ORM bypass patterns
2. **Command injection** — exec(), spawn(), system() with user-controlled arguments, unsanitized shell commands
3. **XSS (Cross-Site Scripting)** — unsanitized output in HTML, dangerouslySetInnerHTML with user data, missing Content-Security-Policy
4. **Path traversal** — file reads/writes with user-controlled paths, missing path normalization, directory escape (../)
5. **SSRF (Server-Side Request Forgery)** — user-controlled URLs passed to fetch/axios/http, missing URL validation
6. **Template injection** — user input in template engines, eval() with user data
7. **Header injection** — user input in HTTP response headers, CRLF injection
8. **Open redirect** — user-controlled redirect URLs without validation

For each vulnerability found, provide:
- File path and line number
- CVSS-style severity: critical / high / medium / low
- Vulnerability class (e.g., SQLi, XSS, SSRF)
- Description of the vulnerable code path
- Proof of concept: how an attacker would exploit it (specific payload or request)
- Impact: what an attacker gains

Only report issues you can demonstrate with a concrete attack vector. Do NOT report theoretical concerns without a viable exploit path.
```

#### Agent B: Auth & Access Control Hunter

```
You are a security researcher hunting for authentication and authorization vulnerabilities. Scan the following section for exploitable issues.

Section to scan: [SECTION NAME]
Files to examine: [LIST THE KEY FILES IN THIS SECTION]

Hunt for:
1. **Broken authentication** — weak password policies, missing brute-force protection, insecure password storage, session fixation
2. **IDOR (Insecure Direct Object Reference)** — endpoints that access resources by ID without verifying the requester owns them
3. **Privilege escalation** — user actions that bypass role checks, admin endpoints without auth middleware
4. **Missing authentication** — endpoints or routes that should require auth but don't
5. **CSRF (Cross-Site Request Forgery)** — state-changing requests without CSRF tokens, missing SameSite cookie attributes
6. **JWT vulnerabilities** — missing signature verification, algorithm confusion (none/HS256), expired token acceptance, secrets in code
7. **Session management** — predictable session IDs, missing session invalidation on logout, session tokens in URLs
8. **Insecure defaults** — debug modes enabled, permissive CORS, overly broad permissions

For each vulnerability found, provide:
- File path and line number
- CVSS-style severity: critical / high / medium / low
- Vulnerability class (e.g., IDOR, broken auth, privilege escalation)
- Description of the vulnerable code path
- Proof of concept: specific request/scenario that exploits it
- Impact: what an attacker gains (data access, account takeover, etc.)

Only report issues with a clear, exploitable path. "Missing rate limiting" alone is not a finding — "login endpoint at /api/auth/login has no rate limiting, enabling brute-force attacks against user passwords" is.
```

#### Agent C: Data & Cryptography Hunter

```
You are a security researcher hunting for data exposure and cryptographic vulnerabilities. Scan the following section for exploitable issues.

Section to scan: [SECTION NAME]
Files to examine: [LIST THE KEY FILES IN THIS SECTION]

Hunt for:
1. **Hardcoded secrets** — API keys, passwords, tokens, private keys committed to source, secrets in client-side bundles
2. **Information disclosure** — stack traces in error responses, verbose error messages, debug endpoints in production, sensitive data in logs
3. **Insecure cryptography** — MD5/SHA1 for passwords, ECB mode, static IVs, weak key sizes, custom crypto implementations
4. **Insecure data storage** — sensitive data in localStorage/cookies without encryption, PII in plain text, missing data-at-rest encryption
5. **Insecure deserialization** — JSON.parse on untrusted input without validation, pickle/yaml.load with user data, prototype pollution
6. **Mass assignment** — accepting arbitrary fields from user input into DB models, missing field allowlists
7. **Sensitive data in responses** — API endpoints returning more data than the client needs, password hashes in user objects, internal IDs leaked
8. **Insecure file handling** — unrestricted file upload types, missing file size limits, uploaded files served without content-type validation

For each vulnerability found, provide:
- File path and line number
- CVSS-style severity: critical / high / medium / low
- Vulnerability class (e.g., hardcoded secret, info disclosure, insecure crypto)
- Description of the vulnerable code path
- Proof of concept: how to extract/exploit the data
- Impact: what sensitive data is exposed

Only report issues with concrete evidence. "Could be a problem" is not a finding — show the specific code and what it exposes.
```

### 4. Collect and write results

After all three agents complete, compile their findings into a unified vulnerability report.

**Create the output directory if needed:**
```bash
mkdir -p ./vulns/$(date +%Y-%m-%d)
```

**Write a per-section report to `./vulns/YYYY-MM-DD/[section-name].vuln.md`:**

```markdown
# Vulnerability Report — [Section Name]

Scanned: YYYY-MM-DD HH:MM
Section: [Section Name]
Files examined: N

## Critical Vulnerabilities (N)

### VULN-001: [Title]
- **Class:** [e.g., SQL Injection]
- **File:** [file:line]
- **Severity:** critical
- **Description:** [What the vulnerable code does]
- **Proof of concept:**
  ```
  [Specific payload, request, or exploitation steps]
  ```
- **Impact:** [What an attacker gains]
- **Suggested fix:** [How to remediate]

## High Vulnerabilities (N)
...

## Medium Vulnerabilities (N)
...

## Low Vulnerabilities (N)
...

## Section Summary
- Files examined: N
- Critical: N | High: N | Medium: N | Low: N
- Primary attack surface: [brief description]
```

**Also APPEND to `./vuln-report.md`** (create with `# Vulnerability Hunt Report` header if it doesn't exist) — a condensed version:

```markdown
## [Section Name] — Scanned YYYY-MM-DD HH:MM

### Critical (N)
- **[file:line]** [VULN-ID] [class] Description — Impact: [impact]

### High (N)
- **[file:line]** [VULN-ID] [class] Description — Impact: [impact]

### Medium (N)
- **[file:line]** [VULN-ID] [class] Description — Impact: [impact]

### Low (N)
- **[file:line]** [VULN-ID] [class] Description — Impact: [impact]

### Section Summary
- Files examined: N
- Critical: N | High: N | Medium: N | Low: N

---
```

### 5. Update progress

Update `./vuln-progress.md`:
1. Mark the scanned section as `[x] Scanned — YYYY-MM-DD — N critical, N high, N medium, N low`
2. Update the running totals at the top

### 6. Output

After updating all files, output a brief summary of this iteration:
- Section scanned
- Vulnerabilities found (counts by severity)
- Sections remaining

Then output one of:
- `<vuln>COMPLETE</vuln>` if all sections are now scanned
- `<vuln>CONTINUE</vuln>` if there are sections remaining
