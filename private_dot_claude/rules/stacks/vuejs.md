# Vue.js + TypeScript Rules

Stack-specific rules. Load **alongside** `../general-rules.md` when working in a Vue.js project (Vite or Nuxt).

---

## File layout

- Components in `src/components/`; one SFC per file. PascalCase filenames.
- Views/pages in `src/views/` (Vite) or `pages/` (Nuxt — file-based routing).
- Composables in `src/composables/`, named `useX.ts`.
- Stores (Pinia) in `src/stores/`.
- API clients in `src/api/` or `src/lib/api/`.
- Shared types in `src/types/` or `*.types.ts` siblings.

---

## Component conventions

- Composition API with `<script setup lang="ts">`. No Options API in new code unless the project is uniformly on it.
- One SFC per file.
- `defineProps<{ ... }>()` with explicit TypeScript types — not the string-array runtime form, when types are known.
- `defineEmits<{ (e: 'event-name', payload: T): void }>()`.
- Prefer composables over mixins. Mixins are forbidden in new code.
- `<script setup>` exposes are implicit — don't try to `export` from inside it.

---

## State management

- **Pinia** for shared state. No Vuex in new code.
- Local component state stays in the component.
- Don't reach into a store from a component that could receive the value as a prop — that breaks reusability.
- Stores are composable functions: `defineStore('name', () => { ... })` setup syntax over options syntax.

---

## TypeScript

- `strict: true` in `tsconfig.json`.
- `vue-tsc` for type-checking SFCs.
- Refs typed explicitly when initial value is `null`: `const el = ref<HTMLDivElement | null>(null)`.
- `unknown` over `any` at API boundaries.

---

## Reactivity

- `ref` for primitives and single values; `reactive` for objects you'll mutate in place.
- `shallowRef` / `shallowReactive` for large collections that don't need deep tracking.
- Don't destructure from `reactive()` — you lose reactivity. Use `toRefs` if you must.
- `computed` is pure — no side effects, no async.
- `watch` for side effects; `watchEffect` only when the dependencies are obvious from the body.

---

## Pre-PR checklist

```bash
npx vue-tsc --noEmit        # typecheck
npm run lint                # ESLint
npm test                    # Vitest (preferred)
npm run build               # production build
```

Component tests: Vitest + `@vue/test-utils` or `@testing-library/vue`. Query by role, not by test id.

---

## Performance

- `defineAsyncComponent` for below-the-fold heavy components.
- Route-level code splitting via dynamic `import()` in router config.
- `v-memo` / `v-once` only where measured.
- `v-for` always with a stable `:key` — never `index` for mutable lists.
- Avoid expensive `computed` chains; cache derived data at the store level if shared.

---

## Security

- `v-html` is `dangerouslySetInnerHTML` — never use with untrusted input. Sanitize via DOMPurify when unavoidable.
- `VITE_*` / `VUE_APP_*` env vars ship to the browser — never put real secrets behind those prefixes.
- Configure CSP headers at the server/edge.
- For Nuxt: server routes in `server/api/` must validate inputs (zod / valibot) and enforce authz.
