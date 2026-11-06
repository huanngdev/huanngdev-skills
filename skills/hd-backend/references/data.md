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
- Time: `timestamptz`, UTC. No soft delete unless the project asks.
- Money: integer minor units — `bigint({ mode: "bigint" })` + a `currency` (ISO 4217) column. No floats/`numeric` math in JS.
- Unknown values are `NULL`, never a made-up `0` or `""`.
- Index every foreign key and every column used in filters/sorts (incl. `(created_at, id)` for pagination).

## Migrations
`drizzle-kit generate` → review the SQL → `drizzle-kit migrate`. Never `drizzle-kit push`. Never edit an applied migration; add a new one. Scripts in `packages/db`: `db:generate`, `db:migrate`, `db:seed`.

## Writes
- A use case that writes more than one row/table runs in one `db.transaction(async (tx) => …)` opened by the service; repositories take the `tx`.
- Writes are idempotent: enforce uniqueness with constraints and use `onConflictDoNothing()` / `onConflictDoUpdate()`; check state in the same statement (`… where status = 'pending'`) instead of read-then-write.
- Select only needed columns; avoid N+1 (use joins or relational queries).

## Seeds
- `@faker-js/faker` in `packages/db/src/seed.ts`, run with `bun run db:seed`.
- Deterministic (`faker.seed(<number>)`), idempotent (fixed IDs or `onConflictDoNothing`), and refuses to run when `NODE_ENV=production`.

## Tests
Integration tests hit the real Postgres from `compose.yaml` (separate `<db>_test` database), never mocks. Each test runs inside a transaction that is rolled back. Run with `bun --bun vitest run` so `Bun.sql` exists.
