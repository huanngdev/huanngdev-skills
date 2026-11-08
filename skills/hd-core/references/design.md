# Feature design (before building)

## When
- New feature, or a change to the data model, an API contract, auth/permissions, money, an external integration, or more than one app/package.
- Skip for bug fixes, copy/style tweaks, refactors inside one module, the fixed new-project init (`hd-infra` init.md — it asks nothing; unknown numbers stay `unknown`), and work an accepted design or plan already covers. Discuss again only new decisions or material deviations.

## 1. Read what the project already decided
`docs/architecture.md`, `GLOSSARY.md` and the related ADRs in `docs/decisions/`. Reuse the established patterns; a new pattern needs a stated reason.

## 2. Write the design: `docs/design/<feature>.md`
- Problem, goals, non-goals.
- Requirements: functional, plus numbers (users, rows, requests/s, payload sizes, latency) and consistency needs. Unknown number → ask; never invent one.
- Data model: tables, invariants, ownership, indexes, retention.
- Contract: shared schemas, endpoints, error codes, pagination.
- Flows incl. failure modes: retries, idempotency, partial failure, concurrent writes, timeouts.
- Security: who may do what, untrusted input, abuse/limits.
- Operability: logs/metrics, migration and rollout (expand → migrate → contract), backfills.
- Test plan: the rules and edge cases that must be proven.

## 3. Options and trade-offs
- At least two realistic options, one of them the simplest that could work.
- Compare in a table: complexity, cost, performance, consistency, failure behavior, operability, reversibility, fit with existing patterns.
- Recommend one and say what would make you pick another.

## 4. Discuss with the user before coding
- Present: summary, recommendation, the trade-off table, open questions.
- Resolve open decisions one question at a time (local override of `grilling`, which batches; use it only while decisions are unresolved); pin down terms (`domain-modeling`).
- Don't implement until the user agrees. Their decision wins; record it even when it differs from the recommendation.

## 5. Remember it for the next feature (same PR as the design)
- Decision → ADR in `docs/decisions/NNNN-title.md`. Vendor skills that default to `docs/adr/` follow this path instead.
- Reusable patterns (how this project does auth checks, jobs, uploads, caching, …) → `docs/architecture.md`, one short section per pattern, linking its ADR.
- New domain terms → `GLOSSARY.md`.
- Design doc status → `Accepted`. The first accepted design creates `docs/architecture.md` / `GLOSSARY.md` if missing; `AGENTS.md` "Read first" lists them.

## 6. While implementing
Follow `workflow.md` order. Implementation diverges from the design → update the design doc, ADR and `docs/architecture.md` in the same PR.

## Vendor skills
`grilling`, `domain-modeling`, `codebase-design` (module boundaries, deep interfaces). Contracts follow `hd-backend` / `hd-validate`. They are installed per project (hd-index docs sources: System design). On conflict this file and the hd-* layout win.
