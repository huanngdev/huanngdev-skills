# React app (Vite + React 19)

## Setup
- `vite.config.ts`: `react({ compiler: true })` from `@vitejs/plugin-react` — the Rust React Compiler (experimental), which needs `bun add -d oxc-transform-react`. If it fails on the project, fall back to `babel({ presets: [reactCompilerPreset()] })` with `@rolldown/plugin-babel` + `@babel/core` (+ `@types/babel__core`) + `babel-plugin-react-compiler` — check the plugin README for the installed version.
- With the compiler on, don't add `useMemo` / `useCallback` / `memo` by hand unless a measured case needs a stable identity.
- Env through `src/env.ts` (`hd-validate`), imported first in `main.tsx`.

## Structure
```
src/
  main.tsx            # env, providers, <RouterProvider router={router} />
  app/router.tsx      # export const router = createBrowserRouter(routes)
  app/routes.tsx      # export const routes: RouteObject[] = [...]
  app/providers.tsx   # QueryClientProvider, ThemeProvider, Toaster
  routes/<name>-route.tsx        # one page component per route
  layouts/<name>-layout.tsx      # shells with <Outlet />
  features/<feature>/{components,hooks,lib,api.ts}
  components/ui/      # shadcn (generated, never edited)
  components/         # reusable app UI composed from components/ui; props only
  lib/                # api client, shared pure functions
```
Shared across apps → `packages/ui` / `packages/shared` (see `hd-infra`).

## Routes = one exported object
```ts
export const routes: RouteObject[] = [
  { path: "/sign-in", lazy: () => import("@/routes/sign-in-route") },
  {
    middleware: [requireSession],                // runs before every loader/action below
    lazy: () => import("@/layouts/app-layout"),
    errorElement: <RouteError />,
    children: [
      { index: true, lazy: () => import("@/routes/home-route") },
      { path: "projects/:projectId", lazy: () => import("@/routes/project-route") },
    ],
  },
  { path: "*", lazy: () => import("@/routes/not-found-route") },
];
```
- No `<Routes>` / `<Route>` JSX and no wrapper components around individual routes.
- Guards are route `middleware` on the parent: `requireSession` reads the session (Better Auth client via the query cache) and `throw redirect("/sign-in?redirectTo=…")`. Not a parent `loader`: loaders run in parallel, so child loaders would start first.
- Client guards are UX only; the API authorizes every request (`hd-auth`). `redirectTo` is validated as a same-origin path before navigating (`hd-core` security.md).
- Every route is `lazy` (code splitting per route). Route modules export `Component` (plus `loader` / `ErrorBoundary` when needed), not a default export. Paths built with constants/`href()`, not string concatenation scattered in components.
- `errorElement` on the root and on each layout route; it renders a friendly error state, never a stack trace.

## Components & hooks (UI and logic never mix)
- Components only render: props, hook calls, JSX. No logic in a component file — no fetching, mutations, effects, timers, `useState`/`useReducer`, validation, business rules, sorting/filtering/mapping data to a new shape, formatting.
- Allowed in a component: destructuring, conditional rendering on values a hook returned, `list.map` to JSX, and inline handlers that only forward to one hook action (`onClick={() => remove(item.id)}`). Anything longer → an action in the hook.
- Two kinds of components:
  - Reusable UI (`components/`, `features/<f>/components/`): props in, events out (`onX`); no feature hooks, no API knowledge; composed from shadcn `components/ui`.
  - Route/container (`routes/*-route.tsx`, one per screen section): calls the feature hook(s) and wires their result into reusable UI. No markup beyond layout.
- Hooks (`features/<f>/hooks/use-*.ts`) own every piece of state, effect, query, mutation and handler; return a named object `{ …state, …actions }`, not tuples. UI-only state (open, tab, selection) too: `use-<thing>-state.ts`. Prefer uncontrolled shadcn primitives (`DialogTrigger`) when no state is needed.
- Pure functions (formatting, mapping, rules) → `features/<f>/lib/*.ts` or `lib/`, called from hooks; never wrap a pure function in a hook.
- Derive values during render inside the hook; don't sync state with effects. One global listener per event.
- File names kebab-case; components PascalCase; hooks `useX`; handlers `handleX`; event props `onX`.

## Tests
- Vitest: pure `lib` functions as plain unit tests, hooks with `renderHook`, components with Testing Library (`test/` mirror of `src/`), MSW for API responses.
- Playwright for the main user flows (sign-in, create, edit, delete).
- Query by role/label (`getByRole`), not by class or test id unless no accessible handle exists.
