# Next.js + React + TypeScript Rules

Stack-specific rules. Load **alongside** `../general-rules.md` when working in a Next.js / React project.

---

## File layout

- Pages in `src/app/**/page.tsx`; route segments follow App Router conventions.
- Reusable UI in `src/components/` — one component per file.
- Data access / API clients in `src/lib/` (or `src/data/`).
- API handlers in `src/app/api/**/route.ts`.
- Shared types in `*.types.ts` siblings or `src/types/`.
- Hooks in `src/hooks/`, named `useX.ts`.

Inline JSX inside `page.tsx` is a smell. If a pattern (hero, section wrapper, icon badge, form field, card, breadcrumb, JSON-LD block) appears more than once, extract it under `src/components/`.

---

## Component conventions

- Functional components + hooks. No class components.
- Server Components by default; reach for `"use client"` only when interactivity actually requires it.
- One component per file → default export is acceptable for the component itself; named exports for types, helpers, and sub-parts.
- Hooks, utilities, and types → named exports.
- Next.js route files require **default exports** — the framework demands them: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`, `template.tsx`, `opengraph-image.tsx`, `default.tsx`.

---

## TypeScript

- `strict: true` in `tsconfig.json`.
- No `any` without a `// reason: <one line>` comment.
- `interface` for object shapes that get extended; `type` for unions, intersections, mapped types.
- Discriminated unions over enum-flag bags.
- `unknown` over `any` at API boundaries; narrow with type guards.

---

## State, data, and forms

- Server state belongs to Server Components / Route Handlers; client state via hooks (`useState`, `useReducer`).
- Cross-component client state: Zustand / Jotai / Redux Toolkit — pick one per project.
- Forms: `react-hook-form` + `zod` resolver. Validation schemas live next to the form or in `src/lib/schemas/`.
- Server Actions and Route Handlers must validate inputs with zod (or equivalent) and enforce authz.

---

## Pre-PR checklist

```bash
npx tsc --noEmit            # typecheck
npm run lint                # ESLint
npm test                    # Jest / Vitest
npm run build               # production build (or `npm run analyze` for bundle size)
```

Tests live next to the code or in `__tests__/` siblings. React Testing Library for component tests — query by role, not by test id.

---

## Performance

- `next/dynamic` for below-the-fold heavy components (carousels, charts, estimators, editors).
- `next/image` for every raster image; set `sizes` when responsive.
- `next/font` for self-hosted fonts; never `<link>` to Google Fonts directly.
- `useMemo` / `useCallback` only when a profiler shows a problem — premature memoization adds noise.
- Streaming + `<Suspense>` for slow data on the same route, not blocking the whole page.

---

## Security

- Keep the secure headers configured in `next.config.ts` (CSP, X-Frame-Options, Referrer-Policy, Permissions-Policy).
- `NEXT_PUBLIC_*` env vars ship to the browser — never put real secrets behind that prefix.
- Don't pass server-only data through props of `"use client"` components if it shouldn't be in the bundle.
- Server Actions: validate every input, re-check authorization server-side, set `revalidatePath` / `revalidateTag` deliberately.
