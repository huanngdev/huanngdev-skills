# Security (OWASP-based defaults)

## Secrets
- Secrets only in `.env` files (generated, `hd-infra` docker.md) and CI secrets; read through validated env objects. Never in code, logs, URLs, error messages, client bundles (`VITE_*` is public).
- Never log tokens, cookies, passwords, API keys, full request bodies with PII, or full LLM prompts/responses with user data.

## Input & output
- Every boundary parsed with Zod; reject unknown/oversized input (Hono `bodyLimit`, `limit` caps).
- SQL only through Drizzle builders or parameterized `sql` templates; never string-concatenated SQL.
- Never accept storage keys, internal IDs for other users' data, roles or prices from the client; derive server-side and check ownership (`hd-auth`).
- Don't render user HTML; if unavoidable, sanitize. No `dangerouslySetInnerHTML` with user data.
- Errors to clients carry a code + safe message; details stay in logs.

## Redirects & outbound requests
- Redirect targets from input (`redirectTo`, `callbackURL`, `next`) must be a same-origin relative path: starts with `/`, not `//` or `/\`; otherwise fall back to `/`.
- Server-side fetches of user-supplied URLs (webhooks, previews, imports): `https:` only, host on an allow-list from env, no private/loopback/link-local IPs, no redirects followed blindly, short timeout and size cap.

## HTTP
- Hono `secureHeaders()` on every app; the SPA host sends a CSP without `unsafe-inline` scripts.
- CORS allow-list from env, credentials only for listed origins (`hd-backend` api.md).
- Cookies via Better Auth (HttpOnly, Secure, SameSite); no tokens in `localStorage`.
- CSRF: cookie-authenticated state-changing routes require JSON bodies and a trusted `Origin` (`hd-auth` setup.md); never state changes on `GET`.
- Rate limit auth and expensive endpoints.

## Audit
- Security-relevant events (sign-in failures, role/permission changes, password/email changes, data exports, admin actions) are logged as structured events with actor, target, time and request id — never the secret values.

## Dependencies & CI
- Add dependencies sparingly (ask first); prefer Bun/platform built-ins.
- Lockfile committed; installs with `--frozen-lockfile`. Lifecycle scripts only for packages listed in `trustedDependencies`.
- `bunfig.toml` `[install] minimumReleaseAge = "3d"` to skip freshly published (possibly hijacked) versions; exclude only with a reason.
- Dependabot weekly; CodeQL and secret scanning (TruffleHog) in CI (`hd-infra` ci.md).
