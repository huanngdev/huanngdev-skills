---
name: hd-core
description: "Cross-cutting engineering rules for TypeScript repos: workflow and hand-off, git and PRs, AGENTS.md and ADRs, TypeScript style, testing, security. Use when implementing, fixing, reviewing or committing code, writing tests, or editing AGENTS.md, ADRs or plans."
license: MIT
metadata:
  author: huanngdev
---

# Core

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`.

Docs: hd-index docs sources (TypeScript, Vite / Vitest, Testing Library, MSW, Playwright).

## Always
- Read the project's `AGENTS.md` first; hand-off check is `bun run check` + `git diff --check` (details in `workflow.md`).

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/workflow.md` | Starting any task, ask-first boundaries, hand-off and reporting |
| `references/git.md` | Branches, commits, PRs, merging |
| `references/docs.md` | AGENTS.md, ADRs, milestones/progress, writing project docs |
| `references/typescript.md` | Writing or reviewing any TypeScript |
| `references/testing.md` | Writing or fixing tests, deciding what to test |
| `references/security.md` | Secrets, input handling, headers, cookies, dependencies, logging |
