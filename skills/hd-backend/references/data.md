# Database (PostgreSQL + Drizzle)

## Stack
- PostgreSQL 18 (compose image `postgres:18-alpine`), Drizzle ORM + drizzle-kit, driver `Bun.sql` via `drizzle-orm/bun-sql`.
- `packages/db`: `src/schema/*.ts`, `src/client.ts`, `src/repositories/*.ts`, `src/seed.ts`, `drizzle/` (migrations), `drizzle.config.ts`. Apps never define tables or raw queries.
- `drizzle({ client, schema, casing: "snake_case" })`: TS camelCase ↔ SQL snake_case. Tables plural snake_case.

## Standard columns (every table)
```ts
export const id = () => uuid().primaryKey().default(sql`uuidv7()`); // a function: one column instance per table
export const timestamps = {
  createdAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp({ withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
};
```
Use in tables as `{ id: id(), …, ...timestamps }`.
- IDs: Postgres-generated `uuidv7()` (time-ordered), no prefixes. Never use array indexes or sequential ints as public IDs.
- Exception: Better Auth tables use its own generated schema with `generateId: "uuid"` (`hd-auth` setup.md); foreign keys to its user table (`user` by default, or the configured `modelName`) are `uuid()`.
- Time: `timestamptz`, UTC. No soft delete unless the project asks.
- Money: integer minor units — `bigint({ mode: "number" })` + a `currency` (ISO 4217) column, so DTOs carry a JSON-safe `z.int()` (`hd-validate` schemas.md). Only if amounts can exceed 2^53 minor units: `mode: "bigint"` in the DB and a digit string in DTOs, converted in the mapper. No floats/`numeric` math in JS.
- Unknown values are `NULL`, never a made-up `0` or `""`.
- Index every foreign key and every column used in filters/sorts (incl. `(created_at, id)` for pagination).

## Migrations
`drizzle-kit generate` → review the SQL → `drizzle-kit migrate`. Never `drizzle-kit push`. Never edit an applied migration; add a new one. Scripts in `packages/db`: `db:generate`, `db:migrate`, `db:check` (`drizzle-kit check`, run in CI), `db:seed`.
- Breaking changes go expand → migrate data → contract across separate releases (add nullable column / new table first, backfill, switch code, drop later). Never rename or drop a column the running code still reads.
- Migrations that lock big tables (new index, `NOT NULL` backfill) get a note in the PR; backfills run in batches. `drizzle-kit migrate` runs all pending migrations in one transaction, so `CREATE INDEX CONCURRENTLY` can't go in a migration: on a big table, run it as a separate reviewed SQL step (ask first), and keep the migration as `CREATE INDEX IF NOT EXISTS` so schema and journal stay in sync.

## Writes
- A use case that writes more than one row/table runs in one `ctx.db.transaction(async (tx) => …)` opened by the service; repositories take the `tx`.
- Writes are idempotent: enforce uniqueness with constraints and use `onConflictDoNothing()` / `onConflictDoUpdate()`; check state in the same statement (`… where status = 'pending'`) instead of read-then-write.
- Retryable creates the client may repeat (payments, orders, submissions) take an `Idempotency-Key` header, scoped by `(user_id, operation, key)` with a unique constraint:
  1. In the use case's transaction, `insert … on conflict do nothing returning` a row with `request_hash` and `status = 'started'`.
  2. Inserted → do the write, store the response, `status = 'done'`, commit.
  3. Conflict → read the row: different hash → `CONFLICT`; `done` → replay the stored response; `started` (the other request is still running) → `CONFLICT` with a retry hint, never a second write.
  - Test it with two identical requests sent concurrently: one effect, the other replays or conflicts.
- Side effects outside the DB (email, storage deletes, third-party calls) run after commit, never inside the transaction.
- Select only needed columns; avoid N+1 (use joins or relational queries).

## Seeds
- `@faker-js/faker` in `packages/db/src/seed.ts`, run with `bun run db:seed`.
- Deterministic (`faker.seed(<number>)`), idempotent (fixed IDs or `onConflictDoNothing`), and refuses to run when `NODE_ENV=production`.

## Tests
- Integration tests hit the real Postgres from `compose.yaml` (separate `<db>_test` database, migrated before the run), never mocks. Run with `bun --bun vitest run` so `Bun.sql` exists.
- Services open transactions on `ctx.db` (never a module-level `db`), so service/repository tests can pass a `tx` and roll it back; the service's own transaction becomes a savepoint.
- Tests going through HTTP or depending on a commit truncate the touched tables between tests instead; test files using the DB don't run in parallel against the same database.
