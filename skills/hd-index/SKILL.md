---
name: hd-index
description: Entry point for huanngdev's skills. Global rules that apply to every task (challenge the user's proposal, Bun-first, Oxc/Vite toolchain, strict TypeScript, official docs, verify before claiming done) and a map of which hd-* skill to load for which task. Use when starting any coding, design, review or planning task in huanngdev's projects, before picking other hd-* skills.
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
- If the project lacks a listed MCP or skill it needs, add it to the project (that file says how).
- Technology not listed: search for an official docs MCP, skill or `llms.txt` first, then propose a registry row to the user.

### Language
- Code, identifiers, comments, commits, PRs, logs: English.
- Chat with the user: Vietnamese. Project docs: the language the project uses.

## Skill map
Domain skills. Each `SKILL.md` is short; the rules live in `references/<topic>.md`. Load the skill, then read **only** the topic files the task touches. If a skill or file isn't there yet, skip it silently.

| Skill | Topic file | Read when the task touches |
|---|---|---|
| `hd-index` | `docs-sources.md` | Before using any library/tool API; adding MCP servers or vendor skills |
| `hd-core` | `workflow.md` | Any implementation, bug fix, refactor; before hand-off |
| | `git.md` | Branches, commits, PRs, releases |
| | `docs.md` | AGENTS.md, CLAUDE.md, ADRs, changelog, plans, milestones |
| | `typescript.md` | Any TypeScript code |
| | `testing.md` | Writing or fixing tests |
| | `security.md` | Secrets, env, untrusted input, logging, PII |
| `hd-frontend` | `react.md` | Components, hooks, Server/Client boundaries |
| | `state.md` | Client state, data fetching, cache invalidation, forms |
| | `ui.md` | Styling, Tailwind, component kit, theming, UI copy |
| | `a11y.md` | Keyboard, focus, semantics, reduced motion |
| `hd-backend` | `api.md` | Routes, services, middleware, errors, responses, pagination |
| | `data.md` | Schema, queries, migrations, transactions, seeds |
| | `storage.md` | File uploads (MinIO/S3), caching (Redis) |
| `hd-validate` | `schemas.md` | Zod schemas, DTOs, shared contracts, parsing |
| | `env.md` | Env loading/validation, new env vars |
| | `forms.md` | Frontend forms, client-side validation |
| `hd-auth` | `setup.md` | Better Auth package, Hono mounting, sessions, passwords |
| | `permissions.md` | Roles, permissions, ownership checks |
| `hd-ai` | — | Any LLM call, AI streaming, AI SDK / OpenRouter code |
| `hd-infra` | `monorepo.md` | Workspace layout, Turborepo, shared configs, package boundaries |
| | `ci.md` | GitHub Actions, CI checks, Dependabot |
| | `docker.md` | Docker, Compose, local infrastructure |

`hd-validate` (Zod), `hd-auth` (Better Auth) and `hd-ai` (AI SDK + OpenRouter) cover only how we use those libraries; API details come from their docs MCP / official skills. Other third-party services (Vercel, Cloudflare, Neon, shadcn, …) are not covered: use the vendor's official skill or docs when the task touches them. Vendor advice never overrides project rules.

## Docs line in every skill
Skills never embed MCP configs or install commands. They point here with exactly: `Docs: hd-index docs sources (<Tech>, …).`

## Combining skills
- Typical full-stack feature: `hd-core` (workflow + typescript) + `hd-validate` + `hd-frontend` and/or `hd-backend`, reading 3–6 topic files in total.
- Conflict between two topic files: the more specific one wins (e.g. `data.md` over `api.md` on persistence).
