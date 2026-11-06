# AGENTS.md — <Project>

<One sentence: what the project is and who it is for.>

## 1. Skills
Shared style: hd-* skills (start with `hd-index`). This file wins on conflict.

## 2. Read first
1. `docs/MILESTONES.md` — current scope (if the project keeps it)
2. <key spec>

## 3. Stack
<apps and packages with their framework, DB, auth, UI kit — major versions>

## 4. Commands
```sh
bun install
bun run env:gen
docker compose up -d
bun run dev
bun run check
```

## 5. Code map
```
apps/web        # ...
apps/api        # ...
packages/shared # contracts, Zod schemas
packages/db     # Drizzle schema, repositories, migrations
```

## 6. Invariants (never violate)
1. <testable statement>
If a task seems to require breaking one → stop, record it in `docs/decisions/`, ask the user.

## 7. Repo-specific conventions
- <roles beyond admin/member, UI language, special folders, …>

## 8. Ask first (beyond hd-core defaults)
- <…>

## 9. Definition of Done
- [ ] `bun run check` passes
- [ ] <project-specific criteria>
- [ ] Docs / ADR / milestones updated
