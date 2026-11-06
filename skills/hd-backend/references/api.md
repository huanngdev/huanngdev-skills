# HTTP API (Hono + Bun)

## Shape of an API app
```
apps/api/src/
  env.ts               # Zod-validated env, imported first (see hd-validate)
  app.ts               # Hono app: middleware + routes
  index.ts             # const server = Bun.serve({ port: env.PORT, fetch: app.fetch }) + shutdown
  routes/<feature>.ts  # HTTP only
  services/<feature>.ts
packages/db            # schema + repositories (see data.md)
packages/shared        # schemas, DTOs, error codes, page schema
```
- REST JSON over HTTP. The frontend calls it with its axios instance (`hd-frontend` state.md); request/response types come from the shared schemas in `packages/shared`, so both sides stay in sync.

## Layers (reuse, nothing goes missing on change)
- **Route**: validate input (`validate()` below) → call **one** service function → return DTO. No business logic, no Drizzle.
- **Service**: one exported function per use case, `(ctx, input) => Promise<Output>` with `ctx = { db, user, log }`. Authorization, transactions and business rules live here. Every caller (routes, scripts, tests) reuses it — never reimplement a use case elsewhere.
- **Repository** (`packages/db`): small query functions per table/aggregate that accept an executor (`db` or `tx`).
- **Mapper**: one `toXxxDto(row)` per entity in the repository layer; every response goes through it.
- Changing a field = change the schema in `packages/shared` + the mapper; the type checker then lists every place to update. If a change compiles while a caller is stale, the types are too loose — tighten them.

## Errors (shared with the frontend)
`packages/shared/src/errors.ts`:
```ts
export const ErrorCode = z.enum(["VALIDATION_FAILED", "UNAUTHENTICATED", "FORBIDDEN", "NOT_FOUND", "CONFLICT", "PAYLOAD_TOO_LARGE", "UNSUPPORTED_MEDIA_TYPE", "RATE_LIMITED", "INTERNAL"]);
export const ErrorResponseSchema = z.object({
  error: z.object({ code: ErrorCode, message: z.string(), details: z.unknown().optional() }),
});
```
- API: one `AppError(code, status, message, details?)` class; services throw it.
- Status per code: 400, 401, 403, 404, 409, 413, 415, 429, 500 in the order above. Code and status always agree.
- `app.onError`: `AppError` → its status + shape; Hono `HTTPException` (e.g. malformed JSON → 400) → shared shape with the code for its status (a 4xx without its own code → 400 `VALIDATION_FAILED`); anything else → 500 `INTERNAL` (log the real error with the request id, never return it).
- `app.notFound` returns the shared shape with `NOT_FOUND`, so unknown routes don't leak Hono's plain-text 404.
- Validation helper (all input goes through it; it also feeds the OpenAPI spec):
```ts
import type { ValidationTargets } from "hono";
import type { StandardSchemaV1 } from "@standard-schema/spec";
import { validator } from "hono-openapi";

const toFieldErrors = (issues: readonly StandardSchemaV1.Issue[]): Record<string, string[]> => {
  const out: Record<string, string[]> = {};
  for (const issue of issues) {
    const key = (issue.path ?? []).map((p) => String(typeof p === "object" ? p.key : p)).join(".") || "_root";
    (out[key] ??= []).push(issue.message);
  }
  return out;
};

export const validate = <T extends StandardSchemaV1, Target extends keyof ValidationTargets>(target: Target, schema: T) =>
  validator(target, schema, (result, c) => {
    if (!result.success) {
      return c.json(
        { error: { code: "VALIDATION_FAILED", message: "Invalid input", details: toFieldErrors(result.error) } },
        400,
      );
    }
  });
```
- Frontend parses non-2xx bodies with `ErrorResponseSchema` and switches on `code`; field errors map onto form fields.

## Responses & pagination
- Success returns the DTO directly (`c.json(dto, 201)`); no `{ data }` envelope. No body → `c.body(null, 204)` (`c.json` can't send 204).
- Lists return `{ items: T[], nextCursor: string | null }`, built from `pageSchema(itemSchema)` in `packages/shared`.
- Query `?cursor=&limit=` (`limit` default 20, max 100). Cursor = opaque base64url of the last row's `(created_at, id)`; order by `created_at desc, id desc`; fetch `limit + 1` to know if there is a next page. Index those columns.
- No API versioning.

## OpenAPI + Scalar (view and try the API)
- Spec is generated from the same Zod schemas with `hono-openapi`; UI is Scalar (`@scalar/hono-api-reference`). No hand-written spec, no Swagger UI.
- Every route: `describeRoute({ tags, summary, responses })` + `validate(...)`. Responses use `resolver(Schema)`; document the success DTO and `ErrorResponseSchema` for error statuses.
- Shared schemas get `.meta({ ref: "UserDto" })` so they appear once under `components`.
- Mount after all routes:
```ts
app.get("/openapi.json", openAPIRouteHandler(app, { documentation: { info: { title: "API", version: "1.0.0" } } }));
app.get("/docs", Scalar({ url: "/openapi.json" }));
```
- Only when `env.NODE_ENV !== "production"` unless the project decides to publish its docs.

## Middleware order
request id → logger → `secureHeaders` → CORS → `bodyLimit` (its `onError` returns 413 `PAYLOAD_TOO_LARGE`) → trusted-`Origin` check on unsafe methods outside `/api/auth/*` (`hd-auth` setup.md) → session (`hd-auth`) → routes (incl. Better Auth handler) → `onError` / `notFound`.
- Logging: pino, JSON, child logger per request with `requestId`. Never log secrets, tokens, cookies, passwords or full bodies with PII.
- CORS: one `cors()` middleware for the whole app (it also covers `/api/auth/*`), origins from env (`CORS_ORIGINS`, comma list), `credentials: true` when using cookies. Never `*` with credentials.
- Rate limit auth and expensive endpoints; store counters in Redis when running more than one instance.

## Health & shutdown
- `GET /health` (process up, no dependencies) and `GET /ready` (DB/Redis reachable, short timeout); both outside auth, never logged at info level.
- On `SIGTERM`/`SIGINT`: `await server.stop()` (stops accepting, waits for in-flight requests; force with `stop(true)` after a deadline), then close DB/Redis clients and exit.
- Long work honours the request's `c.req.raw.signal` (client gone → stop).

## Realtime (only when needed)
Use Bun's built-in WebSocket through Hono's Bun adapter (`hono/bun`). No Socket.IO or extra servers.
