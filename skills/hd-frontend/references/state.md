# Data & state

## API client (one axios instance)
`src/lib/api.ts`:
- `axios.create({ baseURL: env.VITE_API_URL, withCredentials: true, timeout })`.
- Response interceptor: non-2xx → parse body with `ErrorResponseSchema` (`packages/shared`) → throw `ApiError { status, code, message, details }`. Unparseable → `ApiError` with code `INTERNAL`. Network/timeout → code `NETWORK`.
- No other `fetch`/axios calls anywhere.

## Feature API functions
`features/<feature>/api.ts` — one function per endpoint; the response is parsed with the shared schema, so types and runtime agree:
```ts
export const getProject = async (id: string): Promise<ProjectDto> =>
  ProjectDtoSchema.parse((await api.get(`/projects/${id}`)).data);
```

## TanStack Query
- Query keys + options in one factory per feature (`projectQueries.detail(id)` returning `queryOptions({...})`); components/hooks never write raw keys.
- Lists use the shared cursor page with `useInfiniteQuery` (`getNextPageParam: (p) => p.nextCursor`).
- Mutations live in hooks; on success invalidate (or update) exactly the affected keys from the factory.
- Errors: `ApiError` with `VALIDATION_FAILED` → form field errors (`hd-validate` forms.md); other codes → a `sonner` toast with a human message by `code`; `UNAUTHENTICATED` → redirect to sign-in.
- Don't copy server data into Zustand or `useState`.

## Client state
- Zustand only for client state shared by distant components (e.g. sidebar open, draft selections). One small store per concern, selectors to read.
- Filters, tabs, sort and pagination live in the URL (`useSearchParams`), parsed with a Zod schema.
- Local UI state stays in the component's hook.
