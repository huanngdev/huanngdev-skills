# Testing

## Setup
- Vitest, run as `bun --bun vitest run` (Bun APIs available). Config extends `@<scope>/config/vitest/base`.
- Tests live in `<package>/test/`, mirroring `src/` with the same file names (`src/money.ts` → `test/money.test.ts`). Never next to source files. Shared fixtures/helpers in `test/support/`; `src/` never imports from `test/`.
- No coverage threshold gate; coverage is a guide, not a target.

## What must be tested
- Business rules in services (happy path + each rule that can reject).
- Permissions: allowed, forbidden, unauthenticated, another user's resource; role fields can't be set through sign-up/update input.
- Money, time zones/day boundaries, idempotency (same request twice = one effect), pagination edges.
- Schemas with tricky rules; bug fixes get a regression test first.

## How
- Backend integration tests hit real Postgres from compose (`hd-backend` data.md); no DB mocks.
- Frontend: Testing Library by role/label, MSW for API; Playwright for main flows (`hd-frontend`), with an axe accessibility check (`@axe-core/playwright`) on each main page.
- Playwright runs against the built app with services from compose; in CI install browsers with `bunx playwright install --with-deps chromium`.
- No real third-party/LLM calls; use mocks at the provider boundary.
- Deterministic: inject time/randomness, seed faker, no sleeps — wait for conditions.
- One behavior per test, named as the behavior (`"rejects archive when project has open issues"`).
