# Docker & local infrastructure

Docker Compose is for local services (database, cache, object storage, …). Production servers and deploys are handled by the owner — don't write deploy configs unless asked.

## Two kinds of .env
| File | Used by | Contains |
|---|---|---|
| root `.env` | `docker compose` only | credentials and config for the compose services |
| `apps/<app>/.env` | that app only | the app's own config and secrets |
Each has a committed `.env.example` next to it. All `.env` files are gitignored.

## Generating secrets
Never invent or hand-write secret values. Use the generator:
1. Copy `assets/gen-env.ts` from this skill to `scripts/gen-env.ts` (once per repo).
2. Root script: `"env:gen": "bun scripts/gen-env.ts . apps/*"`.
3. Run `bun run env:gen`.

`.env.example` syntax the generator understands:
```sh
# random 32-byte secret
POSTGRES_PASSWORD=<generate>
# plain default, copied as is
POSTGRES_PORT=5432
# apps/api/.env.example — reuse root credentials instead of copying them:
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}
```
Comments go on their own line; a value containing `#` must be quoted (`"a#b"`). The generator rejects unquoted `#`, values with `$`, `\` or both quote kinds, and any `<generate>` left unreplaced.
It never overwrites existing values, only appends missing keys, prints key names only, and sets mode 600. New secret = add `NAME=<generate>` to the right `.env.example`, rerun. Never print, log or commit generated values. One-off value without the script: `openssl rand -hex 32`.

## compose.yaml
- One `compose.yaml` at the repo root with a top-level `name:`. Compose reads the root `.env` for `${…}` interpolation.
- Every username, password, secret, token and connection string comes from `.env` by name:
  - secrets: `${POSTGRES_PASSWORD:?Set POSTGRES_PASSWORD in .env}` — required, **no default**.
  - non-secret config may default: `${POSTGRES_PORT:-5432}`, `${POSTGRES_DB:-app}`. Ports: standard defaults; a busy port is changed in the root `.env`, not in compose.
  - never a literal credential (`POSTGRES_PASSWORD: postgres` is forbidden).
- Build derived URLs once with a YAML anchor instead of repeating parts:
  ```yaml
  x-database-url: &database-url postgresql://${POSTGRES_USER:?}:${POSTGRES_PASSWORD:?}@postgres:5432/${POSTGRES_DB:-app}
  ```
- Pin image tags (`postgres:18-alpine`), never `latest`.
- Every service has a `healthcheck`; dependents use `depends_on: { svc: { condition: service_healthy } }`.
- Named volumes for data. Publish ports on localhost only: `"127.0.0.1:${POSTGRES_PORT:-5432}:5432"`.
- Standard services (only those the project needs): `postgres:18-alpine` (needed for `uuidv7()`), `redis:<version>-alpine` with `--requirepass ${REDIS_PASSWORD:?}`, `rustfs/rustfs:<x.y.z>` for S3 (`hd-backend` storage.md; MinIO's official images are gone), `axllent/mailpit:<vX.Y>` as the local SMTP catcher when the app sends email.
- Validate before committing: `docker compose config --quiet`.
