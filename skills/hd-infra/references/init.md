# New project init

Use when the user asks to create, init or scaffold a new project/repo. Every project starts identical.

## No questions
- Everything in this file is pre-approved: its dependencies, MCP servers, official vendor skills, images and files. Don't ask, don't propose alternatives, don't write ADRs for these defaults.
- Derive inputs, never ask for them:
  - name = current folder name (kebab-case); package scope `@<name>`.
  - one-line purpose = the user's request; else `TODO` in `AGENTS.md`.
  - docs language = `hd-index` default (Vietnamese) unless the request is written in another language.
- Only the request can change the profile or a default below. Still ask before anything outward-facing (`hd-core` workflow.md): pushing, creating the GitHub repo, real secrets, deploys.

## Profile
| Part | Included |
|---|---|
| `packages/config`, `packages/shared`, `packages/db`, `packages/auth`, `apps/api`, `apps/web` | always |
| `packages/ai` (`hd-ai`) | request mentions AI / LLM / chat |
| S3 storage (`hd-backend` storage.md) | request mentions uploads / files / images |
| Redis (`hd-backend` storage.md) | request mentions cache, queues or multiple instances |
| Mailpit (local SMTP catcher) | request mentions email (verification, reset, notifications) |
Not in the profile = not scaffolded. Add it later when a task needs it.

## Versions
- Latest stable at init time, then pinned: `bun --version` → `packageManager`; `bun info <pkg> version` for npm packages; Docker Hub tags for images.
- Images: `postgres:18-alpine`, `redis:<x.y>-alpine`, `rustfs/rustfs:<x.y.z>` (S3-compatible; replaces MinIO), `axllent/mailpit:<vX.Y>`. Never `latest`.
- Ports: standard defaults (Postgres 5432, Redis 6379, S3 9000, Mailpit SMTP 1025 / UI 8025, api 3000, web 5173), localhost only. A port already in use → change it in the root `.env`, not in compose.

## Steps (in order)
1. `git init -b main`. Copy from this skill:
   - `assets/init/gitignore` → `.gitignore`
   - `assets/init/bunfig.toml` → `bunfig.toml`
   - `assets/init/claude-settings.json` → `.claude/settings.json` (enables the `huanngdev` plugin + allowlist)
   - `assets/init/dependabot.yml` → `.github/dependabot.yml`
   - `assets/gen-env.ts` → `scripts/gen-env.ts`
2. Root `package.json`, `turbo.json` and root scripts exactly as in `monorepo.md` (incl. `env:gen`).
3. `packages/config` presets (`packages.md`).
4. `packages/shared`: `errors.ts`, `page.ts`, `permissions.ts` (`hd-backend` api.md, `hd-validate` schemas.md, `hd-auth` permissions.md).
5. `packages/db`: client, standard columns, empty `seed.ts`, `drizzle.config.ts`, `db:*` scripts (`hd-backend` data.md).
6. `packages/auth` (`hd-auth` setup.md): email + password, admin/member roles; generate the auth schema, then the first migration.
7. `apps/api` (`hd-backend` api.md): `env.ts`, `app.ts` with the full middleware order, `/health`, `/ready`, `/openapi.json`, `/docs`, graceful shutdown.
8. `apps/web`: `bunx --bun shadcn@latest init --preset b0 --template vite --pointer --no-monorepo -c apps -n web`, then the `hd-frontend` structure: `env.ts`, `lib/api.ts`, providers, route object, sign-in route, app layout with `ScrollArea` wrapper.
9. `compose.yaml`, root `.env.example`, each app's `.env.example` (`docker.md`); run `bun run env:gen`.
10. `.github/workflows/ci.yml` from `ci.md` (+ the `db:check` step).
11. Docs: `AGENTS.md` from `hd-core` assets (fill stack, commands, code map), `CLAUDE.md` = `@AGENTS.md`, short `README.md`, `docs/decisions/0001-stack.md` listing the profile and pinned versions.
12. `.mcp.json` with the `hd-index` docs-sources entries for the stack (zod-docs, better-auth, tanstack, shadcn, playwright); install the official vendor skills listed there for the stack into the project.

## Verify, then commit
```sh
bun install
docker compose config --quiet && docker compose up -d --wait
bun run --filter '@<name>/db' db:migrate
bun run check
git diff --check
```
- All green → one commit on `main`: `chore: scaffold project` (no remote yet, so no PR). Something fails → fix it; never weaken a check.
- Report: profile, pinned versions, commands run + results, then next steps for the user: `gh repo create <name> --private --source . --push`, branch protection on `main` with the `ci` check required.
