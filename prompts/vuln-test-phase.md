# Vulnerability Test Generation — Single Section

You are a security test engineer. Your job is to write automated test cases that prove a confirmed vulnerability is exploitable AND that will later verify the fix works. You have both the vulnerability report and the triage with reproduction steps.

## Instructions

### 1. Read the vulnerability and triage reports

The section findings and triage results are provided below. Only write tests for **EXPLOITABLE** findings.

### 2. Understand the test infrastructure

Check what test framework the project uses:
```bash
cat package.json 2>/dev/null | grep -E "(vitest|jest|mocha|pytest|go test)" || true
ls -la *test* *spec* __tests__/ tests/ test/ 2>/dev/null | head -20
find . -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" | grep -v node_modules | head -10
```

Read an existing test file to understand conventions (imports, setup/teardown patterns, assertion style).

### 3. Write test cases

For EACH exploitable vulnerability, write tests that:

**a) Prove the vulnerability exists (negative test):**
- Reproduce the exact attack vector from the triage reproduction steps
- Assert that the current code is vulnerable (this test SHOULD PASS now, and SHOULD FAIL after the fix)
- Use a comment `// VULN: [VULN-ID] — this test passes while the vulnerability exists` to mark it

**b) Define the secure behavior (positive test):**
- Assert what the code SHOULD do after remediation
- This test SHOULD FAIL now, and SHOULD PASS after the fix
- Use a comment `// FIX: [VULN-ID] — this test will pass once the vulnerability is fixed` to mark it

### 4. Test patterns by vulnerability class

Use these patterns as guidance:

**SQL Injection:**
```
- Test that malicious input (e.g., `'; DROP TABLE users; --`) is sanitized
- Test that parameterized queries are used (the malicious input is treated as data, not SQL)
```

**XSS:**
```
- Test that script tags in user input are escaped in output
- Test Content-Security-Policy headers are present
```

**IDOR:**
```
- Test that user A cannot access user B's resources by guessing IDs
- Test that the endpoint returns 403/404 for unauthorized access
```

**Auth bypass:**
```
- Test that protected endpoints return 401 without auth token
- Test that expired/invalid tokens are rejected
```

**Path traversal:**
```
- Test that `../` sequences in file paths are rejected or normalized
- Test that file access is confined to the expected directory
```

**SSRF:**
```
- Test that internal/private IP ranges are blocked in user-provided URLs
- Test that URL validation rejects non-allowlisted hosts
```

### 5. Write the test file

Write the test file to `./vulns/YYYY-MM-DD/[section-name].test.ts` (or `.test.py`, `.test.go` — match the project's language).

Structure:
```
describe('[Section Name] — Security Tests', () => {
  describe('VULN-001: [Title]', () => {
    it('is vulnerable to [attack] (proves current code is exploitable)', () => {
      // VULN: VULN-001 — this test passes while the vulnerability exists
      ...
    })

    it('should [secure behavior] after fix', () => {
      // FIX: VULN-001 — this test will pass once the vulnerability is fixed
      ...
    })
  })

  describe('VULN-002: [Title]', () => {
    ...
  })
})
```

### 6. Verify tests compile

Run the test file to verify it at least compiles and the vulnerability-proving tests pass:
```bash
npx vitest run vulns/YYYY-MM-DD/[section-name].test.ts --reporter=verbose 2>&1 | tail -30
```

If tests don't compile, fix the imports and setup. If VULN tests don't pass (meaning the vulnerability might already be mitigated), note this in the output.

### 7. Output

Output a brief summary:
- Section name
- Tests written: N vulnerability proofs, N fix validations
- Tests passing: N/N (vulnerability proofs should pass, fix validations should fail)
- Test file location
- Any findings where the vulnerability could not be reproduced in tests (with reason)

Output ONLY the summary. Do not include conversational text.
