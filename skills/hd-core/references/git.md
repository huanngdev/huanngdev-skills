# Git & PRs

- `main` is protected: changes only through PRs with green CI. Never push to `main` directly, never force-push shared branches.
- Branches: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, `chore/<topic>`, `refactor/<topic>` (kebab-case).
- Conventional Commits in English: `feat(api): add project archive`, `fix(web): keep filter on reload`. Scope = app/package name. Imperative, ≤ 72 chars subject; body explains why when not obvious.
- Small commits that each pass checks; no "wip" or "fix typo" chains in PRs (squash them).
- PR: one concern; title in Conventional Commit form; body = what/why, how it was verified, screenshots for UI, follow-ups.
- Merge by squash; delete the branch after merge.
- Never commit `.env*` (except `.env.example`), secrets, `node_modules`, `dist`, `.turbo`, coverage.
