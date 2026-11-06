---
name: hd-validate
description: huanngdev's validation rules — Zod (latest major) for every boundary from frontend forms to backend input, shared schemas as the single source of types, and mandatory Zod validation of every app's .env before it starts. Use when writing or changing schemas, DTOs, forms, request/response validation, env files or env loading, or anything that parses untrusted data.
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
