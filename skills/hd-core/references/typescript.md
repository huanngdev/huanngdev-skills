# TypeScript

## Compiler
- `typescript` latest (7.x, native `tsc`) for `check-types`; `strict`, ESM, `noUncheckedIndexedAccess`. Package presets also enable `isolatedDeclarations` (see `hd-infra`).
- Never add `any`, `@ts-ignore`/`@ts-expect-error` without a linked reason, non-null `!`, or `as` casts to silence errors. `as const` is fine; `satisfies` over `as`.

## Types
- External data is `unknown` until parsed with Zod (`hd-validate`); types come from schemas.
- Absence is `null` / optional, never `""` or `0` as hidden state.
- Lifecycle and mutually exclusive states are discriminated unions handled by exhaustive `switch` (`const _exhaustive: never = x`).
- Types live next to the code that owns them; no global `types.ts` dump.

## Functions & modules
- Small named functions, one reason to change; > 2 related params → one object param.
- Pure transformations; side effects at module edges; never mutate arguments or shared exports.
- Early returns keep the happy path flat.
- Catch only to add context, translate a boundary error, or recover.
- `import type` for types; no default exports unless a tool requires them (route modules export `Component`); no barrel files that mix server and client code; no circular imports.

## Naming
Files/dirs kebab-case. Components/types PascalCase. Functions/variables camelCase; hooks `useX`. Booleans `is/has/can/should`. Zod schemas `XxxSchema`. Comments explain *why*, not *what*.
