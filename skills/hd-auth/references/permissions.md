# Roles & permissions

## Model
`packages/shared/src/permissions.ts` is the single source:
```ts
export const Role = z.enum(["admin", "member"]);
export const Permission = z.enum(["project:read", "project:write", "user:manage"]);
export const rolePermissions = {
  admin: ["project:read", "project:write", "user:manage"],
  member: ["project:read", "project:write"],
} satisfies Record<z.infer<typeof Role>, z.infer<typeof Permission>[]>;
```
- Permission names are `resource:action`. Add a permission here first, then use it.
- The user's role is stored on the user record (Better Auth `additionalFields` or the admin plugin's `role`).

## Enforcement (in services)
```ts
assertCan(ctx.user, "project:write");                      // role check → AppError FORBIDDEN
assertOwns(ctx.user, project);                              // ownership check for user-owned rows
```
- Every service that reads or changes user-owned or restricted data calls these before doing work. Routes don't check permissions themselves.
- Not found vs forbidden: when the user must not learn that a resource exists, return `NOT_FOUND`.
- Queries for user-owned data filter by owner in the repository (`where ownerId = ctx.user.id`), not after fetching.

## Frontend
Use the same `rolePermissions` map to hide/disable UI. It is a UX hint only.

## Tests
Every protected use case has tests for: allowed role, forbidden role, unauthenticated, and another user's resource.
