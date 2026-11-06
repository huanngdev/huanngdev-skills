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
- Schema: `bunx auth@latest generate` → output into `packages/db/src/schema/auth.ts`, then the normal `drizzle-kit generate` → review → `migrate` flow. Don't use Better Auth's own migrate.
- Env (validated, see `hd-validate`): `BETTER_AUTH_SECRET=<generate>`, `BETTER_AUTH_URL`, allowed origins → `trustedOrigins`.

## Hono
```ts
app.use("/api/auth/*", cors({ origin: env.CORS_ORIGINS, credentials: true })); // before the handler
app.all("/api/auth/*", (c) => auth.handler(c.req.raw));
```
- Path must match Better Auth `basePath` (default `/api/auth`).
- Session middleware for the rest of the API: `auth.api.getSession({ headers: c.req.raw.headers })` → put `user`/`session` (or `null`) in Hono context variables (typed). Routes needing a user throw `AppError("UNAUTHENTICATED", 401, …)` via a `requireUser` middleware.
- The service `ctx.user` comes from that middleware; services never read cookies.

## Passwords
Let Better Auth hash passwords. If the project overrides hashing or hashes anything else (API keys, PINs), use `Bun.password.hash` (argon2id) / `Bun.password.verify` — check the override option names in the docs MCP first.

## Frontend
- `authClient` from `packages/auth/client` for sign-in/up/out and `useSession()`.
- UI hides what the user can't do, but the API still enforces it.

## MCP plugin (only if the app exposes an MCP server)
Better Auth's `mcp()` plugin (`@better-auth/mcp`) turns the app into the OAuth authorization server for MCP clients; it requires the `jwt` plugin and replaces `oauthProvider()`. Use it only when the project serves an MCP endpoint, and read its page (`/docs/plugins/mcp`) via the Better Auth docs before wiring it.
