---
name: hd-ai
description: huanngdev's defaults for LLM features with the Vercel AI SDK and OpenRouter — one provider module, model IDs from env, server-only keys, structured output with Zod, safety rules for model output, and testing without real API calls. Use when adding or changing code that calls an LLM, streams AI responses to the UI, or imports ai, @ai-sdk/*, or @openrouter/ai-sdk-provider.
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

## Tests
No real API calls in tests or CI. Use the AI SDK's mock models from `ai/test` (check the installed version's names) and assert on our parsing/handling.
