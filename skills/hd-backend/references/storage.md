# Storage & cache

## Files (any S3-compatible store)
- Local: an S3-compatible service in `compose.yaml`; the image is the project's choice, pinned and recorded in an ADR. MinIO's official images are no longer published, so don't add `minio/minio`.
- Credentials come from the root `.env` (`S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY=<generate>`, …) and reach the app through its validated env.
- Client: `new Bun.S3Client({ endpoint, accessKeyId, secretAccessKey, bucket })` — no AWS SDK.
- The server chooses the object key (e.g. `<entity>/<id>/<uuid>.<ext>`) and stores it in the DB. Never accept a key or path from the client to read/write.

## Upload flow (browser → storage, the API never proxies the client's upload)
1. `POST …/uploads`: check permission, declared size and content type against an allow-list; create a `pending` upload row (owner, target, limits) with a **staging** key; return `s3.presign(stagingKey, { method: "PUT", expiresIn: 300 })`. Presign `type` only sets the response content type; it doesn't restrict the upload.
2. Browser `PUT`s the file to the staging key.
3. `POST …/uploads/:id/complete` (same owner, row still `pending`): copy staging → a final key that never gets a PUT URL (`await s3.write(finalKey, s3.file(stagingKey), { type })` — bytes stream through the server once), delete the staging object, then `stat()` and sniff the magic bytes of the **final** object. Mismatch with the allowed size/type → delete it and reject; otherwise store `type` from the sniffed bytes, mark `ready`, attach.
4. Stale `pending` rows and staging objects (older than the URL lifetime) are deleted by the next upload request of that user; a scheduled job only if the project has one (no job system by default).
- Never trust declared values, and never serve or attach the staging key: a presigned PUT can be replayed until it expires.
- Private files are served through short-lived presigned `GET` URLs issued after an ownership check.

## Cache (only when measured as needed)
- Redis (`redis:<version>-alpine` in compose, `REDIS_PASSWORD=<generate>`), client `Bun.redis` / `new Bun.RedisClient(url)` — no ioredis.
- Cache-aside in the repository or service: key `<entity>:<id>[:<variant>]`, always with a TTL, invalidate on write in the same use case.
- Never cache per-user secrets or authorization decisions longer than the session.
