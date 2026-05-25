# React + Vite + TypeScript (SPA) Rules

Stack-specific rules. Load **alongside** `../general-rules.md` for a Vite-bundled React SPA. For Next.js, use `nextjs-react.md` instead.

---

## File layout

- Pages/screens in `src/pages/` (or `src/views/`) — one route per file.
- Reusable UI in `src/components/` — one component per file.
- Hooks in `src/hooks/`, named `useX.ts`.
- HTTP clients / data access in `src/api/` or `src/lib/api/`.
- Cross-cutting utils (logger, formatters, env) in `src/utils/` or `src/lib/`.
- Shared types in `*.types.ts` siblings or `src/types/`.
- Route definitions in a single `src/routes.tsx` — config-driven; don't hand-wall `<Routes>` in `App.tsx`.

Inline JSX inside a page past ~150 lines is a smell — extract subcomponents.

---

## Component conventions

- Functional components + hooks only.
- Named exports for components, hooks, utilities, types. Default exports only where a tool demands them.
- One component per file. Co-locate styles/types/small helpers; promote to siblings (`*.types.ts`, `*.utils.ts`) when reused.
- Components render. Data fetching, mutation, side effects live in hooks or services.
- `React.lazy` + `<Suspense>` for route-level code splitting.

---

## TypeScript

- `strict: true`. Keep `noUnusedLocals`, `noUnusedParameters`, `verbatimModuleSyntax` on — don't silence per-file.
- `verbatimModuleSyntax` requires `import type { ... }` for type-only imports; mixing breaks builds.
- No `any` without a one-line `// reason:` comment.
- `interface` for shapes that get extended; `type` for unions / intersections / mapped types.
- `unknown` over `any` at API boundaries; narrow with type guards or zod.
- Discriminated unions over enum-flag bags.

---

## State, data, and forms

- Component state: `useState` / `useReducer`.
- Shared client state: pick **one** of Zustand / Jotai / Redux Toolkit per project. Don't scatter Context for state that belongs in a store.
- Server state: TanStack Query (React Query) or SWR. Don't roll your own `useEffect(fetch...)` cache.
- HTTP: one shared client per API, with auth/interceptors in one place. Components call typed wrappers, not `axios.get` directly.
- Forms: `react-hook-form` + `zod` resolver. Schemas next to the form or in `src/lib/schemas/`.

---

## Routing

- `react-router-dom` v6+ (match the project's installed major).
- Auth/role/feature-flag guards wrap routes in a `<ProtectedRoute>`-style component — not scattered `if (!user) navigate(...)` in page bodies.
- Lazy-load route components with `React.lazy` + `<Suspense>`.

---

## Env vars & build

- All client-readable env vars **must** be `VITE_`-prefixed — others are invisible to `import.meta.env`.
- `VITE_*` ships to the browser; never put real secrets there (only public URLs, flags, build metadata).
- Access via `import.meta.env.VITE_FOO`; don't shim `process.env` in client code.
- Sensible fallbacks at the boundary (e.g. one place in the API client), not at every callsite.
- `npm run build` → static assets in `dist/`. `vite preview` is a local sanity-check, never a prod server.
- If the project deploys `vite dev` behind a reverse proxy instead of serving `dist/`, flag it — dev-only paths (incl. `import.meta.env.DEV` branches) will execute in prod.

---

## Pre-PR checklist

```bash
npx tsc --noEmit            # typecheck
npm run lint                # ESLint
npm test                    # Vitest
npm run build               # production build must succeed
```

Tests in `__tests__/` siblings or co-located `*.test.ts(x)`. Component tests: Vitest + `@testing-library/react` — query by role, not test id. Mock the network at the HTTP-client boundary, not inside components.

---

## Performance

- Route-level code splitting via `React.lazy` + `<Suspense>` for every non-landing route.
- `useMemo` / `useCallback` only when a profiler shows a problem.
- Stable `key` on every `.map()` — never array index for mutable lists.
- Images: `loading="lazy"` below the fold; set `width`/`height` to avoid CLS; prefer AVIF/WebP.
- Bundle audit before shipping major features (`rollup-plugin-visualizer` or `vite-bundle-visualizer`). Watch for duplicate large deps (moment, lodash, MUI variants).

Core Web Vitals targets and a11y rules: see `general-rules.md` §5–6.

---

## Security

- `dangerouslySetInnerHTML` is a security boundary — never with untrusted input. Sanitize via DOMPurify when unavoidable.
- External links: `target="_blank"` always paired with `rel="noopener noreferrer"`.
- Tokens in `sessionStorage` / `localStorage` are XSS-readable — accept that risk or move to httpOnly cookies. Centralize read/write/clear and 401 handling in one module.
- CSP at server/edge, not in `<meta>` (CSP-via-meta has gaps).
- Don't log tokens, full request bodies on auth routes, or client-side PII.
