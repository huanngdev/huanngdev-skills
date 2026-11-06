# Storage & cache

## Files (MinIO locally, any S3-compatible store)
- MinIO runs in `compose.yaml`; credentials come from the root `.env` (`MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD=<generate>`). Pin a `RELEASE.*` image tag.
- Client: `new Bun.S3Client({ endpoint, accessKeyId, secretAccessKey, bucket })` from validated env — no AWS SDK.
- Uploads go browser → storage directly with a presigned URL: `s3.presign(key, { method: "PUT", expiresIn: 600 })`. The API never proxies file bodies.
- The server chooses the object key (e.g. `<entity>/<id>/<uuid>.<ext>`) and stores it in the DB. Never accept a key or path from the client to read/write.
- Validate content type and size before issuing the URL; serve private files through short-lived presigned `GET` URLs.

## Cache (only when measured as needed)
- Redis (`redis:<version>-alpine` in compose, `REDIS_PASSWORD=<generate>`), client `Bun.redis` / `new Bun.RedisClient(url)` — no ioredis.
- Cache-aside in the repository or service: key `<entity>:<id>[:<variant>]`, always with a TTL, invalidate on write in the same use case.
- Never cache per-user secrets or authorization decisions longer than the session.
