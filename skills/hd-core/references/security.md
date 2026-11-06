# Security (OWASP-based defaults)

## Secrets
- Secrets only in `.env` files (generated, `hd-infra` docker.md) and CI secrets; read through validated env objects. Never in code, logs, URLs, error messages, client bundles (`VITE_*` is public).
- Never log tokens, cookies, passwords, API keys, full request bodies with PII, or full LLM prompts/responses with user data.

## Input & output
- Every boundary parsed with Zod; reject unknown/oversized input (body size limits, `limit` caps).
- SQL only through Drizzle builders or parameterized `sql` templates; never string-concatenated SQL.
- Never accept storage keys, internal IDs for other users' data, roles or prices from the client; derive server-side and check ownership (`hd-auth`).
- Don't render user HTML; if unavoidable, sanitize. No `dangerouslySetInnerHTML` with user data.
- Errors to clients carry a code + safe message; details stay in logs.

## HTTP
- Hono `secureHeaders()` on every app; CSP tightened for the SPA host when the project serves it.
- CORS allow-list from env, credentials only for listed origins (`hd-backend` api.md).
- Cookies via Better Auth (HttpOnly, Secure, SameSite); no tokens in `localStorage`.
- Rate limit auth and expensive endpoints.

## Dependencies & CI
- Add dependencies sparingly (ask first); prefer Bun/platform built-ins.
- Dependabot weekly; CodeQL and secret scanning (TruffleHog) in CI (`hd-infra` ci.md).
- Lockfile committed; installs with `--frozen-lockfile`.
