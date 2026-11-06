---
name: hd-core
description: Cross-cutting rules: workflow and hand-off, git and PRs, project docs and AGENTS.md, TypeScript, testing, security. Use when implementing, fixing, reviewing, committing, or writing tests or docs.
license: MIT
metadata:
  author: huanngdev
---

# Core

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`.

Docs: hd-index docs sources (Vite / Vitest, Hono).

## Always
- Read the project's `AGENTS.md` first; make the smallest coherent change; run `bun run check` before handing off.
- Report exactly what was verified and what wasn't.

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/workflow.md` | Starting any task, ask-first boundaries, hand-off and reporting |
| `references/git.md` | Branches, commits, PRs, merging |
| `references/docs.md` | AGENTS.md, ADRs, milestones/progress, writing project docs |
| `references/typescript.md` | Writing or reviewing any TypeScript |
| `references/testing.md` | Writing or fixing tests, deciding what to test |
| `references/security.md` | Secrets, input handling, headers, cookies, dependencies, logging |
