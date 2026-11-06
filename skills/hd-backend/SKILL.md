---
name: hd-backend
description: Hono + Bun backend rules: route/service/repository layers, shared errors and cursor pagination, OpenAPI spec + Scalar UI, PostgreSQL + Drizzle, MinIO storage, Redis cache. Use when changing API routes, services, DB schema, migrations, seeds, storage or cache.
license: MIT
metadata:
  author: huanngdev
---

# Backend

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`. Validation: `hd-validate`. Auth: `hd-auth`. AI: `hd-ai`.

Docs: hd-index docs sources (Hono, hono-openapi, Scalar, Drizzle, Bun).

## Always
- Hono on Bun. Prefer Bun built-ins (`Bun.sql`, `Bun.S3Client`, `Bun.redis`, `Bun.password`) over extra packages.
- Flow: `route → service → repository`. Business rules only in services; DB access only in repositories.
- Contracts (schemas, DTOs, error codes, page shape) live in `packages/shared`; types are `z.infer`, never hand-written twice.
- Every error response uses the shared error shape; every list uses the shared cursor page.
- Every route is documented in the OpenAPI spec (`hono-openapi`) and browsable/testable in Scalar at `/docs`.
- Not used unless asked: background jobs/queues, webhooks, API versioning.

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/api.md` | Routes, services, middleware, errors, responses, pagination, OpenAPI/Scalar docs, CORS, logging, realtime |
| `references/data.md` | Schema, queries, migrations, transactions, idempotency, seeds, DB tests |
| `references/storage.md` | File uploads (MinIO/S3) or caching (Redis) |
