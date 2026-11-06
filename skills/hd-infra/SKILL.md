---
name: hd-infra
description: huanngdev's infrastructure rules for Turborepo + Bun monorepos (internal packages built with tsdown, shared packages/config for tsconfig, oxlint, oxfmt and Vitest, turbo.json cache limits and TUI), Docker Compose with generated secrets in .env files, and GitHub Actions CI. Use when creating or changing turbo.json, workspaces, packages/*, lint/format/tsconfig/vitest config, compose.yaml, .env/.env.example, or .github/workflows.
license: MIT
metadata:
  author: huanngdev
---

# Infra

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`.

Docs: hd-index docs sources (Turborepo, Bun, Oxc, tsdown, Vite / Vitest).

## Always
- Monorepo = Turborepo + Bun workspaces. Run tasks through root scripts (`bun run <task>`), which call `turbo run`.
- Toolchain from the Oxc/Vite ecosystem: oxlint, oxfmt, Vite, Vitest. No ESLint, no Prettier.
- Anything used by more than one app lives in a package under `packages/`; tool configs live in `packages/config`. Never copy code or config between apps.
- No credential is ever written in a committed file. Secrets are generated into `.env` files and referenced by name.

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/monorepo.md` | turbo.json, workspaces, new package/app, shared code, tsconfig/oxlint/oxfmt/vitest config |
| `references/docker.md` | compose.yaml, local services, `.env` / `.env.example`, generating secrets |
| `references/ci.md` | `.github/workflows`, CI checks, caching in CI, Dependabot |
