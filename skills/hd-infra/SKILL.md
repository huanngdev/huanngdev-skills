---
name: hd-infra
description: "Monorepo rules and new-project init: Turborepo + Bun, tsdown packages, shared oxlint/oxfmt/tsconfig/Vitest config, Docker Compose with generated .env secrets, GitHub Actions. Use when creating a new project or changing turbo.json, workspaces, packages, tool configs, compose, .env or CI."
license: MIT
metadata:
  author: huanngdev
---

# Infra

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`.

Docs: hd-index docs sources (Turborepo, Bun, Oxc, tsdown, Vite / Vitest).

## Always
- Monorepo = Turborepo + Bun workspaces. Run tasks through root scripts (`bun run <task>`), which call `turbo run`.
- Anything used by more than one app lives in a package under `packages/`; tool configs live in `packages/config`. Never copy code or config between apps.
- No credential is ever written in a committed file. Secrets are generated into `.env` files and referenced by name.

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/init.md` | Creating, initializing or scaffolding a new project/repo (profile, defaults, steps, no questions) |
| `references/monorepo.md` | turbo.json, workspaces, layout, root scripts, shared code, adding an app/package |
| `references/packages.md` | Building an internal package (tsdown, exports, isolatedDeclarations), tsconfig/oxlint/oxfmt/vitest presets in `packages/config` |
| `references/docker.md` | compose.yaml, local services, `.env` / `.env.example`, generating secrets |
| `references/ci.md` | `.github/workflows`, CI checks, caching in CI, Dependabot |
