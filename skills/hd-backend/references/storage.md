# Storage & cache

## Files (any S3-compatible store)
- Local: an S3-compatible service in `compose.yaml`; the image is the project's choice, pinned and recorded in an ADR. MinIO's official images are no longer published, so don't add `minio/minio`.
- Credentials come from the root `.env` (`S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY=<generate>`, …) and reach the app through its validated env.
- Client: `new Bun.S3Client({ endpoint, accessKeyId, secretAccessKey, bucket })` — no AWS SDK.
- The server chooses the object key (e.g. `<entity>/<id>/<uuid>.<ext>`) and stores it in the DB. Never accept a key or path from the client to read/write.

## Upload flow (browser → storage, the API never proxies bodies)
1. `POST …/uploads`: check permission, declared size and content type against an allow-list; create a `pending` upload row with the key; return `s3.presign(key, { method: "PUT", expiresIn: 600, type })`.
2. Browser `PUT`s the file.
3. `POST …/uploads/:id/complete`: `await s3.file(key).stat()`; if size or type differs from what was allowed (or the bytes fail a magic-number check where it matters), delete the object and reject. Otherwise mark it `ready` and attach it.
4. Stale `pending` uploads (older than the URL lifetime) are deleted by the next upload request of that user; a scheduled job only if the project has one (no job system by default).
- A presigned `PUT` can't enforce size by itself; step 3 is mandatory, never trust the declared values.
- Private files are served through short-lived presigned `GET` URLs issued after an ownership check.

## Cache (only when measured as needed)
- Redis (`redis:<version>-alpine` in compose, `REDIS_PASSWORD=<generate>`), client `Bun.redis` / `new Bun.RedisClient(url)` — no ioredis.
- Cache-aside in the repository or service: key `<entity>:<id>[:<variant>]`, always with a TTL, invalidate on write in the same use case.
- Never cache per-user secrets or authorization decisions longer than the session.
