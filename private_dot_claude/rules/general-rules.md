# Rules for AI Agents Modifying This Project

Binding rules for any AI-assisted change. They override personal preference and existing patterns in the surrounding code.

If a rule conflicts with explicit user instructions for a specific task, follow the user's instructions and surface the conflict; otherwise these rules win.

Stack-specific conventions live in `~/.claude/stack-rules/<name>.md`, auto-loaded at session start by the `detect-stack` hook from project manifests (`package.json`, `pyproject.toml`, `pom.xml`, …). Available stacks: `nextjs-react`, `react-vite`, `vuejs`, `nodejs`, `python`, `java`, `mongodb`.

Override auto-detection: create `<project>/.claude/stacks` (comma- or newline-separated stack names, `#` for comments). If no stack file exists for the stack you're working in, propose creating one rather than laying down ad-hoc patterns.

---

## 1. Code structure & reuse

### 1.1 Reuse over copy-paste.

If a pattern (UI block, validator, data shape, formatter, API method, error type, etc.) appears more than once, extract it into a shared module. Entry-point files (pages, controllers, `main`) read as **data + composition**, not walls of inline logic.

### 1.2 Small files.

Target **500–600 lines**, hard ceiling **1000**. At ~600: split — extract subcomponents/modules, hoist constants into siblings, move types into `*.types.*`. Hitting 1000 unsplit is a review-blocker.

**Scope:** Source files only (`.ts`, `.tsx`, `.js`, `.jsx`, `.vue`, `.py`, `.java`, `.kt`, `.go`, `.rs`, `.rb`, `.cs`, …). Excludes docs (`.md`, `.mdx`, `.rst`, `.txt`), generated files, lockfiles, fixtures, snapshots, data files (`.json`, `.csv`, `.yml`), and migrations.

### 1.3 Strict separation of concerns.

Isolate business logic, data access, and state from presentation. UI renders — doesn't fetch, mutate, or own domain rules. Backend handlers route + validate; domain logic in services; data access in repositories.

---

## 2. Documentation & process

### 2.1 Keep docs in sync with code.

- `README.md` — consumer-facing changes (new feature, setup step, env var).
- `AGENTS.md` / `CLAUDE.md` — AI/developer operational changes (conventions, lint rules, component library, build/test commands). Prefer `AGENTS.md` when both apply.
- `ARCHITECTURE.md` — system design or major architectural shifts.
- `docs/*.md` — module/system-level details.

If a relevant doc doesn't exist yet, propose creating it before shipping.

### 2.2 Conventional commits.

Prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `perf:`, `docs:`, `test:`, `style:`, `ci:`, `build:`. Subject = *what*; body = *why*. PRs small and focused — never a 20-file grab bag.

### 2.3 Verify locally before opening a PR.

Standard checks (typecheck, lint, tests, production build) pass locally with **zero new errors and zero new warnings**. Leave pre-existing warnings alone unless the PR targets them. Commands vary by stack — see `stack-rules/<stack>.md`.

---

## 3. Quality & best practices

### 3.1 Cross-stack defaults.

- Composition over inheritance.
- Pure functions for logic; side effects at the edges.
- `async/await` (or language equivalent) over deep callback / promise chains.
- **Exports / visibility:** Named exports and explicit visibility modifiers. Default exports / package-private only where the language or framework demands them.
- Early returns over deeply nested conditionals.
- Strict typing where supported (TS `strict`, Python `mypy`/`pyright`, Java without raw types). No type escape hatches (`any`, `# type: ignore`, raw casts) without a one-line justification.
- No comments unless logic is non-obvious — code self-documents via naming.
- 12-factor: config from env, not code.
- Observability: structured logs, meaningful errors, correlation IDs across service boundaries.

### 3.2 TDD: tests before / with the implementation.

Cycle: failing test → minimal implementation → refactor. New behavior ships with tests in the same PR. Touching existing logic without tests is a violation unless the file is trivial (e.g. presentation-only markup) and a test would only verify markup.

Test runner, layout, and coverage targets per stack — see `stack-rules/<stack>.md`.

### 3.3 Review and audit all AI-generated code.

AI output is a draft, not a deliverable. Before integrating:
- Read every line you didn't personally write.
- Trace data flow for injection / leakage risks.
- Check error handling, empty states, adversarial inputs.
- Verify code actually exists (no hallucinated imports, APIs, modules, files).

---

## 4. Security & compliance

### 4.1 ISO/IEC 27001 alignment.

Treat user data, customer data, and internal credentials as protected assets:
- Least-privilege access (DB users, IAM roles, API keys, service accounts).
- Encryption in transit (TLS) and at rest where applicable.
- Audit-logged auth and authz events (login, role change, sensitive mutation).
- Documented retention and deletion paths for anything stored.

### 4.2 VAPT before each major release.

- Dependency audit (`npm audit`, `pip-audit`, `mvn dependency-check`, `cargo audit`, Snyk, equivalent) — resolve high-severity findings.
- OWASP Top 10 baseline: input validation, output encoding, auth/session correctness, IDOR-safe access checks, secure HTTP headers, rate limiting.
- Manually re-test auth and admin routes for privilege escalation.

### 4.3 Secret hygiene.

- `.env*` and equivalent files stay out of git.
- Production secrets via platform (Vercel env, AWS Secrets Manager, GCP Secret Manager, K8s secrets, Vault) — never hard-coded.
- Accidentally committed secret → rotate immediately and force-purge from history.
- Browser-exposed env prefixes (`NEXT_PUBLIC_`, `VITE_`, `VUE_APP_`, `REACT_APP_`, …) ship to clients — never put real secrets behind them.

---

## 5. Accessibility (web / UI projects)

WCAG 2.2 AA for anything rendering UI:

- Semantic elements first: `<button>` for actions, `<a href>` for navigation, `<section>` / `<article>` / `<nav>` / `<main>` over `<div>` soup.
- Every interactive element keyboard-reachable with visible focus.
- Every image gets meaningful `alt` (or `alt=""` + `aria-hidden` for decorative).
- Form fields: labels via `id`; error states get `aria-describedby` and `aria-invalid`.
- WCAG AA contrast: 4.5:1 normal, 3:1 large.
- Respect `prefers-reduced-motion`.

---

## 6. Performance

- Lazy-load below-the-fold / rarely-used code paths.
- Use platform-optimized image / asset primitives where available.
- Audit dependency manifests periodically for unused packages.
- Memoize expensive computations only when a profiler shows a problem — never prematurely.
- Keep main-thread / request-thread work small; defer to workers, queues, or async pipelines as needed.
- **Web UIs:** Core Web Vitals — LCP < 2.5s, INP < 200ms, CLS < 0.1.
- **Backend services:** concrete budgets — P95 latency, error rate, throughput, memory.

---

## Enforcement

These rules load into AI agent context. Any PR that materially violates one of them must either:

1. Be rewritten to comply, or
2. Include a short justification in the PR description explaining why the deviation is correct here.

Silent deviations are not acceptable.
