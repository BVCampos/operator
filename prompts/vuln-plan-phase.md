# Vulnerability Hunt — Plan Phase

You are a security architect. Your job is to map the codebase into sections ordered by attack surface area for a systematic vulnerability hunt. You do NOT hunt for vulns — you only create the plan.

## Steps

### 1. Understand the codebase layout

Run these commands to get oriented:
```bash
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.rb" -o -name "*.php" -o -name "*.java" \) | grep -v node_modules | grep -v .next | grep -v dist | grep -v vendor | head -300
```

Check for security-relevant files:
```bash
find . \( -name "*.env*" -o -name "auth*" -o -name "middleware*" -o -name "session*" -o -name "crypt*" -o -name "sanitiz*" -o -name "valid*" -o -name "schema.prisma" -o -name "*.sql" \) ! -path '*/node_modules/*' ! -path '*/.git/*' 2>/dev/null | head -50
```

Check for dependency manifests:
```bash
cat package.json 2>/dev/null | head -60
cat requirements.txt 2>/dev/null || cat Pipfile 2>/dev/null || cat go.mod 2>/dev/null | head -40
```

Read CLAUDE.md, README.md, and any security docs if they exist.

### 2. Map the codebase by attack surface

Design sections ordered by attack surface priority:

**Tier 1 — Direct attack surface (scan first):**
- Authentication & session management
- Authorization & access control middleware
- User input handling (forms, API params, file uploads)
- Database query layer (ORM calls, raw SQL)
- External API integrations

**Tier 2 — Indirect attack surface:**
- Serialization/deserialization (JSON parsing, file processing)
- File system operations (reads, writes, path handling)
- Cryptography & secrets management
- Server configuration & environment handling
- Background jobs & queue processing

**Tier 3 — Supporting code:**
- Shared utilities & helpers
- Client-side rendering (XSS surface)
- Logging & error handling (information disclosure)
- Build & deployment configuration

Each section should be:
- **Bounded** — 5-20 files, auditable in one pass
- **Cohesive** — focused on one attack surface area
- **Specific** — list the key files to examine

### 3. Write the plan

Write `./vuln-progress.md` with EXACTLY this format:

```markdown
# Vulnerability Hunt Progress

## Stats
- Sections: 0/N planned
- Total findings: 0 critical, 0 high, 0 medium, 0 low
- Last updated: YYYY-MM-DD HH:MM

## Codebase Overview
- Language(s): [TypeScript, Python, etc.]
- Framework(s): [Next.js, FastAPI, etc.]
- Total files: N source files
- Auth mechanism: [JWT, session cookies, OAuth, etc.]
- Database: [PostgreSQL, MongoDB, etc.]
- External APIs: [list any]

## Sections
- [ ] Section Name — attack surface: [type] — key files: file1.ts, file2.ts, dir/
- [ ] Section Name — attack surface: [type] — key files: file1.ts, file2.ts
...
```

### 4. Output

Print a summary:
- Total sections planned
- Section list with attack surface tier (1/2/3)
- Recommended scan order

Then output: `<plan>DONE</plan>`

## Rules

- Do NOT hunt for vulnerabilities — only plan
- Do NOT write to vuln-report.md
- Do NOT skip any code that handles user input, auth, or data
- Target 5-15 sections for most projects (adjust for size)
- Always put authentication and input handling sections first
