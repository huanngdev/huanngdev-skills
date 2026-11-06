# Project docs

## Language
Project docs (`AGENTS.md`, `docs/`) in Vietnamese, keeping English technical terms. Code, comments, commits and PRs in English.

## AGENTS.md
- Short (aim < 120 lines), only what is specific to the repo: one-line purpose, stack + versions, commands, code map, invariants, repo-specific conventions, extra ask-first items, definition of done. Generic rules stay in the hd-* skills — reference them, don't copy.
- Start from `assets/AGENTS.template.md` in this skill; delete empty sections.
- `CLAUDE.md` contains only `@AGENTS.md`, so every agent reads one file.
- Invariants are numbered, testable statements ("Money is integer minor units"), not advice.
- Commands are copied from real scripts. Leave tool-generated blocks (e.g. `<!-- BEGIN:… -->`) untouched.

## Decisions & progress
- ADRs in `docs/decisions/NNNN-title.md`: context, decision, consequences. New library or architecture change ⇒ new ADR in the same PR.
- If the project keeps `docs/MILESTONES.md` / `docs/PROGRESS.md`, update them in the PR that completes the item.

## Writing
Each fact lives in one place; link instead of repeating. Prefer tables/bullets over prose. Remove docs that no longer match the code.
