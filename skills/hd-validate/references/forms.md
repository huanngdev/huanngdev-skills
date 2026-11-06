# Forms

- react-hook-form + `@hookform/resolvers/zod` with the **same** input schema the API validates (`CreateXInputSchema` from `packages/shared`). No form-only copy of the rules.
- Form-only fields (e.g. `confirmPassword`) extend the shared schema locally with `.extend()` + `.refine()`; the API schema stays the source of truth.
- `defaultValues` match `z.input<typeof Schema>`; submit handlers receive `z.output<…>`.
- Server errors: parse the response with `ErrorResponseSchema`; for `VALIDATION_FAILED`, map `details` (field errors) to `setError(field, …)`; other codes show a form-level message.
- Client-side validation is UX only — the API always validates again.
