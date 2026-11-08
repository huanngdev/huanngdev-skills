# Workflow

## Before coding
1. Read `AGENTS.md` (and docs it points to for this task). Stay inside the current milestone/plan; inside an agreed plan, continue without re-asking.
2. Check real script names in `package.json`; never guess commands.
3. Search for existing code to reuse or extend before writing new code.
4. Unclear requirement that affects data, security or user-visible behavior → state the assumption or ask.

## Implementing
- Vertical slice, smallest coherent change, one concern per PR.
- Order for a feature: shared schema/contract → migration → service (auth + rules) → route → frontend flow with all UI states → tests.
- Update docs/ADR in the same change when behavior or design changes.
- Keep unrelated user changes intact; remove only code your change made obsolete.

## Ask first
Not during a new-project init: what `hd-infra` init.md lists is pre-approved.
Deploys, remote/production migrations, setting real secrets, creating/deleting cloud resources, adding a dependency or a major upgrade, changing agreed architecture, deleting data or files you didn't create, force-push/history rewrite, paid API calls outside approved tests.

## Never
Commit secrets/`.env`/build output. Weaken types, lint rules, Zod schemas, auth checks or tests to get green.

## Hand-off
- Run `bun run check` (format, lint, types, tests, build) and `git diff --check`. If something can't run (missing service/secret), say so and still run the rest.
- Report: what changed, what was verified (commands + result), what wasn't, follow-ups. No "should work".
