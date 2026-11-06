---
name: hd-frontend
description: "Vite + React 19 rules: React Router route object, TanStack Query + axios, Zustand, shadcn + Tailwind v4, minimal dense UI, scroll fades, accessibility. Use when changing React components or hooks, React Router routes, Tailwind styling, data fetching or client state."
license: MIT
metadata:
  author: huanngdev
---

# Frontend

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`. Forms & schemas: `hd-validate`. Session: `hd-auth`.

Docs: hd-index docs sources (React, React Router, Vite / Vitest, TanStack, axios, Zustand, shadcn/ui, Tailwind CSS, Motion, Testing Library, MSW, Playwright).

## Always
- Vite (latest) + React 19 SPA with React Compiler on. Next.js only if the project already chose it.
- Components are presentational; state, effects and data access live in hooks.
- App REST data only through TanStack Query + the shared axios instance; responses parsed with shared Zod schemas. SDK-owned transports (Better Auth client, AI SDK streams) are the only exceptions.
- UI is minimal and dense: no card inside card, few borders, tight spacing. Every scrollable region is a shadcn `ScrollArea` with a scroll fade (`ui.md`).
- Every screen handles loading, empty, error and success.

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/react.md` | App setup, folder structure, routes/guards, components & hooks, error boundaries, frontend tests |
| `references/state.md` | API calls, queries, mutations, errors from the API, client/URL state |
| `references/ui.md` | Layout, Tailwind/theme tokens, shadcn components, scroll, dark mode, density, icons, motion |
| `references/a11y.md` | Keyboard, focus, labels, contrast, reduced motion |
