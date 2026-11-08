# Monorepo (Turborepo + Bun + VoidZero toolchain)

## Toolchain (prefer VoidZero / Oxc tools everywhere)
| Job | Tool |
|---|---|
| Runtime, package manager, scripts | Bun |
| Task runner | Turborepo |
| Lint | oxlint with `--type-aware` (+ `oxlint-tsgolint`), no ESLint |
| Format | oxfmt (no Prettier) |
| Bundle / dev server | Vite; Next.js only if the project chose it |
| Test | Vitest, always run as `bun --bun vitest run` (Bun APIs available in tests) |
| Package build | tsdown |
Use the full Oxc/Vite ecosystem even where tools are beta; prefer them over alternatives.

## Layout
```
apps/<app>         # deployable: web, api, worker, …  (each has its own .env + .env.example)
packages/shared    # code shared by apps: contracts, Zod schemas, types, utils
packages/<domain>  # shared domain/infra code (db, auth, ui, …)
packages/config    # tsconfig presets, oxlint presets, oxfmt config, vitest base, tsdown base
```
Root `package.json`: `"private": true`, `"packageManager": "bun@<version>"`, `"workspaces": ["apps/*", "packages/*"]`. Root deps = repo tooling only (`turbo`, `oxlint`, `oxlint-tsgolint`, `oxfmt`, `tsdown`, `vitest`, `typescript`).

## turbo.json baseline
```json
{
  "$schema": "https://turborepo.dev/schema.json",
  "ui": "tui",
  "cacheMaxSize": "10GB",
  "cacheMaxAge": "7d",
  "tasks": {
    "build": { "dependsOn": ["^build"], "inputs": ["$TURBO_DEFAULT$", ".env*"], "outputs": ["dist/**"] },
    "dev": { "dependsOn": ["^build"], "cache": false, "persistent": true },
    "lint": { "dependsOn": ["^build"] },
    "check-types": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["^build"], "inputs": ["$TURBO_DEFAULT$", ".env*"], "outputs": ["coverage/**"] },
    "test:integration": { "dependsOn": ["^build"], "cache": false }
  }
}
```
- `ui: "tui"`: one terminal; pick an app/package task in the task list to see its logs and interact with it. Don't add per-app terminal scripts.
- `cacheMaxSize` / `cacheMaxAge`: always set. Override per machine with `TURBO_CACHE_MAX_SIZE` / `TURBO_CACHE_MAX_AGE`. No remote cache.
- `^build` on `dev`/`lint`/`check-types`/`test`: dependents always see fresh `dist` types.
- Add framework outputs per app (e.g. `.next/**`, `!.next/cache/**`) in that app's `turbo.json` or a `app#build` task.
- Every env var a task reads goes in that task's `env` (or `globalEnv`); `.env*` files a task loads go in its `inputs`. Otherwise cache hits are wrong.
- Tasks that depend on running services (DB, storage) — integration tests, e2e — are separate scripts with `cache: false`.

## Root scripts
```json
"dev": "turbo run dev",
"build": "turbo run build",
"lint": "turbo run lint",
"check-types": "turbo run check-types",
"test": "turbo run test",
"test:integration": "turbo run test:integration",
"format": "oxfmt -c packages/config/oxfmt.json",
"format:check": "oxfmt --check -c packages/config/oxfmt.json",
"check": "bun run format:check && turbo run lint check-types test build"
```
With `packages/db`, also root wrappers `"db:<task>": "bun run --filter '@<scope>/db' db:<task>"` for `generate`, `migrate`, `check`, `seed`.
One app: `bunx turbo run dev --filter=<package-name>`.

## Shared code
- Logic, types, schemas, constants or UI used by ≥ 2 apps → move to a package first, then import it. Never duplicate.
- Apps never import from another app. Packages never import from apps.
- Contract changes (API shapes, Zod schemas) start in `packages/shared`.
- Same third-party version across workspaces; use Bun `catalog:` when the repo has a catalog.

## Adding things
- New app/package: copy the shape of an existing one (package.json fields, tsconfig, `.oxlintrc.json`, vitest config, script names). The workspaces glob picks it up.
- New dependency: install in the workspace that uses it (`bun add <pkg>` inside that folder). Ask before adding (`hd-core` workflow.md).
