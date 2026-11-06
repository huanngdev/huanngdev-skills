# Docs sources (single registry)

Goal: research docs fast, accurately and for the **installed** version. Order: docs MCP → official skill → `llms.txt` → docs/types inside `node_modules/<pkg>`. Always compare with the version in `package.json`.

## Registry
| Tech | Docs MCP (`.mcp.json` key) | Official skill (`bunx skills add …`) | llms.txt / local docs |
|---|---|---|---|
| Zod | `zod-docs` | — | `https://zod.dev/llms.txt` |
| Better Auth | `better-auth` | `better-auth/skills -s better-auth-best-practices better-auth-security-best-practices` | `https://better-auth.com/llms.txt` |
| Turborepo | — | `vercel/turborepo -s turborepo` | `https://turborepo.dev/llms.txt` |
| TypeScript | — | — | `https://www.typescriptlang.org/docs/handbook/intro.html` (no llms.txt) |
| Hono | — | `honojs/skills -s hono` | `https://hono.dev/llms.txt` |
| hono-openapi | — | — | `https://github.com/rhinobase/hono-openapi` (README) |
| Scalar | — | — | `https://guides.scalar.com/llms.txt` |
| AI SDK | — | `vercel/ai -s ai-sdk` | `node_modules/ai/docs/`, `https://ai-sdk.dev/llms.txt` |
| OpenRouter | — | — | `https://openrouter.ai/docs/llms.txt` |
| Drizzle | — | — | `https://orm.drizzle.team/llms.txt` |
| Bun | — | — | `https://bun.com/llms.txt` |
| Oxc (oxlint, oxfmt) | — | `oxc-project/oxc -s migrate-oxlint migrate-oxfmt` (migrations only) | `https://oxc.rs/llms.txt` |
| tsdown | — | — | `https://tsdown.dev/llms.txt` |
| Vite / Vitest | — | — | `https://vite.dev/llms.txt`, `https://vitest.dev/llms.txt` |
| React | — | — | `https://react.dev/llms.txt` |
| React Router | — | `remix-run/react-router -s react-router` | `https://raw.githubusercontent.com/remix-run/react-router/refs/tags/react-router@<version>/docs/<path>.md` |
| axios | — | — | `https://axios-http.com/docs/intro` (no llms.txt) |
| Zustand | — | — | `https://zustand.docs.pmnd.rs/llms.txt` |
| Motion | — | — | `https://motion.dev/llms.txt` |
| TanStack | `tanstack` | — | `https://tanstack.com/llms.txt`, `https://tanstack.com/query/latest/llms.txt` |
| shadcn/ui | `shadcn` | `shadcn-ui/ui -s shadcn` | `https://ui.shadcn.com/llms.txt` (pages also as `<url>.md`) |
| Tailwind CSS | — | — | `https://tailwindcss.com/docs` (no llms.txt) |
| react-hook-form | — | — | `https://react-hook-form.com/llms.txt` |
| Testing Library | — | — | `https://testing-library.com/docs` (no llms.txt) |
| MSW | — | — | `https://mswjs.io/docs` (no llms.txt) |
| Playwright | `playwright` | — | `https://playwright.dev/docs/intro` (no llms.txt) |

## MCP entries (merge into the project's `.mcp.json`; add only what the project uses)
```json
{
  "mcpServers": {
    "zod-docs": { "type": "http", "url": "https://mcp.inkeep.com/zod/mcp" },
    "better-auth": { "type": "http", "url": "https://mcp.better-auth.com/mcp" },
    "tanstack": { "command": "bunx", "args": ["@tanstack/cli", "mcp"] },
    "shadcn": { "command": "bunx", "args": ["shadcn@latest", "mcp"] },
    "playwright": { "command": "bunx", "args": ["@playwright/mcp@latest"] }
  }
}
```
Other agents: same servers in their own config (e.g. Better Auth: `bunx auth@latest mcp --codex|--cursor|--open-code`).

## Installing
- Adding an MCP server or vendor skill changes project config and runs third-party code: ask the user first.
- Install into the **project** (not globally) only what its stack uses; commit `.mcp.json` and the project's skills lockfile.
- Official skills only. Update with `bunx skills update`; never hand-edit installed vendor skill files.

## Tech not in the registry
1. Search, official sources first: the vendor's docs site for an MCP server or `llms.txt`, `bunx skills find <tech>`, the vendor's GitHub org for a skills repo.
2. Use the best one found; say if a source is unofficial.
3. Tell the user, and propose a row for this registry (same columns) so the huanngdev-skills repo can add it.
4. A new row needs a checked source: HTTP 200 **and** the expected content type (an `llms.txt` that returns HTML is not one).
