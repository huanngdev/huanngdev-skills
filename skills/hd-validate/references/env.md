# Env validation (mandatory for every app with a .env)

## Rule
The app's first import is its env module. It parses the environment with Zod and exits on failure **before** starting servers, connecting to databases or rendering. Code reads env only from the exported object — never `process.env` / `Bun.env` / `import.meta.env` directly.

## Server / Bun apps — `src/env.ts`
```ts
import { z } from "zod";

const EnvSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().default(3000),
  DATABASE_URL: z.url(),
  BETTER_AUTH_SECRET: z.string().min(32),
  CORS_ORIGINS: z.string().transform((s) => s.split(",").map((o) => o.trim())),
});

const parsed = EnvSchema.safeParse(Bun.env);
if (!parsed.success) {
  console.error(`Invalid environment:\n${z.prettifyError(parsed.error)}`);
  process.exit(1);
}
export const env = parsed.data;
```
`src/index.ts` starts with `import { env } from "./env";`.

## Vite apps — `src/env.ts`
- Only `VITE_*` keys reach the browser; never put secrets there.
- Same pattern with `import.meta.env` as input and a schema of `VITE_*` keys; on failure `throw` (the app must not render). Import it at the top of `main.tsx`.

## Keeping things in sync
- Every key in the schema appears in the app's `.env.example` (secrets as `<generate>`, see `hd-infra` docker.md), and vice versa.
- New env var = add to schema + `.env.example` + (if a turbo task reads it) `turbo.json` `env` in the same change.
- Tests set env through the same schema (e.g. a `.env.test`), never by bypassing it.
