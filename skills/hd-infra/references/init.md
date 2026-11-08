# New project init

Use when the user asks to create, init or scaffold a new project/repo. Every project starts identical.

## No questions
- Everything in this file is pre-approved: its dependencies, MCP servers, official vendor skills, images and files. Don't ask, don't propose alternatives, don't write ADRs for these defaults.
- Derive inputs, never ask for them:
  - name = current folder name → lowercase, every run of characters outside `a-z0-9` → `-`, trim `-`; empty → `app`. Package scope `@<name>`.
  - one-line purpose = the user's request; else `TODO` in `AGENTS.md`.
  - docs language: `hd-index` rule.
- Only the request can change the profile or a default below. Still ask before anything outward-facing (`hd-core` workflow.md): pushing, creating the GitHub repo, real secrets, deploys.

## Profile
| Part | Included |
|---|---|
| `packages/config`, `packages/shared`, `packages/db`, `packages/auth`, `apps/api`, `apps/web` | always |
| `packages/ai` (`hd-ai`) | request mentions AI / LLM / chat |
| S3 storage (`hd-backend` storage.md) | request mentions uploads / files / images |
| Redis (`hd-backend` storage.md) | request mentions cache, queues or multiple instances |
| Mailpit (`docker.md`) | request mentions email (verification, reset, notifications) |
Not in the profile = not scaffolded. Add it later when a task needs it.

## Versions & ports
- npm packages: `bun add <pkg>` without a version, after `bunfig.toml` is in place, so Bun picks the newest version past the release-age gate; `bun.lock` pins it. `packageManager` = `bun@$(bun --version)`.
- Images and ports: `docker.md` (standard defaults; images pinned to the newest stable tag on Docker Hub at init).
- Busy host port → first free port above the default, written to the root `.env` before `env:gen`. Ports live only in the root `.env.example` (`API_PORT=3000`, `WEB_PORT=5173`, service ports); other `.env.example` files map them with `${…}`:
  - `apps/api`: `PORT=${API_PORT}`, `BETTER_AUTH_URL=http://localhost:${API_PORT}`, `CORS_ORIGINS=http://localhost:${WEB_PORT}`
  - `apps/web`: `WEB_PORT=${WEB_PORT}`, `VITE_API_URL=http://localhost:${API_PORT}`; `vite.config.ts` uses `loadEnv(mode, process.cwd(), "")` → `server: { port: Number(env.WEB_PORT), strictPort: true }` (the browser schema stays `VITE_*` only)
  - `packages/db`: `DATABASE_URL` from the `POSTGRES_*` keys

## Steps (in order)
1. `git init -b main`. Copy from this skill:
   - `assets/init/gitignore` → `.gitignore`
   - `assets/init/bunfig.toml` → `bunfig.toml`
   - `assets/init/claude-settings.json` → `.claude/settings.json` (plugin, MCP approvals, allowlist, secret-file denies — file rules don't stop scripts from opening files)
   - `assets/init/dependabot.yml` → `.github/dependabot.yml`
   - `assets/gen-env.ts` → `scripts/gen-env.ts`
2. Root `package.json`, `turbo.json` and root scripts exactly as in `monorepo.md` (incl. `env:gen`); `bun install`.
3. `packages/config`: copy `assets/config/` (`packages.md`).
4. `packages/shared`: `errors.ts`, `page.ts`, `permissions.ts` (`hd-backend` api.md, `hd-validate` schemas.md, `hd-auth` permissions.md).
5. `packages/db` (`hd-backend` data.md): client, standard columns, empty `seed.ts`, `drizzle.config.ts`, `.env.example` with `DATABASE_URL`. Scripts run on Bun so its `.env` loads: `"db:generate": "bun --bun drizzle-kit generate"`, same for `db:migrate`, `db:check`; `"db:seed": "bun src/seed.ts"`.
6. Compose + env: `compose.yaml`, root `.env.example`, each app's `.env.example` (`docker.md`); `bun run env:gen`; `docker compose up -d --wait`.
7. `packages/auth` (`hd-auth` setup.md): email + password; role as `additionalFields` with `input: false` (no admin plugin). `auth` is built by a factory taking `{ db, secret, baseURL, trustedOrigins }`; `server.ts` exports it plus an instance built from Zod-parsed `Bun.env`. Then:
   - `bunx turbo run build --filter=@<name>/auth...` (builds `shared` and `db` first)
   - from `apps/api` (so Bun loads its `.env`): `bunx --bun auth@latest generate --config ../../packages/auth/src/server.ts --output ../../packages/db/src/schema/auth.ts --yes`
   - `bun run --filter '@<name>/db' db:generate`, review the SQL, `db:migrate`.
8. `apps/api` (`hd-backend` api.md): `env.ts`, `app.ts` with the full middleware order, `/health`, `/ready`, `/openapi.json`, `/docs`, graceful shutdown.
9. `apps/web`: `bunx --bun shadcn@latest init --preset b0 --template vite --pointer --no-monorepo -c apps -n web`, then the `hd-frontend` structure: `env.ts`, `lib/api.ts`, providers, route object with sign-in, sign-up and a guarded home route inside an app layout using the `ScrollArea` wrapper.
10. `.github/workflows/ci.yml` from `ci.md` (+ the `db:check` step).
11. Docs: `AGENTS.md` from `hd-core` assets (fill stack, commands, code map), `CLAUDE.md` = `@AGENTS.md`, short `README.md`, `docs/decisions/0001-stack.md` listing the profile and pinned versions.
12. `.mcp.json` with the `hd-index` docs-sources entries for the stack (zod-docs, better-auth, tanstack, shadcn, playwright); install the official vendor skills listed there for the stack, non-interactively as that file says.

## Verify, then commit
```sh
docker compose config --quiet
bun run check
git diff --check
```
- All green → one commit on `main`: `chore: scaffold project` (no remote yet, so no PR).
- Then prove a clean checkout works like CI: clone into a temp dir, `bun install --frozen-lockfile && bun run env:gen && bun run check`, delete the clone. Fails → fix, amend the commit, repeat.
- Never weaken a check to get green.
- Report: profile, pinned versions, commands run + results, then next steps for the user: `gh repo create <name> --private --source . --push`, branch protection on `main` with the `ci` check required.
