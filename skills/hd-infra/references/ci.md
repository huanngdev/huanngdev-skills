# CI (GitHub Actions)

GitHub Actions only. No other CI services.

## ci.yml baseline
```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
permissions:
  contents: read
jobs:
  ci:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7
      - uses: oven-sh/setup-bun@v2
        with:
          bun-version-file: package.json
      - uses: actions/cache@v6
        with:
          path: .turbo
          key: ${{ runner.os }}-turbo-${{ hashFiles('bun.lock') }}-${{ github.sha }}
          restore-keys: |
            ${{ runner.os }}-turbo-${{ hashFiles('bun.lock') }}-
            ${{ runner.os }}-turbo-
      - run: bun install --frozen-lockfile
      - run: bun run format:check
      - run: bun run lint
      - run: bun run check-types
      - run: bun run test
      - run: bun run build
      # with packages/db: - run: bun run --filter '@<scope>/db' db:check
```
Check action majors against their releases when creating a new workflow; keep them consistent across the repo.

## Rules
- CI runs the same root scripts as local (`bun run …`); no CI-only logic in YAML when a script can hold it.
- `permissions` least-privilege at workflow level; raise per job only when needed (e.g. `contents: write` for releases).
- Secrets via repository/environment secrets, passed as `env:` on the step that needs them. Never `echo` them. Fork PRs get no secrets — jobs must still pass or skip cleanly.
- Services needed by integration tests run as job `services:` with credentials from secrets or generated in the job, never literals.
- Job/step names are stable: they are the required status checks on protected `main`. Renaming one means updating branch protection.
- Lint workflows with `actionlint` before pushing.
- `.github/dependabot.yml`: weekly updates for `github-actions` and `bun`.
- Lint with `oxlint --deny-warnings` (via `bun run lint`); format check with `bun run format:check` (oxfmt).
- Security follows best practice: CodeQL workflow and secret scanning (TruffleHog) on PRs.
