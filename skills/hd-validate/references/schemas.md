# Schemas & contracts

## Where schemas live
```
packages/shared/src/
  <feature>/<feature>.schema.ts   # CreateXInput, UpdateXInput, XDto, XListQuery
  errors.ts                       # ErrorCode, ErrorResponseSchema
  page.ts                         # pageSchema(item), CursorQuery
```
- Name: `XxxSchema` for the schema, `Xxx` for its type: `export type UserDto = z.infer<typeof UserDtoSchema>`.
- Input and output are separate schemas (`CreateUserInputSchema` ≠ `UserDtoSchema`). Derive with `.pick()`, `.omit()`, `.extend()`, `.partial()` instead of copying fields.
- Shared schemas contain no server-only logic (DB, secrets) so the frontend can import them.

## Zod 4 habits
- Top-level formats: `z.email()`, `z.url()`, `z.uuid()`, `z.iso.datetime()` (not `z.string().email()`).
- Objects are strict about intent: `z.strictObject()` for inputs where unknown keys are a bug; `z.object()` otherwise.
- Query/params arrive as strings: `z.coerce.number().int()`, `z.stringbool()`.
- Money in contracts is an integer minor-unit (`z.int().nonnegative()`) or a decimal string — never a float.
- IDs: `z.uuid()`. Dates over JSON: ISO strings (`z.iso.datetime()`), converted at the edge.
- Transformations (`.transform`) only at the edge that needs them; keep shared DTO schemas serializable.

## Parsing
- `schema.parse()` where failure is a programmer/config error (env, internal invariants); `safeParse()` where failure is expected (user input) and must become a response.
- Error formatting: `z.flattenError(err).fieldErrors` for forms/API `details`; `z.prettifyError(err)` for logs and CLI output.
- Never trust unparsed `JSON.parse`, `request.json()`, `localStorage`, `searchParams` or model output — parse them.
