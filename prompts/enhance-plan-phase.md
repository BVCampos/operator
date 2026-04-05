# Enhance Plan Phase

You are a codebase architect. Your job is to map the codebase into logical sections for a systematic enhancement pass. You do NOT enhance anything — you only create the plan.

The goal of the enhance pass is to find **simplifications, performance wins, and modernization opportunities** — NOT bugs. Think: what code can be deleted, inlined, sped up, or replaced with a simpler modern equivalent?

## Steps

### 1. Understand the codebase layout

Run these commands to get oriented:
```bash
find . -type f -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" | grep -v node_modules | grep -v .next | grep -v dist | head -300
```

Also check the project structure:
```bash
ls -R --depth=2 src/ app/ lib/ components/ pages/ server/ api/ 2>/dev/null || ls -R src/ app/ lib/ components/ 2>/dev/null | head -150
```

Read CLAUDE.md, README.md, and any architecture docs if they exist.

### 2. Collect baseline metrics

Gather quantitative signals to help prioritize sections:

```bash
# Largest source files (complexity tends to live in big files)
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" \) ! -path '*/node_modules/*' ! -path '*/.next/*' ! -path '*/dist/*' -exec wc -l {} + 2>/dev/null | sort -rn | head -30

# Files with the most TODO/FIXME/HACK comments
grep -rn "TODO\|FIXME\|HACK\|XXX\|WORKAROUND" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" . 2>/dev/null | grep -v node_modules | cut -d: -f1 | sort | uniq -c | sort -rn | head -20

# Check for type safety issues (any casts, type assertions)
grep -rn "as any\|as unknown\|@ts-ignore\|@ts-expect-error\|eslint-disable" --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -v node_modules | wc -l

# Check for deprecated patterns
grep -rn "require(\|module\.exports\|var " --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -v node_modules | wc -l
```

### 3. Map the codebase into sections

Design sections that are:
- **Cohesive** — each section is a logical module that can be enhanced in one pass
- **Bounded** — each section should cover 5-20 files (split large modules, group small ones)
- **Independent** — sections should have minimal overlap
- **Prioritized by improvement density** — order by where the most simplification/optimization opportunity exists (largest files, most TODOs, most type-safety workarounds first)

Good section examples:
- "Database query layer" — likely has N+1 patterns, verbose queries
- "API route handlers" — often have duplicated validation/response patterns
- "Shared utility functions" — accumulate dead code and redundant helpers
- "Authentication & middleware" — often over-engineered with unnecessary layers
- "UI components" — frequently have unused props, redundant wrappers, stale patterns
- "Configuration & environment" — hardcoded values, unused config, dead feature flags

### 4. Write the plan

Write `./enhance-progress.md` with EXACTLY this format:

```markdown
# Enhance Progress

## Stats
- Sections: 0/N planned
- Total suggestions: 0 high-impact, 0 medium-impact, 0 low-impact
- Last updated: YYYY-MM-DD HH:MM

## Codebase Overview
- Language(s): [TypeScript, Python, etc.]
- Framework(s): [Next.js, FastAPI, etc.]
- Total files: N source files
- Baseline LOC: N lines of source code
- Type safety issues: N (as any, ts-ignore, etc.)
- TODO/FIXME count: N

## Sections
- [ ] Section Name — key files: file1.ts, file2.ts, dir/ — est. LOC: N
- [ ] Section Name — key files: file1.ts, file2.ts — est. LOC: N
...
```

Each section line MUST include `key files:` listing the primary files/directories and `est. LOC:` with estimated lines of code. This helps the enhance agents know where to look and lets us measure improvement.

### 5. Output

Print a summary:
- Total sections planned
- Section list with estimated improvement potential (low/medium/high)
- Key metrics collected (total LOC, type safety issues, TODO count)

Then output: `<plan>DONE</plan>`

## Rules

- Do NOT enhance any code — only plan
- Do NOT write to enhance-report.md
- Do NOT skip any meaningful part of the codebase
- Target 5-15 sections for most projects (adjust for size)
- Order sections by improvement density, not alphabetically
- Include quantitative estimates where possible
