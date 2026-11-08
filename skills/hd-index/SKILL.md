---
name: hd-index
description: "Entry point for huanngdev's skills: global rules (challenge the user, Bun + Oxc/Vite toolchain, docs research via MCP and skills) and the map of which hd-* skill and file to read. Use when starting any coding, review or planning task in huanngdev's projects."
license: MIT
metadata:
  author: huanngdev
---

# huanngdev skills index

Precedence: user's explicit decision > project `AGENTS.md` / `CODE_RULES.md` > hd-* skills > vendor skills > model defaults.

## Global rules (always apply)

### Think, don't just comply
- Treat every request as input, not a final decision. Before implementing, check whether a simpler, faster, safer or more maintainable solution exists.
- If one exists, say so briefly: the problem with the proposal, the better option, the tradeoff. Then let the user choose.
- Push back on: unnecessary complexity, new dependencies, premature abstraction, insecure shortcuts, anything that breaks a project invariant.
- New project: follow `hd-infra` init.md exactly, without questions or alternative proposals.
- Don't argue for its own sake. Once the user decides (or a plan in `docs/plans/` is agreed), execute it without re-litigating.
- Never invent requirements, permissions, metrics or integrations. State assumptions explicitly.

### Bun-first, Oxc/Vite toolchain
- Bun is the runtime, package manager and script runner: `bun install`, `bun add`, `bun run <script>`, `bunx <bin>`.
- Toolchain from the Oxc/Vite (VoidZero) ecosystem: oxlint (lint), oxfmt (format), Vite (dev/bundle), Vitest (tests). No ESLint, Prettier or Jest.
- Never use `npm`, `npx`, `yarn` or `pnpm` unless the repo's lockfile/scripts already require it.
- Prefer Bun built-ins (`Bun.file`, `Bun.password`, `bun:sqlite`, `Bun.$`) over extra packages when the code only runs on Bun. Code that must run elsewhere (Workers, browser, Node) uses web-standard APIs.

### Engineering defaults
- TypeScript strict, ESM, Zod at every external boundary.
- Tests live in a separate `test/` folder per package that mirrors `src/`, never next to the code. Run them with `bun --bun vitest run`.
- Every app with a `.env` validates it with Zod before starting (`hd-validate`).
- Smallest coherent change. Reuse existing code before adding new code.
- Never claim "done" without running the project's checks; report exactly what was and wasn't verified.
- Ask before destructive or outward-facing actions (deploy, remote migration, secrets, deleting data, force-push, paid API calls).

### Docs research (every technology)
- Never code a library API from memory. Before using a technology, look it up in `references/docs-sources.md` and use its docs MCP / official skill / `llms.txt`, matching the installed version.
- If the project lacks a listed MCP or skill it needs, propose adding it (it changes project config: ask first, see that file); meanwhile use the `llms.txt` / docs fallback.
- Technology not listed: search for an official docs MCP, skill or `llms.txt` first, then propose a registry row to the user.

### Language
- Code, identifiers, comments, commits, PRs, logs: English.
- Chat with the user: Vietnamese.
- Project docs (`AGENTS.md`, `docs/`): the language the project already uses; new projects default to Vietnamese with English technical terms. This is the only language rule; other skills don't restate it.

## Skill map
Domain skills. Each `SKILL.md` is short; the rules live in `references/<topic>.md`. Load the skill, then read **only** the topic files the task touches. If a skill or file isn't there yet, skip it silently.

| Skill | Topic file | Read when the task touches |
|---|---|---|
| `hd-index` | `docs-sources.md` | Before using any library/tool API; adding MCP servers or vendor skills |
| `hd-core` | `workflow.md` | Starting any task, ask-first boundaries, hand-off and reporting |
| | `design.md` | Planning a new feature or a change to data model, API contract, auth, money, integrations; trade-offs; recording the design for later features |
| | `git.md` | Branches, commits, PRs, merging |
| | `docs.md` | AGENTS.md, CLAUDE.md, ADRs, plans, milestones/progress, writing project docs |
| | `typescript.md` | Writing or reviewing any TypeScript |
| | `testing.md` | Writing or fixing tests, deciding what to test |
| | `security.md` | Secrets, untrusted input, redirects, outbound URLs, CSRF, headers, cookies, audit logging, dependencies |
| `hd-frontend` | `react.md` | App setup, folder structure, routes/guards, components & hooks, error boundaries, frontend tests |
| | `state.md` | API calls, queries, mutations, errors from the API, client/URL state |
| | `ui.md` | Choosing/adding any UI component (shadcn only), landing/marketing pages, layout, Tailwind/theme tokens, scroll, dark mode, density, icons, motion |
| | `a11y.md` | Keyboard, focus, labels, contrast, reduced motion |
| `hd-backend` | `api.md` | Routes, services, middleware, errors, responses, pagination, OpenAPI/Scalar docs, CORS, logging, health/shutdown, realtime |
| | `data.md` | Schema, queries, migrations, transactions, idempotency, seeds, DB tests |
| | `storage.md` | File uploads (S3-compatible) or caching (Redis) |
| `hd-validate` | `schemas.md` | Writing schemas/DTOs, shared contracts, parsing data, error formatting |
| | `env.md` | Creating or changing any app's env loading, `.env.example`, new env vars |
| | `forms.md` | Frontend forms and client-side validation |
| `hd-auth` | `setup.md` | Creating/changing the auth package, Hono mounting, session middleware, schema/IDs, env, CSRF/origin, rate limit, session revocation, passwords, MCP plugin |
| | `permissions.md` | Roles, permissions, protecting a use case, ownership checks |
| `hd-ai` | — | Any LLM call, AI streaming, AI SDK / OpenRouter code |
| `hd-infra` | `init.md` | Creating, initializing or scaffolding a new project/repo (profile, defaults, steps, no questions) |
| | `monorepo.md` | turbo.json, workspaces, layout, root scripts, shared code, adding an app/package |
| | `packages.md` | Building an internal package (tsdown, exports, isolatedDeclarations), tsconfig/oxlint/oxfmt/vitest presets in `packages/config` |
| | `docker.md` | compose.yaml, local services, `.env` / `.env.example`, generating secrets |
| | `ci.md` | `.github/workflows`, CI checks, caching in CI, Dependabot |

`hd-validate` (Zod), `hd-auth` (Better Auth) and `hd-ai` (AI SDK + OpenRouter) cover only how we use those libraries; API details come from their docs MCP / official skills. Other third-party tools and services (Vercel, Cloudflare, Neon, …) get no hd-* skill: use the vendor's official skill or docs (registry) when the task touches them. Vendor advice never overrides project rules.

## Docs line in every skill
Skills never embed MCP configs or install commands. They point here with exactly: `Docs: hd-index docs sources (<Tech>, …).`

## Combining skills
- Typical full-stack feature: `hd-core` (workflow + typescript) + `hd-validate` + `hd-frontend` and/or `hd-backend`, reading 3–6 topic files in total.
- Conflict between two topic files: the more specific one wins (e.g. `data.md` over `api.md` on persistence).
