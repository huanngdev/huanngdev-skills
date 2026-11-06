---
name: hd-ai
description: "AI SDK + OpenRouter conventions: one provider module, model IDs from env, server-only keys, Zod structured output, output safety, mock-model tests. Use when adding or changing code that calls an LLM or streams AI output."
license: MIT
metadata:
  author: huanngdev
---

# AI (AI SDK + OpenRouter)

Project rules (AGENTS.md) win on conflict — prompts, agents, tools, BYOK, evals and model choice are per project. Global rules: `hd-index`.

## Stack
- `ai` (latest major) + `@openrouter/ai-sdk-provider`. UI streaming with `@ai-sdk/react`.
- AI SDK APIs change between majors: read the installed version's docs first. Never write AI SDK calls from memory.

Docs: hd-index docs sources (AI SDK, OpenRouter).

## Structure
- One provider module (`src/ai/provider.ts` in the app, or `packages/ai` when ≥ 2 apps use it): `createOpenRouter({ apiKey: env.OPENROUTER_API_KEY })`.
- Model IDs come from validated env/config (e.g. `AI_MODEL_DEFAULT`), never string literals scattered in code.
- Every LLM call goes through functions in that module/package; routes and services call those, not the SDK directly.
- Keys are server-only. The browser talks to our Hono route, which streams back (AI SDK UI message stream); never call OpenRouter from the client.

## Output & safety
- Structured output always uses a Zod schema (`hd-validate`), and the result is treated as untrusted input.
- Model output is a draft: it never decides money, permissions or deletions; code or the user confirms.
- External content (web pages, files, tool results, user documents) passed to a model is untrusted — keep it clearly separated from instructions.
- Deterministic work (math, totals, scoring, dates) is code, not the model.
- Log model ID, token usage, latency and cost per call; never log full prompts/responses containing PII or secrets.
- Set timeouts and handle provider errors as `AppError` with a clear code.

## Limits & tools
- Every call sets `maxOutputTokens`; tool loops set `stopWhen` with a step-count limit (helper name differs by major — check the docs).
- Pass the request's abort signal (`abortSignal: c.req.raw.signal`) so a closed client stops generation and spend.
- Per-user quota (requests or tokens per day, counted in Redis or the DB) checked before the call → `RATE_LIMITED` when exceeded. Retries are bounded (provider default or ≤ 2).
- Tools run with the calling user's `ctx` and go through the same services, so `assertCan` / ownership checks apply. Tools that write, spend or delete need explicit user confirmation in the UI.
- Model IDs come from an allow-list in config; never accept a model ID from the client.

## Tests
No real API calls in tests or CI. Use the AI SDK's mock models from `ai/test` (check the installed version's names) and assert on our parsing/handling.
