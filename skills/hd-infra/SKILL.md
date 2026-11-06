---
name: hd-infra
description: Monorepo rules: Turborepo + Bun, tsdown packages, shared oxlint/oxfmt/tsconfig/Vitest config, Docker Compose with generated .env secrets, GitHub Actions. Use when changing turbo.json, workspaces, packages, tool configs, compose, .env or CI.
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
