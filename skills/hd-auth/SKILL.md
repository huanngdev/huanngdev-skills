---
name: hd-auth
description: "Better Auth conventions: shared auth package, cookie sessions, Hono middleware, admin/member permissions checked in services. Use when changing sign-in, sessions, users, roles, permissions or protected routes."
license: MIT
metadata:
  author: huanngdev
---

# Auth (Better Auth)

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`. API layering: `hd-backend`.

## Always
- Better Auth is the only auth library. Never hand-roll sessions, tokens or password storage.
- Cookie sessions (Better Auth default). No JWTs in `localStorage`.
- Authentication happens in middleware; **authorization happens in services** (`assertCan`), never only in the UI or route.
- Better Auth APIs change between minors: check them in the docs first.

Docs: hd-index docs sources (Better Auth).

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/setup.md` | Creating/changing the auth package, Hono mounting, session middleware, schema/IDs, env, CSRF/origin, rate limit, session revocation, passwords, MCP plugin |
| `references/permissions.md` | Roles, permissions, protecting a use case, ownership checks |
