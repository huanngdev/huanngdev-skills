# HTTP API (Hono + Bun)

## Shape of an API app
```
apps/api/src/
  env.ts               # Zod-validated env, imported first (see hd-validate)
  app.ts               # Hono app: middleware + routes chained, exports `type AppType`
  index.ts             # export default { port: env.PORT, fetch: app.fetch }
  routes/<feature>.ts  # HTTP only
  services/<feature>.ts
packages/db            # schema + repositories (see data.md)
packages/shared        # schemas, DTOs, error codes, page schema
```
- REST JSON. Chain route definitions (`new Hono().get(…).post(…)`) so types flow; export `type AppType = typeof app`.
- Frontend calls through `hc<AppType>()` from `hono/client`, importing the type only (`import type { AppType }`). No hand-written fetch wrappers per endpoint.

## Layers (reuse, nothing goes missing on change)
- **Route**: validate input (`validate()` below) → call **one** service function → return DTO. No business logic, no Drizzle.
- **Service**: one exported function per use case, `(ctx, input) => Promise<Output>` with `ctx = { db, user, log }`. Authorization, transactions and business rules live here. Every caller (routes, scripts, tests) reuses it — never reimplement a use case elsewhere.
- **Repository** (`packages/db`): small query functions per table/aggregate that accept an executor (`db` or `tx`).
- **Mapper**: one `toXxxDto(row)` per entity in the repository layer; every response goes through it.
- Changing a field = change the schema in `packages/shared` + the mapper; the type checker then lists every place to update. If a change compiles while a caller is stale, the types are too loose — tighten them.

## Errors (shared with the frontend)
`packages/shared/src/errors.ts`:
```ts
export const ErrorCode = z.enum(["VALIDATION_FAILED", "UNAUTHENTICATED", "FORBIDDEN", "NOT_FOUND", "CONFLICT", "RATE_LIMITED", "INTERNAL"]);
export const ErrorResponseSchema = z.object({
  error: z.object({ code: ErrorCode, message: z.string(), details: z.unknown().optional() }),
});
```
- API: one `AppError(code, status, message, details?)` class; services throw it; `app.onError` maps `AppError` → its status + shape, anything else → 500 `INTERNAL` (log the real error with the request id, never return it).
- Status per code: 400, 401, 403, 404, 409, 429, 500 in the order above.
- Validation helper (all input goes through it):
```ts
import type { ValidationTargets } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";

export const validate = <T extends z.ZodType, Target extends keyof ValidationTargets>(target: Target, schema: T) =>
  zValidator(target, schema, (result, c) => {
    if (!result.success) {
      return c.json(
        { error: { code: "VALIDATION_FAILED", message: "Invalid input", details: z.flattenError(result.error).fieldErrors } },
        400,
      );
    }
  });
```
- Frontend parses non-2xx bodies with `ErrorResponseSchema` and switches on `code`; field errors map onto form fields.

## Responses & pagination
- Success returns the DTO directly (`c.json(dto, 201)`); no `{ data }` envelope. No body → 204.
- Lists return `{ items: T[], nextCursor: string | null }`, built from `pageSchema(itemSchema)` in `packages/shared`.
- Query `?cursor=&limit=` (`limit` default 20, max 100). Cursor = opaque base64url of the last row's `(created_at, id)`; order by `created_at desc, id desc`; fetch `limit + 1` to know if there is a next page. Index those columns.
- No API versioning.

## Middleware order
request id → logger → CORS → session (`hd-auth`) → routes → `onError`.
- Logging: pino, JSON, child logger per request with `requestId`. Never log secrets, tokens, cookies, passwords or full bodies with PII.
- CORS: allowed origins from env (`CORS_ORIGINS`, comma list), `credentials: true` when using cookies. Never `*` with credentials.
- Rate limit auth and expensive endpoints; store counters in Redis when running more than one instance.

## Realtime (only when needed)
Use Bun's built-in WebSocket through Hono's Bun adapter (`hono/bun`). No Socket.IO or extra servers.
