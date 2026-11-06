---
name: hd-backend
description: huanngdev's backend rules for Hono on Bun — layered routes/services/repositories, shared error and response shapes, cursor pagination, PostgreSQL with Drizzle (Bun.sql, uuidv7 ids, migrations, transactions, faker seeds), MinIO storage and Redis cache via Bun built-ins. Use when building or changing API routes, services, database schema, queries, migrations, seeds, file storage or caching.
license: MIT
metadata:
  author: huanngdev
---

# Backend

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`. Validation: `hd-validate`. Auth: `hd-auth`. AI: `hd-ai`.

Docs: hd-index docs sources (Hono, Drizzle, Bun).

## Always
- Hono on Bun. Prefer Bun built-ins (`Bun.sql`, `Bun.S3Client`, `Bun.redis`, `Bun.password`) over extra packages.
- Flow: `route → service → repository`. Business rules only in services; DB access only in repositories.
- Contracts (schemas, DTOs, error codes, page shape) live in `packages/shared`; types are `z.infer`, never hand-written twice.
- Every error response uses the shared error shape; every list uses the shared cursor page.
- Not used unless asked: background jobs/queues, webhooks, API versioning.

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/api.md` | Routes, services, middleware, errors, responses, pagination, CORS, logging, realtime |
| `references/data.md` | Schema, queries, migrations, transactions, idempotency, seeds, DB tests |
| `references/storage.md` | File uploads (MinIO/S3) or caching (Redis) |
