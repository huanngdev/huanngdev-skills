# Better Auth setup

## Layout
```
packages/auth/src/
  server.ts   # export const auth = betterAuth({...})  — server-only entry
  client.ts   # export const authClient = createAuthClient({...}) from "better-auth/react"
packages/db/src/schema/auth.ts   # generated Better Auth tables (Drizzle)
```
- One `auth` instance for the whole repo; apps import it, never create their own.
- Adapter: `drizzleAdapter(db, { provider: "pg" })` with the shared `db` from `packages/db`.
- IDs: `advanced.database.generateId: "uuid"` so auth tables use Postgres `uuid` columns that our tables can reference (`hd-backend` data.md).
- Schema: `bunx auth@latest generate` → output into `packages/db/src/schema/auth.ts`, then the normal `drizzle-kit generate` → review → `migrate` flow. Don't use Better Auth's own migrate. Don't hand-edit the generated file; change the config and regenerate.
- Env (validated, see `hd-validate`): `BETTER_AUTH_SECRET=<generate>`, `BETTER_AUTH_URL`, allowed origins → `trustedOrigins` (same list as `CORS_ORIGINS`).

## Hono
```ts
app.all("/api/auth/*", (c) => auth.handler(c.req.raw)); // CORS comes from the app-wide cors() (hd-backend api.md)
```
- Path must match Better Auth `basePath` (default `/api/auth`).
- Session middleware for the rest of the API: `auth.api.getSession({ headers: c.req.raw.headers })` → put `user`/`session` (or `null`) in Hono context variables (typed). Routes needing a user throw `AppError("UNAUTHENTICATED", 401, …)` via a `requireUser` middleware.
- The service `ctx.user` comes from that middleware; services never read cookies.

## Security settings
- Better Auth's CSRF/origin checks only run for requests through `auth.handler`. Our own cookie-authenticated state-changing routes get a middleware that rejects a missing or untrusted `Origin` (`(await auth.$context).isTrustedOrigin(origin)`).
- Calls to `auth.api.*` from our routes skip the `trustedOrigins` check on `callbackURL` / `redirectTo`: validate those as same-origin paths (`hd-core` security.md).
- Keep Better Auth's built-in rate limit on; behind a proxy configure the client-IP source it documents, otherwise `X-Forwarded-For` is spoofable. More than one instance → rate-limit storage in Redis (secondary storage).
- Secure cookies in production (HTTPS `BETTER_AUTH_URL`); never `disableCSRFCheck` / `disableOriginCheck`.
- Password change revokes other sessions (`revokeOtherSessions: true`); role or ban changes revoke that user's sessions. With `session.cookieCache` on, revocation lags by its `maxAge` — keep it short or off.
- Email verification and password reset only through Better Auth's flows; their emails go through the project's mailer.

## Passwords
Let Better Auth hash passwords. If the project overrides hashing or hashes anything else (API keys, PINs), use `Bun.password.hash` (argon2id) / `Bun.password.verify` — check the override option names in the docs MCP first.

## Frontend
- `authClient` from `packages/auth/client` for sign-in/up/out and `useSession()`. It uses its own fetch; that is the allowed exception to the axios-only rule (`hd-frontend` state.md).
- On sign-out or user change: `queryClient.clear()` before navigating.
- UI hides what the user can't do, but the API still enforces it.

## MCP plugin (only if the app exposes an MCP server)
Better Auth's `mcp()` plugin (`@better-auth/mcp`) turns the app into the OAuth authorization server for MCP clients; it requires the `jwt` plugin and replaces `oauthProvider()`. Use it only when the project serves an MCP endpoint, and read its page (`/docs/plugins/mcp`) via the Better Auth docs before wiring it.
