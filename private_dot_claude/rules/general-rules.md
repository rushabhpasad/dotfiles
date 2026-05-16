# Rules for AI Agents Modifying This Project

These rules govern any AI-assisted change made to a codebase. Treat them as binding constraints — they take precedence over personal preference and over what the surrounding code happens to do today.

If a rule conflicts with explicit user instructions for a specific task, follow the user's instructions and surface the conflict; otherwise these rules win.

Stack-specific conventions live alongside this file under `stacks/`. When working in a particular stack, **load the matching rules in addition to this file**:

- `stacks/nextjs-react.md` — Next.js (App Router) + React + TypeScript
- `stacks/vuejs.md` — Vue.js + TypeScript (Vite / Nuxt)
- `stacks/nodejs.md` — Node.js services, APIs, CLIs, LoopBack
- `stacks/python.md` — Python services and tooling (FastAPI / Django / Flask)
- `stacks/java.md` — Java services (Spring Boot / general JVM)

If a stack file does not yet exist for the stack you're working in, propose creating one rather than laying down stack-specific patterns ad hoc.

---

## 1. Code structure & reuse

### 1.1 Always create reusable components / modules rather than copy-pasting logic.

If a pattern (UI block, validation helper, data shape, formatter, API client method, error type, etc.) appears more than once, extract it into a shared module. Entry-point files (pages, controllers, `main`) should read as **data + composition**, not as walls of inline logic.

### 1.2 Keep code files small.

Target **500–600 lines**. Hard ceiling **1000 lines**. When a file approaches 600 lines, split it: extract subcomponents/modules, hoist constants into sibling files, or move types into a dedicated `*.types.*` file. Hitting the 1000-line ceiling without splitting is a review-blocker.

**Scope:** This rule applies to **source code files** (`.ts`, `.tsx`, `.js`, `.jsx`, `.vue`, `.py`, `.java`, `.kt`, `.go`, `.rs`, `.rb`, `.cs`, etc.). It does **not** apply to documentation (`.md`, `.mdx`, `.rst`, `.txt`), generated files, lockfiles, fixtures, snapshots, data files (`.json`, `.csv`, `.yml` configs), or migrations.

### 1.3 Maintain a strict separation of concerns.

Isolate business logic, data access, and state management from presentation. UI components render; they don't fetch, mutate, or own domain rules. Backend handlers route and validate; the domain logic belongs in a service/domain layer. Data access belongs in repositories/data modules.

---

## 2. Documentation & process

### 2.1 Keep docs in sync with code.

- `README.md` — update when the consumer-facing understanding of the project changes (new feature, new setup step, new env var a developer must know).
- `AGENTS.md` / `CLAUDE.md` — update when AI/developer operational behavior changes (new conventions, new lint rules, new component library, new build/test command). Prefer `AGENTS.md` over `CLAUDE.md` when both are options.
- `ARCHITECTURE.md` — update when system design or major architectural decisions shift.
- `docs/*.md` — update when module-level or system-level details are added or shifted.

If a relevant doc file doesn't exist yet, propose creating it before shipping the change.

### 2.2 Conventional commits.

Prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `perf:`, `docs:`, `test:`, `style:`, `ci:`, `build:`. The subject line explains *what*; the body explains *why*. PRs should be small and focused — never a 20-file grab bag.

### 2.3 Verify locally before opening a PR.

The project's standard checks (typecheck, lint, test suite, production build) must pass locally with **zero new errors and zero new warnings**. Pre-existing warnings should be left alone unless the PR explicitly targets them. Exact commands vary by stack — see the relevant `stacks/<stack>.md`.

---

## 3. Quality & best practices

### 3.1 Cross-stack defaults.

- Prefer composition over inheritance.
- Pure functions for logic; isolate side effects at the edges.
- Async correctness: prefer `async/await` (or the language equivalent) over deeply nested callbacks/promise chains.
- **Exports / visibility:** Prefer named exports and explicit visibility modifiers. Default exports / package-private access are acceptable only where the language or framework requires them (see stack files).
- Early returns over deeply nested conditionals.
- Strict typing where the language supports it (TS `strict`, Python type hints + `mypy`/`pyright`, Java without raw types). No type escape hatches (`any`, `# type: ignore`, raw casts) without a one-line justification.
- No comments unless logic is non-obvious. Code should explain itself through naming.
- 12-factor app principles. Config from env, not from code.
- Design for observability — structured logs, meaningful error messages, correlation IDs across service boundaries.

### 3.2 TDD: tests before / with the implementation.

The cycle is: failing test → minimal implementation → refactor. New behavior ships with tests in the same PR. Touching existing logic without tests is a violation unless the file is genuinely trivial (e.g. presentation-only markup) and a test would only verify the markup itself.

Test runner, layout, and coverage targets vary by stack — see `stacks/<stack>.md`.

### 3.3 Review and audit all AI-generated code.

AI output is a draft, not a deliverable. Before integrating:
- Read every line you didn't personally write.
- Trace data flow for injection / leakage risks.
- Check error handling, empty states, and adversarial inputs.
- Verify the code actually exists in the repo (no hallucinated imports, APIs, modules, or files).

---

## 4. Security & compliance

### 4.1 ISO/IEC 27001 alignment.

Treat user data, customer data, and internal credentials as protected assets:
- Least-privilege access (DB users, IAM roles, API keys, service accounts).
- Encryption in transit (TLS) and at rest where applicable.
- Audit-logged authentication and authorization events (login, role change, sensitive mutation).
- Documented data retention and deletion paths for anything stored.

### 4.2 VAPT before each major release.

- Run dependency audit (`npm audit`, `pip-audit`, `mvn dependency-check`, `cargo audit`, Snyk, or equivalent) and resolve high-severity findings.
- Verify OWASP Top 10 baseline: input validation, output encoding, auth/session correctness, IDOR-safe access checks, secure HTTP headers, rate limiting.
- Re-test auth and admin routes manually for privilege escalation.

### 4.3 Secret hygiene.

- `.env*` and equivalent secret files stay out of git.
- Secrets in production come from the platform (Vercel project env, AWS Secrets Manager, GCP Secret Manager, Kubernetes secrets, HashiCorp Vault, etc.) — never hard-coded.
- If a secret is ever accidentally committed, rotate it immediately and force-purge from history.
- Browser-exposed env var prefixes (`NEXT_PUBLIC_`, `VITE_`, `VUE_APP_`, `REACT_APP_`, etc.) ship to clients — never put real secrets behind those prefixes.

---

## 5. Accessibility (web / UI projects)

WCAG 2.2 AA adherence for anything that renders a UI:

- Semantic elements first: `<button>` for actions, `<a href>` for navigation, `<section>` / `<article>` / `<nav>` / `<main>` over `<div>` soup.
- Every interactive element keyboard-reachable with a visible focus state.
- Every image gets meaningful `alt` text (or `alt=""` + `aria-hidden` for purely decorative imagery).
- Form fields get labels associated by id; error states get `aria-describedby` and `aria-invalid`.
- Maintain WCAG AA contrast ratios (4.5:1 normal text, 3:1 large text).
- Respect `prefers-reduced-motion`.

---

## 6. Performance

- Lazy-load below-the-fold or rarely-used code paths.
- Use the platform's optimized image / asset primitives where they exist.
- Audit dependency manifests periodically for unused packages.
- Memoize expensive computations only when a profiler shows a problem — don't memoize prematurely.
- Keep main-thread / request-thread work small; defer to workers, queues, or async pipelines where workload demands it.
- **Web UIs:** target Core Web Vitals — LCP < 2.5s, INP < 200ms, CLS < 0.1.
- **Backend services:** set and watch concrete budgets — P95 latency, error rate, throughput, memory.

---

## Enforcement

These rules are loaded into AI agent context. Any PR that materially violates one of them should either:

1. Be rewritten to comply, or
2. Include a short justification (in the PR description) explaining why the deviation is correct in this specific case.

Silent deviations are not acceptable.
