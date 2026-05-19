# Node.js Backend Rules

Stack-specific rules. Load **alongside** `../general-rules.md` when working in a Node.js service, API, CLI, or LoopBack project.

---

## Runtime & tooling

- LTS Node only. Pin in `package.json` `engines` and via `.nvmrc` / `.node-version`.
- TypeScript with `strict: true` for non-trivial services.
- ESM (`"type": "module"`) for new projects unless a dependency forces CJS.
- One package manager per repo (`npm` / `pnpm` / `yarn`). Lockfile committed.

---

## File layout

- `src/routes/` (or `src/controllers/`) — HTTP entry points; thin.
- `src/services/` — business logic.
- `src/repositories/` (or `src/data/`) — database access.
- `src/lib/` — cross-cutting utilities (logger, http client, config).
- `src/types/` — shared types/interfaces.
- `src/index.ts` (or `src/server.ts`) — composition root only.

---

## Architectural patterns

- Controllers route and validate (zod / joi / class-validator). Services contain logic. Repositories own the DB. **No SQL/ORM calls in controllers.**
- Errors as typed classes (`NotFoundError`, `ValidationError`, `AuthError`) → translated to HTTP at a single boundary (error-handling middleware).
- Don't `throw` strings or untyped objects. Don't swallow errors silently.
- Async everywhere; never block the event loop with sync I/O in request paths.
- Cancellation: pass `AbortSignal` through long-running operations.

---

## LoopBack specifics

- Repositories generated from models — don't bypass them with raw DataSource calls in controllers.
- Use `@authenticate` and `@authorize` decorators on controller methods, not ad-hoc checks.
- Use the dependency injection container; don't `new` services in controllers.
- Interceptors for cross-cutting concerns (logging, metrics, request validation).
- OpenAPI spec is generated — keep model/controller decorators accurate; don't hand-write `openapi.json`.

---

## Logging & observability

- Structured JSON logging — `pino` preferred over `winston` for new code.
- Every request gets a correlation/trace id (`x-request-id`), propagated to downstream calls.
- Log levels:
  - `error` — operator-actionable
  - `warn` — degraded but handled
  - `info` — lifecycle events
  - `debug` — off in prod
- **Never log** secrets, tokens, full PII, or full request bodies on auth/sensitive routes.
- Metrics: Prometheus / OpenTelemetry; trace at service boundaries.

---

## Database access

- Use a query builder or ORM consistently (Prisma / Drizzle / TypeORM / Knex / Mongoose). Don't mix.
- Migrations are mandatory; no schema changes via ad-hoc SQL.
- Parameterized queries always — string interpolation into SQL is a security defect.
- Connection pooling configured explicitly; verify under load.
- N+1 guards: explicit joins / includes; review query logs in dev.

---

## Pre-PR checklist

```bash
npx tsc --noEmit
npm run lint
npm test                    # Jest / Vitest / node:test
npm run build               # if applicable
```

Tests:
- Unit tests for services and pure utilities.
- Integration tests for routes + DB using a real test DB (testcontainers or docker-compose). Don't mock the DB.
- Contract tests for external API consumers.

---

## Security

- Helmet (Express) / `@fastify/helmet` for security headers.
- Validate `Content-Type` and body schema on every mutating endpoint.
- Rate limit auth and write endpoints (`express-rate-limit`, `@fastify/rate-limit`).
- CORS allowlist — not `*` — for credentialed endpoints.
- Secrets via env / secret manager; never in code or logs.
- `JSON.parse` on untrusted input wrapped in try/catch with a size limit upstream.
- `child_process` calls: pass args as arrays, never use `shell: true` with user input.
- Pin and audit dependencies (`npm audit`, Snyk); resolve high-severity findings before release.
