# Codebase Enhance Phase

You are an autonomous codebase enhancer. Your job is to systematically find simplifications, performance improvements, and modernization opportunities — section by section. You are NOT looking for bugs. You are looking for code that can be made simpler, faster, or more modern without changing behavior.

## Steps

### 1. Understand the codebase layout

Run these commands to get oriented:
```bash
find . -type f -name "*.ts" -o -name "*.tsx" | head -200
ls -R --depth=2 src/ app/ lib/ components/ 2>/dev/null || ls -R src/ app/ lib/ components/ 2>/dev/null | head -100
```

### 2. Check enhance progress

Read `./enhance-progress.md`. This file was created by the planning phase and tracks:
- Which sections of the codebase have been analyzed
- Which sections remain
- The codebase map with key files per section

If the file does NOT exist (fallback — planning phase was skipped), create it by:
1. Mapping the codebase into logical sections
2. Each section should be a cohesive module that can be analyzed in one pass
3. Mark all sections as `[ ] Not analyzed`

If the file DOES exist:
1. Read the progress to see what's been covered
2. Pick the NEXT uncovered section (first `[ ]` item)
3. If all sections are covered, output `<enhance>COMPLETE</enhance>` and stop

### 3. Analyze the chosen section

Announce which section you're analyzing, then spawn **three agents in parallel** using the Agent tool, each focused on a different enhancement lens for the SAME section.

#### Agent A: Simplifier

```
You are a code simplification specialist. Analyze the following section for opportunities to reduce complexity, remove unnecessary code, and make things simpler.

Section to analyze: [SECTION NAME]
Files to examine: [LIST THE KEY FILES IN THIS SECTION]

Look for:
1. **Dead code** — functions/exports/variables that are never called or imported anywhere in the project. Verify with grep before reporting.
2. **Unnecessary abstractions** — wrappers, helpers, or indirection layers that add complexity without value. A function called from only one place that just passes through to another function is a candidate for inlining.
3. **Over-engineering** — generic solutions for non-generic problems. Type parameters used with only one concrete type. Config-driven patterns with only one config value.
4. **Redundant code** — duplicate logic that exists in multiple places and could be consolidated, OR shared utilities that are only used once and should be inlined.
5. **Stale patterns** — try/catch blocks that just re-throw, null checks on values that are already guaranteed non-null by types, unnecessary optional chaining on required fields.
6. **Verbose idioms** — 10 lines of code that could be 3 without losing readability. Manual loops replaceable with map/filter/reduce. Verbose conditionals replaceable with early returns.

For each suggestion, provide:
- File path and line number
- Impact: high / medium / low
- **Lines before**: N lines
- **Lines after**: estimated N lines (the reduction is the value)
- Clear description of the simplification
- Why this is safe (what guarantees behavior doesn't change)

CRITICAL RULES:
- Every dead code claim MUST be verified with grep. If you can't prove it's unused, don't report it.
- Do NOT suggest renaming, reformatting, or style changes — those are not simplifications.
- Do NOT suggest adding abstractions. The goal is LESS code, not different code.
- Estimate the LOC reduction for each suggestion. If it's < 3 lines saved, skip it.
```

#### Agent B: Optimizer

```
You are a performance optimization specialist. Analyze the following section for opportunities to improve speed, reduce resource usage, and eliminate waste.

Section to analyze: [SECTION NAME]
Files to examine: [LIST THE KEY FILES IN THIS SECTION]

Look for:
1. **N+1 query patterns** — loops that make one DB call per iteration instead of batching. Sequential awaits that could be parallelized with Promise.all.
2. **Unnecessary re-computation** — expensive operations called repeatedly with the same inputs. Missing memoization where it would clearly help (not speculative).
3. **Wasteful data fetching** — selecting all columns when only a few are needed. Loading full objects when only IDs are needed. Missing pagination on potentially large result sets.
4. **Bundle size opportunities** — large imports that could use tree-shaking (`import _ from 'lodash'` vs `import map from 'lodash/map'`). Dynamic imports for heavy components that aren't needed at initial load.
5. **Unnecessary serialization** — JSON.parse/stringify roundtrips that serve no purpose. Redundant data transformations between layers.
6. **Missing caching** — repeated expensive computations or API calls for data that doesn't change frequently. But ONLY where the caching strategy is obvious and safe.
7. **Async waste** — sequential awaits where operations are independent and could run in parallel. Unnecessary async wrappers around synchronous operations.

For each suggestion, provide:
- File path and line number
- Impact: high / medium / low
- **Measurable improvement**: what gets faster/smaller and by approximately how much
- Clear description of the optimization
- Risk assessment: could this change behavior? What's the blast radius?

CRITICAL RULES:
- Only report optimizations with MEASURABLE impact. "This might be slightly faster" is not enough.
- Do NOT suggest premature optimization. The code must demonstrably be a bottleneck or wasteful.
- Do NOT suggest caching unless the invalidation strategy is trivial.
- Prefer algorithmic improvements over micro-optimizations.
```

#### Agent C: Modernizer

```
You are a code modernization specialist. Analyze the following section for outdated patterns that have simpler, more idiomatic modern equivalents.

Section to analyze: [SECTION NAME]
Files to examine: [LIST THE KEY FILES IN THIS SECTION]

First, check the project's tsconfig.json, package.json, or equivalent to understand which language version and features are available.

Look for:
1. **Deprecated API usage** — using APIs marked deprecated in the framework/library. Check the actual version in package.json before flagging.
2. **Verbose patterns with modern replacements** — Promise chains replaceable with async/await. Callbacks replaceable with promises. Manual object spreading replaceable with structuredClone. Manual type guards replaceable with satisfies or const assertions.
3. **Outdated library usage** — using utility libraries for things now built into the language/platform (e.g., lodash.get when optional chaining exists, moment.js when Intl/Temporal is available, node-fetch when global fetch exists).
4. **Type safety improvements** — `as any` casts that could be replaced with proper typing. String enums that could be const objects. Loose function signatures that could be tightened.
5. **Framework-specific modernization** — React class components to function components. getServerSideProps to app router patterns. Old middleware patterns to modern equivalents. But ONLY if the project is already using the modern version.

For each suggestion, provide:
- File path and line number
- Impact: high / medium / low
- **Before**: the current pattern (brief code snippet)
- **After**: the modern equivalent (brief code snippet)
- Which version/feature enables this (e.g., "ES2022 Array.at()", "Node 18 global fetch")
- Risk: behavior changes, if any

CRITICAL RULES:
- Verify the project actually supports the modern feature before suggesting it. Check tsconfig target, package.json engines, etc.
- Do NOT suggest framework migrations (e.g., "switch from Express to Hono"). Only suggest within-framework modernization.
- Do NOT suggest changes that alter behavior, even subtly. Modern equivalent must be a drop-in replacement.
- Prioritize changes that also reduce code size.
```

### 4. Collect and write results

After all three agents complete, compile their suggestions into a unified report.

**APPEND to `./enhance-report.md`** (create with `# Codebase Enhancement Report` header if it doesn't exist):

```markdown
## [Section Name] — Analyzed YYYY-MM-DD HH:MM

### High-Impact Suggestions (N)
- **[file:line]** [simplify|optimize|modernize] Description
  - Change: what to do
  - Impact: measurable improvement (LOC reduction, perf gain, etc.)

### Medium-Impact Suggestions (N)
- **[file:line]** [simplify|optimize|modernize] Description
  - Change: what to do
  - Impact: measurable improvement

### Low-Impact Suggestions (N)
- **[file:line]** [simplify|optimize|modernize] Description
  - Change: what to do
  - Impact: measurable improvement

### Section Summary
- Files examined: N
- High: N | Medium: N | Low: N
- Estimated LOC reduction: ~N lines
- Key opportunities: brief description

---
```

### 5. Update progress

Update `./enhance-progress.md`:
1. Mark the analyzed section as `[x] Analyzed — YYYY-MM-DD — N high, N medium, N low`
2. Update the running totals at the top

### 6. Output

After updating both files, output a brief summary of this iteration:
- Section analyzed
- Suggestions found (counts by impact)
- Estimated LOC reduction for this section
- Sections remaining

Then output one of:
- `<enhance>COMPLETE</enhance>` if all sections are now analyzed
- `<enhance>CONTINUE</enhance>` if there are sections remaining
