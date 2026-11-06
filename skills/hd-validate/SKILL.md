---
name: hd-validate
description: "Zod everywhere: shared schemas from forms to API, parsing untrusted data, mandatory .env validation at startup. Use when writing schemas, DTOs, forms, request validation, env loading or parsing external data."
license: MIT
metadata:
  author: huanngdev
---

# Validation (Zod)

Project rules (AGENTS.md) win on conflict. Global rules: `hd-index`.

## Always
- Zod, latest major (`import { z } from "zod"`). No other validation library, no hand-written type guards for external data.
- Validate every boundary: HTTP body/query/params, forms, env, URL/search params, storage/JSON columns, files, third-party and LLM output.
- One schema per concept in `packages/shared`, used by both frontend and backend. Types come from `z.infer` / `z.input`; never redeclare them.
- Every app validates its `.env` with Zod before doing anything else; invalid env = exit with the list of bad keys.
- Zod 4 differs from Zod 3: check unfamiliar APIs in the docs first.

Docs: hd-index docs sources (Zod).

## Topics — read only what the task touches
| File | Read when |
|---|---|
| `references/schemas.md` | Writing schemas/DTOs, shared contracts, parsing data, error formatting |
| `references/env.md` | Creating or changing any app's env loading, `.env.example`, new env vars |
| `references/forms.md` | Frontend forms and client-side validation |
