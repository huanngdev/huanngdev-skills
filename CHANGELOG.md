# Changelog

All notable changes to the `huanngdev` plugin. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/) — rules in [AGENTS.md §7](AGENTS.md#7-versioning).

## [Unreleased]

### Changed
- `hd-infra`: assets are now tested in CI — structured files must parse, `gen-env.ts` has regression tests, and the `assets/config` presets are exercised in a temp consumer repo (`tsc` 7, oxlint, oxfmt, vitest). No rule changes.

## [1.1.0] - 2026-11-08

### Added
- `hd-infra`: `init.md` — new-project init with a fixed profile, derived inputs, pinned defaults, ordered steps and verification; no questions. Assets: `.gitignore`, `bunfig.toml`, Claude Code project settings (enables the `huanngdev` plugin, allowlist, `.env` read deny), Dependabot.

### Changed
- `hd-core`, `hd-index`: a new-project init follows `hd-infra` init.md without asking; its dependencies, MCP servers and vendor skills are pre-approved.
- `hd-backend`, `hd-infra`: default S3-compatible image is `rustfs/rustfs`, Mailpit for local email, standard ports overridden in the root `.env`.
- `hd-infra`: `packages/db` gets its own generated `.env`; CI runs `env:gen` before checks.
- `hd-index`: vendor skills install non-interactively at project scope for a fixed agent list (`-a claude-code codex -y`).
- `hd-infra`: exact `packages/config` presets as assets (tsconfig base/bun/package/vite-react, oxlint base/react/node, oxfmt, vitest base), verified with `tsc` 7 and oxlint.

### Fixed
- `hd-core`: `minimumReleaseAge` is in seconds (`259200`), not `"3d"`.

## [1.0.0] - 2026-11-06

### Added
- `hd-index`: entry point — global rules (challenge the user, Bun-first, Oxc/Vite toolchain, engineering defaults, tests in `test/` run with `bun --bun vitest run`, language), the skill map, and a single docs-sources registry (docs MCP, official skills, llms.txt per tech) that every skill points to with one standard line.
- `hd-core`: workflow and hand-off, git/PR conventions, project docs + AGENTS.md template, TypeScript 7 rules, testing (what must be tested, no coverage gate, Playwright + axe), OWASP-based security (open redirects, outbound URLs, CSRF, audit events, `trustedDependencies`, `minimumReleaseAge`).
- `hd-frontend`: Vite + React 19 with the Rust React Compiler, React Router route object with middleware guards, TanStack Query + axios with schema-parsed responses and query defaults, Zustand/URL state, shadcn preset b0 + Tailwind v4, minimal dense UI, scroll fades on `ScrollArea`, system dark mode, WCAG 2.2 AA.
- `hd-backend`: Hono + Bun layering (route → service → repository, mappers), shared errors (incl. Hono `HTTPException` and 404 mapping) and cursor pagination, OpenAPI via `hono-openapi` + Scalar UI at `/docs`, health/ready and graceful shutdown, PostgreSQL 18 + Drizzle (Bun.sql, uuidv7, expand/contract migrations, idempotency keys, transaction test boundaries, faker seeds), S3-compatible uploads with a verify-on-complete step, Redis cache.
- `hd-validate`: Zod everywhere, shared schemas, JSON-safe money, mandatory env validation, forms.
- `hd-auth`: Better Auth conventions — Hono mounting, uuid IDs, server-owned role field (`input: false`), CSRF/origin checks for our routes, rate limit, session revocation, permissions in services.
- `hd-ai`: AI SDK + OpenRouter — provider module, structured output, safety, token/step limits, abort on disconnect, per-user quotas, tool authorization, mock-model tests.
- `hd-backend`: uploads go to a staging key and are copied to a server-only final key before inspection; idempotency keys handle concurrent duplicates; `PAYLOAD_TOO_LARGE` / `UNSUPPORTED_MEDIA_TYPE` codes; trusted-`Origin` check in the middleware order.
- `hd-infra`: Turborepo + Bun monorepo (TUI, cache limits, env-aware inputs), internal packages built with tsdown, shared configs in `packages/config`, Docker Compose with generated secrets (`assets/gen-env.ts`: Bun-dotenv-safe quoting, atomic mode-600 writes), GitHub Actions baseline.

[Unreleased]: https://github.com/huanngdev/huanngdev-skills/compare/huanngdev--v1.1.0...HEAD
[1.1.0]: https://github.com/huanngdev/huanngdev-skills/compare/huanngdev--v1.0.0...huanngdev--v1.1.0
[1.0.0]: https://github.com/huanngdev/huanngdev-skills/releases/tag/huanngdev--v1.0.0
