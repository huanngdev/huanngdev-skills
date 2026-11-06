# Testing

<!-- TODO: full rules. Decisions already made: -->
- Runner: Vitest (config extends `@<scope>/config/vitest/base`).
- Tests live in `<package>/test/`, mirroring `src/` with the same file names (`src/money.ts` → `test/money.test.ts`). Never next to source files.
- Shared fixtures/helpers in `test/support/`. `src/` never imports from `test/`.
